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
  parser = argparse.ArgumentParser(parents=[aws_parser()],description='Load data in dynamo')
  parser.add_argument('-T','--table',default="stacks",help='Table used to store stack information')
  parser.add_argument('file',help='File with data to load')

  return parser.parse_args()


def main(args):
  conn=dynaconnect(args)
  tableName=args.table

  try:
    table=Table(tableName,connection=conn)
  except boto.exception.JSONResponseError as details:
    error("Error when connecting to DynamodDB",details.message)
    
  users = [[x.strip() for x in line.strip().split(",")] for line in open(args.file)]

  for user in users:
    dynamodata={'firstname':user[0], 'lastname':user[1], 'society':user[2]}
    item=Item(table,data=dynamodata)
    item.save(overwrite=True)

if __name__ == "__main__":
  args=parseargs()
  main(args)
