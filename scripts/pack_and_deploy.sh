#!/bin/bash
set -e

BUILD_DIR=$1
PACKER_VARS=$2
PACKER_TEMPLATE=$3
COMMIT=$4

packer build -force -var-file $BUILD_DIR/$PACKER_VARS -var "source_dir=$BUILD_DIR" -var "commit=${COMMIT:0:7}" $BUILD_DIR/$PACKER_TEMPLATE | tee /tmp/packer.out

ami=$(egrep "(eu|us|ap|sa)-(west|central|east|northeast|southeast)-(1|2): ami-" /tmp/packer.out | sed 's/.*ami-\([0-9a-f]*\).*/ami-\1/g')
echo $ami
