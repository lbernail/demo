provider "aws" {
  region = "${var.region}"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "${var.state_bucket}"
    key    = "${var.vpc_state_key}"
    region = "${var.region}"
  }
}

data "terraform_remote_state" "backends" {
  backend = "s3"

  config {
    bucket = "${var.state_bucket}"
    key    = "${var.backends_state_key}"
    region = "${var.region}"
  }
}

resource "aws_elb" "web" {
  name                      = "web${var.frontend_name}"
  subnets                   = ["${split(",",data.terraform_remote_state.vpc.public_subnets)}"]
  security_groups           = ["${data.terraform_remote_state.backends.sg_elb}"]
  cross_zone_load_balancing = "true"
  internal                  = "false"

  listener {
    instance_port     = "80"
    instance_protocol = "http"
    lb_port           = "80"
    lb_protocol       = "http"
  }

  listener {
    instance_port      = "80"
    instance_protocol  = "http"
    lb_port            = "443"
    lb_protocol        = "https"
    ssl_certificate_id = "${var.ssl_certificate_id}"
  }

  health_check {
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    timeout             = "2"
    target              = "HTTP:80${var.health_check_path}"
    interval            = "5"
  }

  tags {
    Name = "web-${var.frontend_name}"
  }
}

resource "template_file" "user_data" {
  template = "${file("user_data.tpl")}"

  vars {
    backend_properties = "${data.terraform_remote_state.backends.properties}"
    properties         = "${var.properties}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "web" {
  image_id      = "${var.web_ami}"
  name_prefix   = "lc-web-${var.frontend_name}-"
  instance_type = "${var.web_instance_type}"
  key_name      = "${var.key_name}"

  security_groups = ["${data.terraform_remote_state.backends.sg_web}",
    "${data.terraform_remote_state.vpc.sg_sshserver}",
  ]

  user_data            = "${template_file.user_data.rendered}"
  iam_instance_profile = "${data.terraform_remote_state.backends.web_profile}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                      = "asg-${aws_launch_configuration.web.name}"
  launch_configuration      = "${aws_launch_configuration.web.id}"
  availability_zones        = ["${split(",",data.terraform_remote_state.vpc.azs)}"]
  vpc_zone_identifier       = ["${split(",",data.terraform_remote_state.vpc.private_subnets)}"]
  load_balancers            = ["${aws_elb.web.name}"]
  health_check_type         = "${var.health_check_type}"
  health_check_grace_period = "${var.health_check_grace_period}"

  tag {
    key = "Name"

    value = "Web-${var.frontend_name}"

    propagate_at_launch = "true"
  }

  tag {
    key = "Commit"

    value = "${var.commit}"

    propagate_at_launch = "true"
  }

  min_size         = "${var.asg_min}"
  min_elb_capacity = "${var.asg_min}"
  max_size         = "${var.asg_max}"
  desired_capacity = "${var.asg_desired}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "web" {
  zone_id = "${var.route53_zoneid}"
  name    = "${var.dns_alias}"
  type    = "A"

  alias {
    name                   = "${aws_elb.web.dns_name}"
    zone_id                = "${aws_elb.web.zone_id}"
    evaluate_target_health = "false"
  }
}

output "elb" {
  value = "${aws_elb.web.dns_name}"
}
