# platform-infra

This repository contains the infrastructure and Kubernetes deployment assets
for the software engineering project cluster on AWS.

It currently covers three main areas:

- Terraform for AWS EC2 infrastructure
- Ansible for installing k3s
- Kubernetes manifests under `k8s/`

The goal is simple:

1. Provision the servers on AWS
2. Install k3s on those servers
3. Deploy Kubernetes resources from the manifests in this repo

## Repository layout

```text
platform-infra/
├── .github/workflows/       # CI checks for this repo
├── ansible/                 # k3s installation playbooks
├── k8s/                     # Kubernetes manifests
├── terraform/               # AWS infrastructure code
└── README.md
```

## What each folder does

- `terraform/` creates the EC2 instances, security group, and Elastic IP
- `ansible/` installs the k3s control-plane and worker nodes
- `k8s/` contains deployable Kubernetes resources such as the HiveMQ broker

## Typical setup order

### 1. Create the AWS infrastructure

Go to [terraform/README.md](/home/sheron/Documents/sem4se/platform-infra/terraform/README.md:1) and run:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Install k3s on the EC2 instances

Update the inventory in [ansible/inventory.ini](/home/sheron/Documents/sem4se/platform-infra/ansible/inventory.ini:1), then run:

```bash
cd ansible
ansible-playbook install-k3s.yml
```

### 3. Deploy Kubernetes manifests

Apply manifests directly while the deployment layout is being rebuilt:

```bash
kubectl apply -k k8s/
```

There is currently no active Argo CD application setup in this repository.
When GitOps is reintroduced later, the deployment flow can be documented again
from scratch.

## Current Kubernetes manifests in this repo

- `k8s/broker/` contains the HiveMQ MQTT broker manifests
- `k8s/ingress/` contains the ingress-nginx traffic policy override for AWS/k3s

## Useful checks

Check cluster nodes:

```bash
kubectl get nodes
```

Check the MQTT broker resources:

```bash
kubectl get pods -n mqtt
kubectl get svc -n mqtt
```

## Notes

- Do not store secrets directly in Git
- Terraform and Ansible prepare the cluster
- The current deployment assets in this repo are plain Kubernetes manifest

  # Project Architecture

  <img width="934" height="584" alt="image" src="https://github.com/user-attachments/assets/39b4eab3-9c6b-4e8e-9eda-44a582479bf4" />

  
