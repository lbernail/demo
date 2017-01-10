#!/bin/bash
set -x

TERRAFORM_DL=${TOOLS_DIR}/terraform-${TERRAFORM_VERSION}

mkdir -p ${TOOLS_DIR}/bin      
                               
if [ ! -d "${TERRAFORM_DL}" ]
then
    mkdir -p ${TERRAFORM_DL}
    wget -O terraform-${TERRAFORM_VERSION}.zip http://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    unzip terraform-${TERRAFORM_VERSION}.zip -d ${TERRAFORM_DL}
    rm terraform-${TERRAFORM_VERSION}.zip
fi

ln -sf ${TERRAFORM_DL}/terraform ${TOOLS_DIR}/bin
terraform version
