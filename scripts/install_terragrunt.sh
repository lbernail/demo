#!/bin/bash -xe

TERRAGRUNT_DL=${TOOLS_DIR}/terragrunt-${TERRAGRUNT_VERSION}

mkdir -p ${TOOLS_DIR}/bin

if [ ! -d "${TERRAGRUNT_DL}" ]
then
    mkdir -p ${TERRAGRUNT_DL}
    wget -O ${TERRAGRUNT_DL}/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64
    chmod +x ${TERRAGRUNT_DL}/terragrunt
fi

ln -sf ${TERRAGRUNT_DL}/terragrunt ${TOOLS_DIR}/bin
terragrunt -v
