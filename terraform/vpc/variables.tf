variable "region" {}

variable azs {
    default = {
        "eu-west-1" = "eu-west-1a,eu-west-1b"
        "us-west-2" = "us-west-2a,us-west-2b"
        "us-east-1" = "us-east-1a,us-east-1b"
    }
}

variable "vpc_name" {}
variable "base_network" {}
variable "public_networks" {}
variable "private_networks" {}
variable "trusted_networks" {}

variable "bastion_ami" {}
variable "bastion_type" {}
variable "key_name" {}
