terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = "1.8.5"
}

provider "aws" {
  default_tags {
    tags = {
      Terraform = true
    }
  }
}

data "aws_vpc" "this" {
  filter {
    name = "is-default"
    values = ["true"]
  }
}

data "aws_caller_identity" "this" {}

data "aws_subnets" "this" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name = "default-for-az"
    values = ["true"]
  }
}

locals {
  aws_user_name    = split("/", data.aws_caller_identity.this.arn)[1]
  user_with_suffix = "${local.aws_user_name}-dev"
  default_tags = {
    Name = local.user_with_suffix
  }
}

resource "aws_security_group" "this" {
  description = "IP based filtering for ${local.user_with_suffix}"
  vpc_id      = data.aws_vpc.this.id
  tags        = local.default_tags
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_vpc_security_group_ingress_rule" "private" {
  for_each = toset(var.use_private_ip ? [22, 6443] : [])
  security_group_id = aws_security_group.this.id
  ip_protocol       = "tcp"
  to_port           = each.value
  cidr_ipv4         = "${chomp(data.http.myip.response_body)}/32"
  tags              = local.default_tags
}

resource "aws_vpc_security_group_ingress_rule" "public" {
  for_each = toset(var.use_private_ip ? [] : ["public"])
  security_group_id = aws_security_group.this.id
  ip_protocol       = "all"
  cidr_ipv4         = "${chomp(data.http.myip.response_body)}/32"
  tags              = local.default_tags
}

resource "aws_key_pair" "this" {
  public_key = file("~/.ssh/id_rsa.pub")
  key_name = local.user_with_suffix
  tags     = local.default_tags
}

locals {
  ubuntu_account_ids = {
    aws-us-gov = 513442679011
    aws        = 099720109477
  }
  ami_owner = local.ubuntu_account_ids[split(":", data.aws_caller_identity.this.arn)[1]]
}

data "aws_ami" "this" {
  most_recent = true
  owners = [local.ami_owner]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  ami                                  = data.aws_ami.this.image_id
  create_spot_instance                 = true
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = local.vm_size_map[var.vm_size]["instance_type"]
  key_name                             = aws_key_pair.this.key_name
  spot_price                           = local.vm_size_map[var.vm_size]["spot_price"]
  spot_type                            = "one-time"
  subnet_id                            = data.aws_subnets.this.ids[0]
  tags                                 = local.default_tags
  associate_public_ip_address          = !var.attach_secondary_ip
  secondary_private_ips = []
  user_data = file("./user_data.txt")
  vpc_security_group_ids = [aws_security_group.this.id]
}

resource "aws_ebs_volume" "this" {
  availability_zone = module.ec2_instance.availability_zone
  size              = 120
  type              = "gp3"
  encrypted         = true
}

resource "aws_volume_attachment" "this" {
  device_name = "/dev/sda1"
  volume_id   = aws_ebs_volume.this.id
  instance_id = module.ec2_instance.id
}

resource "aws_eip" "this" {
  for_each = toset(var.attach_secondary_ip ? ["EIP1", "EIP2"] : [])
  tags = {
    Name  = "${local.user_with_suffix}-${each.value}"
    Owner = local.aws_user_name
  }
}

resource "aws_eip_association" "this" {
  for_each    = aws_eip.this
  instance_id = module.ec2_instance.spot_instance_id
  public_ip   = each.value.public_ip
}