variable "aws_region" {
  description = "AWS region where the infrastructure will be created."
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_type" {
  description = "EC2 instance type for all k3s nodes."
  type        = string
  default     = "t3.small"
}

variable "trusted_ip_cidr" {
  description = "Trusted public IPv4 or IPv6 CIDR allowed to reach the Kubernetes API on port 6443, for example 203.0.113.10/32 or 2001:db8::10/128."
  type        = string
}

variable "key_pair_name" {
  description = "Name of an existing AWS EC2 key pair to attach to the instances."
  type        = string
}
