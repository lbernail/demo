#!/usr/bin/python
import boto
from boto.dynamodb2.table import Table
import argparse


def stscredentials(args):
  kwparams={}
  try:
    if args.instance_role:
      pass
    elif args.profile:
      kwparams['profile_name']=args.profile
    else:
      kwparams['aws_access_key_id']=args.credentials[0]
      kwparams['aws_secret_access_key']=args.credentials[1]

    sts=boto.sts.connect_to_region(args.region,**kwparams)
    assumed_role = sts.assume_role(args.stsrole, 'STS_session')

  except boto.exception.BotoServerError as detail:
    error('Unable to assume role',detail)
  except boto.provider.ProfileNotFoundError as detail:
    error('Unable to use provided profile',detail)
  else:
    return assumed_role.credentials.access_key,assumed_role.credentials.secret_key,assumed_role.credentials.session_token


def getcredentials(args):
  kwparams={}
  if args.stsrole:
    key,secret,token=stscredentials(args)
    kwparams['aws_access_key_id']=key
    kwparams['aws_secret_access_key']=secret
    kwparams['security_token']=token
  elif args.instance_role:
    pass
  elif args.profile:
    kwparams['profile_name']=args.profile
  else:
    kwparams['aws_access_key_id']=args.credentials[0]
    kwparams['aws_secret_access_key']=args.credentials[1]

  return kwparams


def dynaconnect(args):
  kwparams=getcredentials(args)
  try:
    c=boto.dynamodb2.connect_to_region(args.region,**kwparams)
  except boto.provider.ProfileNotFoundError as detail:
    error('Unable to use provided profile',detail)
  return c


def parseargs():
  # Parse arguments
  parser = argparse.ArgumentParser(description='Update AMI artifact dynamo table')

  credentials = parser.add_mutually_exclusive_group(required=True)
  credentials.add_argument('-c','--credentials',help='AWS credentials',nargs=2,metavar=('ACCESS_KEY_ID','SECRET_KEY'))
  credentials.add_argument('-p','--profile',help='Boto Profile to use')
  credentials.add_argument('-i','--instance_role',help='Use instance role',action='store_true')

  parser.add_argument('-s','--stsrole', help='STS Role to assume')
  parser.add_argument('-r','--region', help='Region to connect to', default='eu-west-1')
  parser.add_argument('-t','--table', help='Referential Table')

  parser.add_argument('application', help='Application Name')
  parser.add_argument('build', help='Build Number')
  parser.add_argument('build_id', help='Build ID')
  parser.add_argument('commit', help='Git Commit')
  parser.add_argument('ami', help='AMI ID')


  return parser.parse_args()

def main(args):
  conn=dynaconnect(args)
  ref = Table(args.table,connection=conn)

  ref.put_item(data={'Application':args.application,'Build':args.build,'Build_ID':args.build_id,'Commit':args.commit,'AMI':args.ami})

if __name__ == "__main__":
  args=parseargs()
  main(args)
