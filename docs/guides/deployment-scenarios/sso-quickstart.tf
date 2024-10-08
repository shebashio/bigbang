terraform {
  required_version = "1.9.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.70.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Input variables
variable "your_name" {
  description = "Your name"
  type        = string
}

variable "aws_security_group_name" {
  description = "Security group name"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID, e.g. 123456789012"
  type        = string
}

variable "aws_region" {
  type        = string
  description = "The AWS region, e.g. us-east-1. If you get the 'InvalidClientTokenId: The security token included in the request is invalid' error, it could actually be due to region miss-match. Confirm your region in the AWS Console."
}

# Data sources
data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "this" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name = "group-name"
    values = [var.aws_security_group_name]
  }
}

data "aws_subnets" "this" {

  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name = "default-for-az"
    values = [true]
  }
}

data "aws_subnet" "this" {
  id = data.aws_subnets.this.ids[0]
}

# Key Pair creation
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

locals {
  your_name = replace(var.your_name, " ", "")
}

resource "aws_key_pair" "this" {
  key_name   = "${local.your_name}KeycloakSSOQuickstart"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "private_key" {
  filename        = "${pathexpand("~/.ssh")}/${local.your_name}KeycloakSSOQuickstart.pem"
  content         = tls_private_key.this.private_key_pem
  file_permission = "0600"
}

data "aws_ami" "this" {
  most_recent = true

  owners = [var.aws_account_id]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 instances
resource "aws_instance" "ec2_instances" {
  count = 2

  ami           = data.aws_ami.this.image_id
  instance_type = "t3a.2xlarge"
  key_name      = aws_key_pair.this.key_name
  subnet_id     = data.aws_subnet.this.id
  vpc_security_group_ids = [data.aws_security_group.this.id]

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 100
  }

  tags = {
    Name = "${local.your_name}-KeycloakSSOQuickstart"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Output public IP addresses
output "ec2_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.ec2_instances[*].public_ip
}
