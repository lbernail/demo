terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }
}

state_bucket = "grk-tfstates"

vpc_state_key = "vpc"

backends_state_key = "backends"

region = "eu-west-1"

frontend_name = "demo"

web_instance_type = "t2.micro"

key_name = "aws-dev"

properties = "environment:Integration,version:Grey"

health_check_path = "/index.php"

asg_desired = "4"

asg_max = "4"

asg_min = "4"

health_check_type = "EC2"

health_check_grace_period = "300"

route53_zoneid = "Z2R8GOXZP18OSR"

dns_alias = "tiad.awsdemo.grkoffi.me"
