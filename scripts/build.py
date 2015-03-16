#!/usr/local/bin/python3

import boto.cloudformation
from boto.dynamodb2.types import *
from boto.dynamodb2.fields import *
from boto.dynamodb2.table import Table
from boto.dynamodb2.items import Item

import argparse,sys,time,json

from aws_credentials import *


def error(context,details):
  print(context)
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


def s3connect(args):
  kwparams=getcredentials(args) 
  try:
    c=boto.s3.connect_to_region(args.region,**kwparams)
  except boto.provider.ProfileNotFoundError as detail:
    error('Unable to use provided profile',detail)
  return c



def parseargs():
  # Parse arguments
  parser = argparse.ArgumentParser(parents=[aws_parser()],description='Manage infrastructure and application ressources')
  parser.add_argument('-T','--table',default="Stacks",help='Table used to store stack information')
  parser.add_argument('-b','--bucket',default="demo-templates",help='Bucket with cloudformation templates')
  parser.add_argument('-n','--name',required=True,help='Name of the stack')
  parser.add_argument('-t','--tag',default="integration",help='Environments tag')
  parser.add_argument('action',choices=['build','delete'],help='Action: build (create or update), delete')
  parser.add_argument('key',nargs='*',help='Additionnal config keys in the forme "key=value"')

  return parser.parse_args()


def main(args):
  dynamo=dynaconnect(args)
  cfn=cfnconnect(args)
  s3=s3connect(args)

  try:
   dynamo.describe_table(args.table)
  except boto.exception.JSONResponseError as details:
    error("Unable to access parameter table",details.message)
  else:
    table = Table(args.table,connection=dynamo) 
  

  stackName=args.name
  try:
    stack=cfn.describe_stacks(stackName)
  except boto.exception.BotoServerError as details:
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
  
    # Initial values from explicit parameters
    print(args.key)
    param_values_list=[dict([x.strip() for x in k.strip().split("=")] for k in args.key)]
  
    # Get DynamoDB parameters
    conf_item=table.get_item(name=stackName)
    type=conf_item['type']
    param_values_list.append(conf_item['config'])
    while (conf_item['depends']):
      conf_item=table.get_item(name=conf_item['depends'])
      param_values_list.append(conf_item['outputs'])
      param_values_list.append(conf_item['config'])

    # We reverse the list of dictionnaries to prioritize explicit parameters over stack parameters (over dependant stack parameters)
    param_values=dict((k,v) for p in reversed(param_values_list) for (k,v) in p.items())

    # Get template from bucket add parse param keys
    bucket=s3.get_bucket(args.bucket)
    template=bucket.get_key(type).get_contents_as_string(encoding='utf-8');
    param_list=json.loads(template)['Parameters'].keys()

    # We set all the parameters from the template that we found in ddb or on the command line
    params=[ (p,param_values[p]) for p in param_list if p in param_values] 

    url="https://s3-%s.amazonaws.com/%s/%s" % (args.region,args.bucket,type)

    try:
      action(stackName,template_url=url,parameters=params, capabilities=['CAPABILITY_IAM'],tags={'env':args.tag})
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
    stack_params=table.get_item(name=stackName)
    stack_params['outputs']=dict((o.key,o.value) for o in desc.outputs);
    stack_params.partial_save();
    

if __name__ == "__main__":
  args=parseargs()
  main(args)
