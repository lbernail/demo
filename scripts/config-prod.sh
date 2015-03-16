#/bin/bash
./setparams.py -p lbernail -T Stacks -t common -n infra-prod ../environment/prod/common.properties
./setparams.py -p lbernail -T Stacks -t shared -n shared-demo-prod -k depends=infra-prod  ../environment/prod/shared-demo-nodb.properties
./setparams.py -p lbernail -T Stacks -t application -n demo-prod-blue -k depends=shared-demo-prod  ../environment/prod/demo-blue.properties
./setparams.py -p lbernail -T Stacks -t application -n demo-prod-green -k depends=shared-demo-prod  ../environment/prod/demo-green.properties
