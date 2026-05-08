# Terraform Infrastructure for the k3s Cluster

This folder provisions only the AWS infrastructure for a small self-managed k3s cluster:

- `control-plane`
- `worker-1`
- `worker-2`

It uses the AWS default VPC in the selected region to keep the setup simple for a university project.
It does not install k3s. Ansible can be used later for installing k3s and joining the workers.

## Files

```text
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── README.md
```

## 1. Initialize Terraform

```bash
cd terraform
terraform init
```

## 2. Set your variables

Copy the example file and edit it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Defaults:

- `aws_region = "ap-southeast-1"` for Singapore
- `control_plane_instance_type = "t3.medium"`
- `control_plane_root_volume_size = 50`
- `worker_instance_type = "t3.large"`
- `worker_root_volume_size = 80`

Set:

- `key_pair_name` to the name of an existing AWS EC2 key pair
- `trusted_ip_cidr` to the public IPv4 or IPv6 CIDR that should be allowed to access the Kubernetes API on port `6443`
- adjust the root EBS volume sizes if you need more or less local storage for k3s, container images, and `local-path` PVCs

Example:

```hcl
trusted_ip_cidr = "203.0.113.10/32"
```

IPv4 single-address example:

```hcl
trusted_ip_cidr = "203.0.113.10/32"
```

IPv6 single-address example:

```hcl
trusted_ip_cidr = "2001:db8::10/128"
```

If you are on a home connection, `/32` usually means only your current IPv4 address and `/128` usually means only your current IPv6 address.

Security model in this version:

- SSH port `22` is open from anywhere and protected by your SSH key pair
- Kubernetes API port `6443` is still restricted to `trusted_ip_cidr` and internal cluster traffic

## 3. Preview the infrastructure

```bash
terraform plan
```

## 4. Create the infrastructure

```bash
terraform apply
```

Terraform will output:

- the control-plane public IP
- the control-plane Elastic IP
- the worker private IPs
- ready-to-copy SSH commands for all three nodes

## 5. SSH into the nodes

Use the SSH commands from the Terraform outputs, or follow this format:

```bash
ssh -i /path/to/your-key.pem ubuntu@CONTROL_PLANE_ELASTIC_IP
ssh -i /path/to/your-key.pem ubuntu@WORKER_PUBLIC_IP
```

The Ubuntu AMI uses the `ubuntu` username.

## 6. Destroy the infrastructure

```bash
terraform destroy
```

Use this when you are done testing so you do not keep AWS resources running.
