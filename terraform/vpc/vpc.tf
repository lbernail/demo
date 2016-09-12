provider "aws" {
    region = "eu-west-1"
}

resource "aws_vpc" "main" {
    cidr_block = "${var.base_network}"
    tags { Name = "${var.vpc_name}" }
}

resource "aws_subnet" "public" {
    vpc_id = "${aws_vpc.main.id}"
    count = "${length(split(",",lookup(var.azs,var.region)))}"
    cidr_block = "${element(split(",",var.public_networks),count.index)}"
    availability_zone = "${element(split(",", lookup(var.azs,var.region)), count.index)}"
    map_public_ip_on_launch = "true"
    tags { Name = "${var.vpc_name} public subnet ${count.index}" }
}

resource "aws_subnet" "private" {
    vpc_id = "${aws_vpc.main.id}"
    count = "${length(split(",",lookup(var.azs,var.region)))}"
    cidr_block = "${element(split(",",var.private_networks),count.index)}"
    availability_zone = "${element(split(",", lookup(var.azs,var.region)), count.index)}"
    map_public_ip_on_launch = "false"
    tags { Name = "${var.vpc_name} private subnet ${count.index}" }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.main.id}"
    tags { Name = "${var.vpc_name} igw" }
}

resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }
    tags { Name = "${var.vpc_name} public route" }
}

resource "aws_route_table_association" "rtap" {
    count = "${length(split(",",lookup(var.azs,var.region)))}"
    subnet_id = "${element(aws_subnet.public.*.id,count.index)}"
    route_table_id = "${aws_route_table.public.id}"
}


resource "aws_eip" "nat" {
    vpc = true
}

resource "aws_nat_gateway" "gw" {
    allocation_id = "${aws_eip.nat.id}"
    subnet_id = "${aws_subnet.public.0.id}"
}

resource "aws_route_table" "private" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.gw.id}"
    }
    tags { Name = "${var.vpc_name} Private Route" }
}

resource "aws_route_table_association" "rtaprv" {
    count = "${length(split(",",lookup(var.azs,var.region)))}"
    subnet_id = "${element(aws_subnet.private.*.id,count.index)}"
    route_table_id = "${aws_route_table.private.id}"
}

resource "aws_security_group" "bastion" {
  name = "${var.vpc_name}-bastion"
  description = "Allow all ssh from trusted networks"
  vpc_id = "${aws_vpc.main.id}"
  ingress { from_port=22 to_port=22 protocol="tcp" cidr_blocks=[ "${split(",",var.trusted_networks)}" ] }
  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
  tags { Name = "${var.vpc_name} Bastion" }
}

resource "aws_security_group" "sshserver" {
  name = "${var.vpc_name}-sshserver"
  description = "Allow all ssh from bastion"
  vpc_id = "${aws_vpc.main.id}"
  ingress { from_port=22 to_port=22 protocol="tcp" security_groups=[ "${aws_security_group.bastion.id}" ] }
  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
  tags { Name = "${var.vpc_name} SSH server" }
}

resource "aws_instance" "bastion" {
    ami = "${var.bastion_ami}"
    instance_type = "${var.bastion_type}"
    key_name = "${var.key_name}"
    subnet_id = "${aws_subnet.public.0.id}"
    vpc_security_group_ids = [ "${aws_security_group.bastion.id}" ]
    tags { Name = "bastion" }
}

output "vpc_id" { value = "${aws_vpc.main.id}" }
output "region" { value = "${var.region}" }
output "azs" { value = "${lookup(var.azs,var.region)}" }
output "public_subnets" { value = "${join(",", aws_subnet.public.*.id)}" }
output "private_subnets" { value = "${join(",", aws_subnet.private.*.id)}" }
output "bastion" { value = "${aws_instance.bastion.public_ip}" }
output "sg_sshserver" { value = "${aws_security_group.sshserver.id}" }
