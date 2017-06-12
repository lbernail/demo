variable "region" {}

variable "frontend_name" {}
variable "commit" {default = "unknwon"}

variable "web_ami" {}
variable "web_instance_type" {}
variable "key_name" {}
variable "properties" {}

variable "health_check_path" {}
variable "health_check_type" {}

variable "asg_desired" {}
variable "asg_max" {}
variable "asg_min" {}
variable "health_check_grace_period" {}

variable "route53_zoneid" {}
variable "dns_alias" {}
