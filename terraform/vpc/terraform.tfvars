region          = "eu-west-1"

vpc_name        = "demo-training"
base_network    = "10.0.0.0/16"
public_networks = "10.0.0.0/24,10.0.1.0/24"
private_networks= "10.0.2.0/24,10.0.3.0/24"
trusted_networks= "109.28.19.33/32"

bastion_ami     = "ami-e31a6594"
bastion_type    = "t2.nano"
key_name        = "aws-dev"
