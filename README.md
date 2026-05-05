# platform-infra

This repository contains the infrastructure and GitOps configuration for the
software engineering project cluster on AWS.

It covers four main areas:

- Terraform for AWS EC2 infrastructure
- Ansible for installing k3s
- Kubernetes manifests under `k8s/`
- Argo CD applications under `argocd/apps/`

The goal is simple:

1. Provision the servers on AWS
2. Install k3s on those servers
3. Let Argo CD watch Git and deploy Kubernetes manifests automatically

## Repository layout

```text
platform-infra/
├── .github/workflows/       # CI checks for this repo
├── ansible/                 # k3s installation playbooks
├── argocd/apps/             # Argo CD Application manifests
├── k8s/                     # Kubernetes manifests Argo CD deploys
├── terraform/               # AWS infrastructure code
└── README.md
```

## What each folder does

- `terraform/` creates the EC2 instances, security group, and Elastic IP
- `ansible/` installs the k3s control-plane and worker nodes
- `k8s/` contains deployable Kubernetes resources such as the HiveMQ broker
- `argocd/apps/` tells Argo CD which repositories and paths to sync

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

### 3. Install or access Argo CD

Once Argo CD is installed in the cluster, you can access its UI locally with
port forwarding:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then open:

```text
https://localhost:8080
```

The default username is:

```text
admin
```

To get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### 4. Bootstrap the Argo CD app-of-apps

Apply the root Argo CD application:

```bash
kubectl apply -f argocd/apps/e4-app.yaml
```

After that, Argo CD will read the rest of `argocd/apps/` and register the
other applications automatically.

## How GitOps works here

Argo CD watches Git instead of you manually running `kubectl apply` for every
change.

That means the normal workflow is:

1. Edit files in `k8s/` or `argocd/apps/`
2. Commit and push
3. Argo CD detects the change and syncs it to the cluster

## Current Kubernetes manifests in this repo

- `k8s/broker/` contains the HiveMQ MQTT broker manifests
- `k8s/ingress/` contains the ingress-nginx traffic policy override for AWS/k3s

## Useful checks

Check cluster nodes:

```bash
kubectl get nodes
```

Check Argo CD applications:

```bash
kubectl get applications -n argocd
```

Check the MQTT broker resources:

```bash
kubectl get pods -n mqtt
kubectl get svc -n mqtt
```

## Notes

- Do not store secrets directly in Git
- Argo CD deploys what is committed in the repository
- Terraform and Ansible prepare the cluster, but application deployment should
  happen through GitOps manifests
