#!/bin/bash
set -e

BUILD_DIR=$1
PACKER_VARS=$2
PACKER_TEMPLATE=$3
COMMIT=$4
BUCKET=$5
KEY=$6

SHORT_COMMIT=${COMMIT:0:7}
PACKER_DIR=$BUILD_DIR/packer
TERRAFORM_DIR=$BUILD_DIR/terraform/frontends

packer build -force -var-file $PACKER_DIR/$PACKER_VARS -var "site_dir=$BUILD_DIR/site" -var "commit=$SHORT_COMMIT" $PACKER_DIR/$PACKER_TEMPLATE | tee /tmp/packer.out

AMI=$(egrep "(eu|us|ap|sa)-(west|central|east|northeast|southeast)-(1|2): ami-" /tmp/packer.out | sed 's/.*ami-\([0-9a-f]*\).*/ami-\1/g')

pushd $TERRAFORM_DIR
rm -rf .terraform
terraform remote config -backend=s3 -backend-config="bucket=$BUCKET" -backend-config="key=$KEY"
TF_VAR_commit=$SHORT_COMMIT terraform plan  -var "web_ami=$AMI"
TF_VAR_commit=$SHORT_COMMIT terraform apply -var "web_ami=$AMI"
popd
