#!/usr/local/bin/python3

from __future__ import division
import boto
from boto.dynamodb2.types import *
from boto.dynamodb2.fields import *
from boto.dynamodb2.table import Table
from boto.dynamodb2.items import Item

import argparse,sys,time
from pprint import pprint

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


def parseargs():
  # Parse arguments
  parser = argparse.ArgumentParser(parents=[aws_parser()],description='Create stack parameters Table if necessary, and upload keys from file')
  parser.add_argument('-T','--table',default="stacks",help='Table used to store stack information')
  parser.add_argument('-n','--name',required=True,help='Name of the stack')
  parser.add_argument('-t','--type',required=True,choices=['common','shared','application'],help='Type of the stack')
  parser.add_argument('-k','--key',action='append',default=[],help='Additionnal config key in the forme "key=value"')
  parser.add_argument('prop_file',help='File with stack properties to load in Dynamo')

  return parser.parse_args()


def main(args):
  conn=dynaconnect(args)
  tableName=args.table

  try:
    conn.describe_table(tableName)
  except boto.exception.JSONResponseError as details:
    if (details.error_code != "ResourceNotFoundException"):
      error("Error when connecting to DynamodDB",details.message)
    
    sys.stdout.write("Table does not exist, creating it")
    sys.stdout.flush()
    
    table = Table.create(tableName, schema=[ HashKey('name') ], global_indexes=[GlobalAllIndex('StacksByType', parts=[HashKey('type')])], connection=conn)

    while (table.describe()["Table"]["TableStatus"]!="ACTIVE"):
      time.sleep(1)
      sys.stdout.write('.')
      sys.stdout.flush()
    print("")
  else:
    table = Table(tableName,connection=conn)

  parameters = dict([x.strip() for x in line.strip().split("=")] for line in open(args.prop_file))
  additionals = dict([x.strip() for x in k.strip().split("=")] for k in args.key)

  dynamodata={'type':args.type, 'name':args.name, 'config':parameters}
  dynamodata.update(additionals)
  item=Item(table,data=dynamodata)

  item.save(overwrite=True)

if __name__ == "__main__":
  args=parseargs()
  main(args)
