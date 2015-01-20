#!/usr/bin/python

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


def parseargs():
  # Parse arguments
  parser = argparse.ArgumentParser(parents=[aws_parser()],description='Create application parameters Table if necessary, and upload keys from file')
  parser.add_argument('-t','--table',required=True,help='Parameter table for the environment')
  parser.add_argument('-a','--app',required=True,help='Application')
  parser.add_argument('prop_file',help='File with application properties to load in Dynamo')

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
    
    table = Table.create(tableName, schema=[ HashKey('application'), RangeKey('parameter'), ], connection=conn)

    while (table.describe()["Table"]["TableStatus"]!="ACTIVE"):
      time.sleep(1)
      sys.stdout.write('.')
      sys.stdout.flush()
    print ""
  else:
    table = Table(tableName,connection=conn)

  parameters = dict([x.strip() for x in line.strip().split("=")] for line in open(args.prop_file))
  for k,v in parameters.items():
    item=Item(table,data={'application':args.app, 'parameter':k, 'value':v, 'source':'Config'})
    item.save(overwrite=True)

if __name__ == "__main__":
  args=parseargs()
  main(args)
