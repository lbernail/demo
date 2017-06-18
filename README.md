# Application lifecycle automation Demo

## Deploying the application

If you want to use this demo in your environment, you can clone it (or even fork it). You will need to do some reconfiguration on your account.

### Configuration of terraform

First, you need to create a bucket to store your tfstates:
```
aws s3 mb s3://my-state-bucket
```

Then go to the terraform directory and edit the state configurations for the three terraform stacks:
- terraform/vpc/vpc.tf
- terraform/backends/backends.tf
- terraform/frontends/frontends.tf

In these files, you need to update the bucket key for the terraform configuration:
```hcl
terraform {
    backend "s3" {
        bucket = "my-state-bucket"
        key    = "demo/vpc"
        region = "eu-west-1"
    }
}
```

You then need to update data sources for cross-stack references in files:
- terraform/backends/backends.tf
- terraform/frontends/frontends.tf

In both, you need to modify the vpc data source (to access outputs from the vpc stack):
```hcl
data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "my-state-bucket"
        key    = "demo/vpc"
        region = "${var.region}"
    }
}
```

In frontends.tf, you also need to modify the reference to the backend stack:
```hcl
data "terraform_remote_state" "backends" {
    backend = "s3"
    config {
        bucket = "my-state-bucket"
        key    = "demo/backends"
    }
}
```

### Deploy the VPC
Go to the terraform/vpc directory and initialize the terraform setup:
```
terraform init
```
Then you can see what resources terraform will create and apply
```
terraform plan
terraform apply
```

### Deploy backends
Go to the terraform/backends directory and deploy backends
```
terraform init
terraform plan
terraform apply
```

### Deploy frontends
To deploy frontends, we need to use Packer to create an AMI with the code of the application.
First, you need to go to the packer directory and configure Packer to use a VPC and subnet you own.
You can do this by modifying the build_vpc and build_subnet in the vars/travis.json file:
```json
{
    "source_ami": "ami-e31a6594",
    "region": "eu-west-1",
    "build_vpc": "vpc-6a44b50f",
    "build_subnet": "subnet-6f607c29",
    "build_sg": "",
    "ssh_private"   : "false",
    "public_ip"     : "true",
    "project" : "demotv"
}
```
For the VPC and subnet, you can either use the one you created with terraform or use a different build VPC (which could be your default VPC for instance).

You can now build your AMI:
```
packer build -var-file vars/travis.json -var "site_dir=../site" packer_apache_php.json
```

Once your AMI is built, you can deploy the frontends of the application. Go to the terraform/frontends directory. If you have a route53 public zone and would like to have a readable URL for the demo website, you need to update the terraform.tfvars and change the route53_zoneid and dns_alias to match your environment:
```
route53_zoneid      = "Z32YN70UZV2CU7"
dns_alias           = "tiad.awsdemo.d2-si.eu"
```
If you don't have a route53 public zone, you can simply remove these two lines (terraform is configured not to create the record if the zoneid variable is not set. You can now deploy your frontends using the AMI you built with packer.
```
terraform init
terraform plan -var web_ami=<ami-id>
terraform apply -var web_ami=<ami-id>
```

## Integration with Travis

If you have forked the repo on github you can also use the Travis integration. You need to go to travis-ci.org and link your repo and configure it for your environment. For the configuration, you need to edit the .travis.yml file. First, update the STATE_BUCKET variable to use the bucket you created earlier.

To be able to deploy in your environment, travis will need access to AWS credentials: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY. For security purposes, these variables need to be encrypted. You can see the encrypted versions of the credentials I use in the .travis.yml file in the form of the two lines started with "secure:"). To use your credentials, you simply need to use the travis gem:
```
gem install travis
travis encrypt AWS_ACCESS_KEY_ID=<your access key id>
travis encrypt AWS_SECRET_ACCESS_KEY=<your secret access id>
```
You then need to replace the two "secure:" line in .travis.yml with the ones you generated. You can find more information on encrypted variable on the [travis website](https://docs.travis-ci.com/user/environment-variables/#Defining-encrypted-variables-in-.travis.yml).

Now, every time you push code to the master branch of your repository the frontends stack will be updated. The code of the application is located in the "site" directory. This will only work if the vpc and backends stacks are already deployed.
