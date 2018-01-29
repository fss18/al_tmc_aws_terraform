# Set variables
variable "vpc_id" {
	description = "VPC into which Threat Manager will be deployed (Must have available EIPs)."
}

variable "subnet_id" {
	description = "ID of a DMZ subnet, with a default route to an IGW, into which Threat Manager will be deployed."
}

variable "instance_type" {
	description = "EC2 Instance Type Threat Manager will be spun up as (Supported: c3.large, c3.xlarge, c3.2xlarge, c4.large, c4.xlarge, c4.2xlarge)."
}

variable "tag_name" {
	description = "Provide a tag name for your Threat Manager instance."
}
variable "claimCIDR" {
	description = "CIDR netblock which will be submitting the web form that the appliance serves for claiming over port 80 (This rule can be removed after the appliance has been claimed)."
}

variable "monitoringCIDR" {
	description = "CIDR netblock to be monitored (Where agents will be installed)."
}

# Latest AMI as per Oct 2017, contact AlertLogic (support@alertlogic.com) if you want to see the latest AMI per region
variable "aws_amis" {
  default = {
		ap-south-1 = "ami-f6ccb499"
		eu-west-2 = "ami-321d0c56"
		eu-west-1 = "ami-b6c52ecf"
		ap-northeast-2 = "ami-26a17848"
		ap-northeast-1 = "ami-dd17f5bb"
		sa-east-1 = "ami-a9b8cfc5"
		ca-central-1 = "ami-9e0db2fa"
		ap-southeast-1 = "ami-a4d24fc7"
		ap-southeast-2 = "ami-9dbda2fe"
		eu-central-1 = "ami-909438ff"
		us-east-1 = "ami-c2a8f7b9"
		us-east-2 = "ami-322f0f57"
		us-west-1 = "ami-8b765eeb"
		us-west-2 = "ami-cb9f85b2"
  }
}

# Data sources
data "aws_region" "current" {
  current = true
}

# Create a security group policy and setup rules for Threat Manager appliance
resource "aws_security_group" "tmc_sg" {
	name = "Alert Logic Threat Manager Security Group"
	tags {
		Name = "Alert Logic Threat Manager Security Group"
	}
	vpc_id = "${var.vpc_id}"

	ingress	{
	protocol = "tcp"
	cidr_blocks = ["204.110.218.96/27"]
	from_port = 22
	to_port = 22
}
ingress	{
	protocol = "tcp"
	cidr_blocks = ["204.110.219.96/27"]
	from_port = 22
	to_port = 22
}
ingress	{
	protocol = "tcp"
	cidr_blocks = ["208.71.209.32/27"]
	from_port = 22
	to_port = 22
}
ingress	{
	protocol = "tcp"
	cidr_blocks = ["185.54.124.0/24"]
	from_port = 22
	to_port = 22
}
ingress	{
	protocol = "tcp"
	cidr_blocks = ["${var.monitoringCIDR}"]
	from_port = 7777
	to_port = 7777
}
ingress	{
	protocol = "tcp"
	cidr_blocks = ["${var.monitoringCIDR}"]
	from_port = 443
	to_port = 443
}
ingress	{
	protocol = "tcp"
	cidr_blocks = ["${var.claimCIDR}"]
	from_port = 80
	to_port = 80
}
egress {
	protocol = "tcp"
	cidr_blocks = ["204.110.218.96/27"]
	from_port = 443
	to_port = 443
}
egress {
	protocol = "tcp"
	cidr_blocks = ["204.110.219.96/27"]
	from_port = 443
	to_port = 443
}
egress {
	protocol = "tcp"
	cidr_blocks = ["208.71.209.32/27"]
	from_port = 443
	to_port = 443
}
egress {
	protocol = "tcp"
	cidr_blocks = ["185.54.124.0/24"]
	from_port = 443
	to_port = 443
}
egress {
	protocol = "tcp"
	cidr_blocks = ["204.110.218.96/27"]
	from_port = 4138
	to_port = 4138
}
egress {
	protocol = "tcp"
	cidr_blocks = ["204.110.219.96/27"]
	from_port = 4138
	to_port = 4138
}
egress {
	protocol = "tcp"
	cidr_blocks = ["208.71.209.32/27"]
	from_port = 4138
	to_port = 4138
}
egress {
	protocol = "tcp"
	cidr_blocks = ["185.54.124.0/24"]
	from_port = 4138
	to_port = 4138
}
egress {
	protocol = "udp"
	cidr_blocks = ["8.8.8.8/32"]
	from_port = 53
	to_port = 53
}
egress {
	protocol = "udp"
	cidr_blocks = ["8.8.4.4/32"]
	from_port = 53
	to_port = 53
}
egress {
	protocol = "tcp"
	cidr_blocks = ["8.8.8.8/32"]
	from_port = 53
	to_port = 53
}
egress {
	protocol = "tcp"
	cidr_blocks = ["8.8.4.4/32"]
	from_port = 53
	to_port = 53
}

# Launch a Threat Manager instance from a shared AMI
resource "aws_instance" "tmc" {
	ami = "${lookup(var.aws_amis, data.aws_region.current.name)}"
	instance_type = "${var.instance_type}"
	subnet_id = "${var.subnet_id}"
	vpc_security_group_ids = ["${aws_security_group.tmc_sg.id}"]
	tags {
		Name = "${var.tag_name}"
	}
	depends_on = ["aws_security_group.tmc_sg"]
}

# Allocate a new Elastic IP to be associated with the new Threat Manager instance
resource "aws_eip" "tmc" {
	instance = "${aws_instance.tmc.id}"
	vpc      = true
	depends_on = ["aws_instance.tmc"]
}

# Outputs
output "Threat Manager public IP" {
	value = "${aws_eip.tmc.public_ip}"
}

output "Threat Manager private IP" {
	value = "${aws_instance.tmc.private_ip}"
}

output "Threat Manager security group (if needed add this to your EC2 instance outbound rules" {
	value = "${aws_security_group.tmc_sg.id}"
}
