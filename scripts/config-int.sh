#/bin/bash
./setparams.py -p lbernail-admin -T Stacks -t common -n infra-int ../environment/integration/common.properties
./setparams.py -p lbernail-admin -T Stacks -t shared -n shared-demo-int -k depends=infra-int  ../environment/integration/shared-demo-nodb.properties
./setparams.py -p lbernail-admin -T Stacks -t application -n demo-int -k depends=shared-demo-int  ../environment/integration/demo.properties
