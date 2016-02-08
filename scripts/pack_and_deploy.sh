#!/bin/bash
set -e
set -x

echo "In script"
echo $PATH

packer version
terraform version
