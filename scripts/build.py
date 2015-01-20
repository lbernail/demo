#!/usr/bin/python

import boto.cloudformation
from boto.dynamodb2.types import *
from boto.dynamodb2.fields import *
from boto.dynamodb2.table import Table
from boto.dynamodb2.items import Item

import argparse,sys,time,json

from aws_credentials import *


def error(context,details):
  print context
  print(details)
  exit(1)


def dynaconnect(args):
  kwparams=getcredentials(args) 
  try:
    c=boto.dynamodb2.connect_to_region(args.region,**kwparams)
  except boto.provider.ProfileNotFoundError as detail:
    error('Unable to use provided profile',detail)
  return c

def cfnconnect(args):
  kwparams=getcredentials(args) 
  try:
    c=boto.cloudformation.connect_to_region(args.region,**kwparams)
  except boto.provider.ProfileNotFoundError as detail:
    error('Unable to use provided profile',detail)
  return c


def parseargs():
  # Parse arguments
  parser = argparse.ArgumentParser(parents=[aws_parser()],description='Manage infrastructure and application ressources')
  parser.add_argument('-t','--table',required=True,help='Parameter table for the environment')
  parser.add_argument('-m','--ami',help='AMI table',default='AMI_artifacts')
  parser.add_argument('-a','--app',required=True,help='Application do deploy (can be "Common")')
  parser.add_argument('action',choices=['build','delete'],help='Action: build (create or update), delete')
  parser.add_argument('template',help='Template file')

  return parser.parse_args()


def main(args):
  dynamo=dynaconnect(args)
  cfn=cfnconnect(args)

  try:
   dynamo.describe_table(args.table)
  except boto.exception.JSONResponseError as details:
    error("Unable to access parameter table",details.message)
  else:
    table = Table(args.table,connection=dynamo) 
    
  stackName=args.table+'-'+args.app
  try:
    stack=table.get_item(application=args.app,parameter='StackName')
  except boto.dynamodb2.exceptions.ItemNotFound as details:
    if args.action=="delete":
      error("No such stack","") 
    else:
      print("Creating stack")
      action=cfn.create_stack
  else:
    if args.action=="delete":
      print("Deleting stack")
    else:
      print("Updating stack")
      action=cfn.update_stack


  if args.action=="delete":
    cfn.delete_stack(stackName)
  else:
    with open (args.template, "r") as f:
      template=f.read()

    param_list=json.loads(template)['Parameters'].keys()
    param_values={}
    for a in ['Common',args.app]:
      results=table.query_2(application__eq=a,consistent=True)
      param_values=dict(param_values.items() + [(r['parameter'],r['value']) for r in results])

    if args.app!='Common':
      # Deploying an app, use last artifact
      ami_table = Table(args.ami,connection=dynamo)
      r=ami_table.query_2(Application__eq=args.app,reverse=True)
      param_values['AppAMI']=r.next()['AMI']

    try:
      params=[ (p,param_values[p]) for p in param_list] 
    except KeyError as details:
      error("Missing parameter in dynamoDB referential",details)


    try:
      action(stackName,template_body=template,parameters=params, capabilities=['CAPABILITY_IAM'])
    except boto.exception.BotoServerError as details:
      if (details.error_message == "No updates are to be performed."):
        print("Stack already up to date")
        exit(0)
      else:
        error("Unable to Create/Update",details)


    while cfn.describe_stacks(stackName)[0].stack_status in ["CREATE_IN_PROGRESS", "UPDATE_IN_PROGRESS", "UPDATE_COMPLETE_CLEANUP_IN_PROGRESS"]:
      time.sleep(10)
      resources=cfn.list_stack_resources(stackName)
      r=sorted([(i.resource_status,i.logical_resource_id) for i in resources])
      for t in r:
        print("%s\t%s" % t)
      print("===============================================================")

    desc=cfn.describe_stacks(stackName)[0]
    if desc.stack_status!="CREATE_COMPLETE" and desc.stack_status!="UPDATE_COMPLETE":
      error("Stack creation failed",desc.stack_status_reason)

    print("Stack created/updated successfully, udpdating referential data")
    Item(table,data={'application':args.app, 'parameter':'StackName', 'value': stackName, 'source':'Build'}).save(overwrite=True)
    
    for o in desc.outputs:
      Item(table,data={'application':args.app, 'parameter':o.key, 'value':o.value, 'source' : stackName}).save(overwrite=True)


if __name__ == "__main__":
  args=parseargs()
  main(args)
