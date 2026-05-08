terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  # Common tags help you find resources easily in the AWS console.
  common_tags = {
    Project   = "uni-k3s-cluster"
    ManagedBy = "terraform"
  }

  # We keep the node definitions in one place so the instance resource stays simple.
  cluster_nodes = {
    control-plane = {
      role             = "control-plane"
      instance_type    = var.control_plane_instance_type
      root_volume_size = var.control_plane_root_volume_size
    }
    worker-1 = {
      role             = "worker"
      instance_type    = var.worker_instance_type
      root_volume_size = var.worker_root_volume_size
    }
    worker-2 = {
      role             = "worker"
      instance_type    = var.worker_instance_type
      root_volume_size = var.worker_root_volume_size
    }
  }

  # For a student project, using the default VPC is the simplest approach.
  default_subnet_id = sort(data.aws_subnets.default.ids)[0]

  # Detect whether the trusted CIDR is IPv6 so we can place it in the correct field.
  trusted_ip_is_ipv6 = length(regexall(":", var.trusted_ip_cidr)) > 0
}

# Look up the default VPC in the selected AWS region.
data "aws_vpc" "default" {
  default = true
}

# Get the subnets that belong to the default VPC.
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Ubuntu 22.04 LTS (Jammy) from Canonical.
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_security_group" "k3s_cluster" {
  name_prefix = "uni-k3s-cluster-"
  description = "Security group for the self-managed k3s cluster"
  vpc_id      = data.aws_vpc.default.id

  # SSH is open from anywhere in this simpler setup.
  # Access is still controlled by your AWS key pair.
  ingress {
    description      = "SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Web traffic for applications that will later run on the cluster.
  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS from anywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "MQTT from anywhere"
    from_port        = 1883
    to_port          = 1883
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Kubernetes API access stays restricted to a trusted IP or network.
  ingress {
    description      = "Kubernetes API from trusted IP/CIDR"
    from_port        = 6443
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = local.trusted_ip_is_ipv6 ? [] : [var.trusted_ip_cidr]
    ipv6_cidr_blocks = local.trusted_ip_is_ipv6 ? [var.trusted_ip_cidr] : []
  }

  # Kubernetes API access between nodes that share this security group.
  ingress {
    description = "Kubernetes API within the cluster security group"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  # Allow all traffic between the three cluster nodes.
  ingress {
    description = "All internal traffic between cluster nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Allow the instances to reach the internet for package updates later.
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "uni-k3s-cluster-sg"
  })
}

resource "aws_instance" "nodes" {
  for_each = local.cluster_nodes

  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = each.value.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = local.default_subnet_id
  vpc_security_group_ids      = [aws_security_group.k3s_cluster.id]
  associate_public_ip_address = true

  # k3s, container images, and local-path PVCs all consume node disk space.
  root_block_device {
    volume_size           = each.value.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = each.key
    Role = each.value.role
  })
}

resource "aws_eip" "control_plane" {
  domain   = "vpc"
  instance = aws_instance.nodes["control-plane"].id

  tags = merge(local.common_tags, {
    Name = "control-plane-eip"
  })
}
