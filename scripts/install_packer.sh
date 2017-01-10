#!/bin/bash
set -x

PACKER_DL=${TOOLS_DIR}/packer-${PACKER_VERSION}

mkdir -p ${TOOLS_DIR}/bin      
                               
if [ ! -d "${PACKER_DL}" ]
then
    mkdir -p ${PACKER_DL}
    #wget -O /tmp/packer-${PACKER_VERSION}.zip http://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip
    curl -sSLo packer-${PACKER_VERSION}.zip  https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip
    unzip packer-${PACKER_VERSION}.zip -d ${PACKER_DL}
    rm packer-${PACKER_VERSION}.zip
fi

ln -sf ${PACKER_DL}/packer ${TOOLS_DIR}/bin
packer version
