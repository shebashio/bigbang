terraform {
  required_version = "1.9.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.70.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Input variables
variable "key_output_directory" {
  description = "The directory in which the private key for accessing the VMs will be saved."
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

data "http" "my_public_ip" {
  url = "https://api.ipify.org"
}


resource "aws_security_group_rule" "allow_rule" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${data.http.my_public_ip.response_body}/32"]
  security_group_id = data.aws_security_group.this.id

  description = "${local.project}: Allow inbound TCP/SSH traffic for ${local.user_name}"
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
  project = "KeycloakSSOQuickstart"
}

data "aws_caller_identity" "current" {}

resource "aws_key_pair" "this" {
  key_name   = "${local.user_name}${local.project}"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "private_key" {
  filename        = "${pathexpand(var.key_output_directory)}/${local.user_name}${local.project}.pem"
  content         = tls_private_key.this.private_key_pem
  file_permission = "0600"
}

locals {
  user_name = split("/", data.aws_caller_identity.current.arn)[1]
  ssh_config = join("\n", [
    for k, v in {
      keycloak = aws_instance.ec2_instances[0].public_ip
      workload = aws_instance.ec2_instances[1].public_ip
    } : <<EOT
Host ${k}-cluster
  Hostname ${v}  #IP Address of VM1 (future k3d cluster)
  IdentityFile ${local_file.private_key.filename}
  User ubuntu
  StrictHostKeyChecking no
EOT
  ])
}

resource "local_file" "ssh_config" {
  filename = "${pathexpand(var.key_output_directory)}/${local.user_name}${local.project}config"
  content  = local.ssh_config
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
    Name = "${local.user_name}-${local.project}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Output public IP addresses
output "ssh_config_include" {
  description = "Add the following line to your ~/.ssh/config file. Then you can ssh into the VMs like this: ssh keycloak-cluster ; ssh workload-cluster"
  value       = <<EOT
Add the following line to the **TOP** of your  ~/.ssh/config file (create the dir/file if they don't exist):

###
Include ${local_file.ssh_config.filename}
###

Then you can ssh into the VMs like this:
$ ssh keycloak-cluster
$ ssh workload-cluster
EOT
}
