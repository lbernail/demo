#!/bin/bash
set -e

BUILD_DIR=$1
PACKER_VARS=$2
COMMIT=$3

packer build -var-file $BUILD_DIR/$PACKER_VARS -var "source_dir=$BUILD_DIR" -var "commit=${COMMIT:0:7}" $BUILD_DIR/packer_apache_php.json
