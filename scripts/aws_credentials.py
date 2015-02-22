#!/usr/bin/python

import boto
import argparse

def error(context,details):
  print(context)
  print(details)
  exit(1)


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


def aws_parser():
  aws_parser = argparse.ArgumentParser(add_help=False)
  credentials = aws_parser.add_mutually_exclusive_group(required=True)
  credentials.add_argument('-c','--credentials',help='AWS credentials',nargs=2,metavar=('ACCESS_KEY_ID','SECRET_KEY'))
  credentials.add_argument('-p','--profile',help='Boto Profile to use')
  credentials.add_argument('-i','--instance_role',help='Use instance role',action='store_true')

  aws_parser.add_argument('-s','--stsrole', help='STS Role to assume')
  aws_parser.add_argument('-r','--region', help='Region to connect to', default='eu-west-1')

  return aws_parser
