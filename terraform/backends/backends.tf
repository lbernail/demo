data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "${var.state_bucket}"
        key = "${var.vpc_state_key}"
    }
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_security_group" "elb" {
    name = "sg_elb_${var.backend_name}"
    description = "Allow traffic to ELB"
    vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
    ingress {
        from_port = "80"
        to_port = "80"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags { Name = "sg_elb_api_${var.backend_name}"}
}

resource "aws_security_group" "web" {
    name = "sg_web_${var.backend_name}"
    description = "Allow traffic to web instances"
    vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
    ingress {
        from_port = "80"
        to_port = "80"
        security_groups = [ "${aws_security_group.elb.id}"]
        protocol = "tcp"
    }
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags { Name = "sg_web_${var.backend_name}"}
}

resource "aws_dynamodb_table" "ddb" {
    name = "${var.ddb_name}"
    read_capacity = "${var.ddb_read_cap}"
    write_capacity = "${var.ddb_write_cap}"
    hash_key = "lastname"
    range_key = "firstname"
    attribute {
      name = "lastname"
      type = "S"
    }
    attribute {
      name = "firstname"
      type = "S"
    }
}

resource "aws_iam_role" "web" {
    name = "role_web_${var.backend_name}"
    path = "/"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ddb_read" {
    name = "policy_ddb_${var.backend_name}"
    path = "/"
    description = "Acess to attendee table"
    policy = <<EOF
{
    "Statement": [
        {
            "Effect":"Allow",
            "Action":[
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:DescribeTable"
            ],
            "Resource": "${aws_dynamodb_table.ddb.arn}"
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_policy_attachment" "web" {
    name = "web_ddb_${var.backend_name}"
    roles = ["${aws_iam_role.web.name}"]
    policy_arn = "${aws_iam_policy.ddb_read.arn}"
}

resource "aws_iam_instance_profile" "web" {
    name = "profile_web_${var.backend_name}"
    roles = ["${aws_iam_role.web.name}"]
}

output "ddb_table" { value = "${var.ddb_name}" }
output "sg_elb" { value = "${aws_security_group.elb.id}" }
output "sg_web" { value = "${aws_security_group.web.id}" }
output "web_profile" { value = "${aws_iam_instance_profile.web.id}" }
output "properties" { value = "ddbtable:${var.ddb_name},region:${data.terraform_remote_state.vpc.region}" }
