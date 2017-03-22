state_bucket	    = "tfstates"
vpc_state_key	    = "demo/vpc"
backends_state_key	= "demo/backends"
region	            = "eu-west-1"

frontend_name	    = "demo"

web_instance_type	= "t2.micro"
key_name	        = "aws-dev"
properties          = "environment:Integration,version:Grey"

health_check_path	= "/index.php"

asg_desired	        = "4"
asg_max	            = "4"
asg_min	            = "4"
health_check_type	= "EC2"
health_check_grace_period = "300"

route53_zoneid      = "Z32YN70UZV2CU7"
dns_alias           = "tiad.awsdemo.d2-si.eu"
