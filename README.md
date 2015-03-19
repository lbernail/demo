# TIAD Demo

## Disclaimer
This is a very first draft of the automation deployment tool I demonstrated at TIAD. I plan to redesign it much more cleanly in the future (help welcome!)

The Jenkins workflow to redeploy is not here yet but I will add it soon

## Using it
1. Fork it and configure it for you

Change the HostedZoneName (environment/(integration|prod)/common.properties)  
Create an AMI with a web site (for example)
 
2. Load config data in the dynamoDB referential

By default the Dynamo Table is called Stacks and will be created if it does not exist

These commands will configure 3 cloudformation stacks and the associated dependencies:
- Infrastructure (associated cloudformation template: environment/common.template.json)
- Backends (environment/shared-demo.template.json)
- Application (environment/app-demo.template.json)

```
./setparams.py -T Stacks -t common -n infra-int ../environment/integration/common.properties
./setparams.py -T Stacks -t shared -n shared-demo-int -k depends=infra-int  ../environment/integration/shared-demo-nodb.properties
./setparams.py -T Stacks -t application -n demo-int -k depends=shared-demo-int  ../environment/integration/demo.properties
```

3. Build stacks

The build tool is retrieving the templates from an S3 bucket so they can be centralized.  
The default bucket is demo-templates which is publicly readable but you can easily change it and upload custom cloudformation templates

```
./build.py -n infra-int -t integration build
./build.py -n shared-demo-int -t integration build
./build.py -n demo-int -t integration build AppAMI=ami-xxxxx
```
