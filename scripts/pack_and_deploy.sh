#!/bin/bash
set -e

BUILD_DIR=$1
PACKER_VARS=$2
PACKER_TEMPLATE=$3
COMMIT=$4

PACKER_DIR=$BUILD_DIR/packer

packer build -force -var-file $PACKER_DIR/$PACKER_VARS -var "site_dir=$BUILD_DIR/site" -var "commit=${COMMIT:0:7}" $PACKER_DIR/$PACKER_TEMPLATE | tee /tmp/packer.out

ami=$(egrep "(eu|us|ap|sa)-(west|central|east|northeast|southeast)-(1|2): ami-" /tmp/packer.out | sed 's/.*ami-\([0-9a-f]*\).*/ami-\1/g')
echo $ami
