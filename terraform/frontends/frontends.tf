provider "aws" {
  region = "${var.region}"
}

resource "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "${var.state_bucket}"
        key = "${var.vpc_state_key}"
    }
}

resource "terraform_remote_state" "backends" {
    backend = "s3"
    config {
        bucket = "${var.state_bucket}"
        key = "${var.backends_state_key}"
    }
}

resource "aws_elb" "web" {
    name = "${concat("web-",var.frontend_name)}"
    subnets = ["${split(",",terraform_remote_state.vpc.output.public_subnets)}"]
    security_groups = ["${terraform_remote_state.backends.output.sg_elb}"]
    cross_zone_load_balancing = "true"
    internal = "false"
    listener {
        instance_port = "80"
        instance_protocol = "http"
        lb_port = "80"
        lb_protocol = "http"
    }
    health_check {
        healthy_threshold = "2"
        unhealthy_threshold = "2"
        timeout = "2"
        target = "${concat("HTTP:80",var.health_check_path)}"
        interval = "5"
    }
    tags { Name = "${concat("web-",var.frontend_name)}" }
}

resource "template_file" "user_data" {
    template = "${file("user_data.tpl")}"
    vars {
         backend_properties = "${terraform_remote_state.backends.output.properties}"
         properties = "${var.properties}"
    }
    lifecycle { create_before_destroy = true }
}

resource "aws_launch_configuration" "web" {
    image_id = "${var.web_ami}"
    name_prefix = "${concat("lc-web-",var.frontend_name,"-")}"
    instance_type = "${var.web_instance_type}"
    key_name = "${var.key_name}"
    security_groups = ["${terraform_remote_state.backends.output.sg_web}",
                       "${terraform_remote_state.vpc.output.sg_sshserver}"]
    user_data="${template_file.user_data.rendered}"
    iam_instance_profile = "${terraform_remote_state.backends.output.web_profile}"
    lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "web_asg" {
    name = "${concat("asg-",aws_launch_configuration.web.name)}"
    launch_configuration = "${aws_launch_configuration.web.id}"
    availability_zones = ["${split(",",terraform_remote_state.vpc.output.azs)}"]
    vpc_zone_identifier = ["${split(",",terraform_remote_state.vpc.output.private_subnets)}"]
    load_balancers = ["${aws_elb.web.name}"]
    health_check_type = "${var.health_check_type}"
    health_check_grace_period = "${var.health_check_grace_period}"
    tag { key = "Name" value = "${concat("Web-",var.frontend_name)}" propagate_at_launch = "true" }
    tag { key = "Commit" value = "${var.commit}" propagate_at_launch = "true" }
    min_size = "${var.asg_min}"
    min_elb_capacity = "${var.asg_min}"
    max_size = "${var.asg_max}"
    desired_capacity = "${var.asg_desired}"
    lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "web" {
    zone_id = "${var.route53_zoneid}"
    name = "${var.dns_alias}"
    type = "A"
    alias {
        name = "${aws_elb.web.dns_name}"
        zone_id = "${aws_elb.web.zone_id}"
        evaluate_target_health = "false"
    }
}

output "elb" { value = "${aws_elb.web.dns_name}" }
