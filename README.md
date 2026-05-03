# platform-infra — E4 Platform & Infrastructure Repository

> **E4 Subgroup** | Member 2 — CI/CD Pipeline (GitHub Actions + Argo CD)
>
> This repository is the **central hub** for the Energy Management System's deployment infrastructure.
> It does not contain application code — instead it contains the automation and configuration
> that builds, tests, and deploys code from E1, E2, and E3 automatically.

---

## What Does This Repository Do?

In simple terms:

1. **Every time code is pushed** to this repo, GitHub Actions automatically runs a pipeline that:
   - Checks that all YAML files are valid
   - Scans the codebase for security vulnerabilities (using Trivy)
   - (Later) Tells Argo CD to deploy the latest version to Kubernetes

2. **Argo CD watches all 4 repositories** (E1, E2, E3, E4) and automatically applies any
   Kubernetes manifest changes to the cluster — no manual `kubectl apply` needed.

---

## Folder Structure

```
platform-infra/
│
├── .github/
│   └── workflows/
│       └── ci.yml          ← The GitHub Actions pipeline (runs on every push/PR)
│
├── argocd/
│   └── apps/
│       ├── e1-app.yaml     ← Argo CD config for E1 (energy-edge-nodes)
│       ├── e2-app.yaml     ← Argo CD config for E2 (data-intelligence)
│       ├── e3-app.yaml     ← Argo CD config for E3 (ems-app)
│       └── e4-app.yaml     ← Argo CD ROOT app (manages e1+e2+e3+e4 together)
│
└── README.md               ← This file
```

---

## How the CI/CD Pipeline Works — Step by Step

The pipeline is defined in `.github/workflows/ci.yml` and has **3 jobs** that run in order:

```
Push to main
     │
     ▼
┌─────────────────────┐
│  Job 1: Validate    │  Checks that all .yml files are syntactically correct
│  YAML Files         │  Tool: yamllint
└────────┬────────────┘
         │ (only if Job 1 passes)
         ▼
┌─────────────────────┐
│  Job 2: Trivy       │  Scans the whole repo for security vulnerabilities
│  Security Scan      │  Tool: Trivy (by Aqua Security)
└────────┬────────────┘
         │ (only if Job 2 passes)
         ▼
┌─────────────────────┐
│  Job 3: Argo CD     │  [PLACEHOLDER] Will trigger Argo CD to deploy to K8s
│  Sync               │  Requires: ARGOCD_SERVER and ARGOCD_TOKEN secrets
└─────────────────────┘
```

### What each job does in detail

| Job | What it runs | What it checks |
|-----|-------------|----------------|
| validate-yaml | `yamllint -d relaxed .` | Every `.yml`/`.yaml` file has valid syntax |
| security-scan | `aquasecurity/trivy-action@master` | Known CVEs in files and dependencies |
| argocd-sync | placeholder `echo` (real command commented out) | Will sync Argo CD once cluster is up |

---

## What Other Teams Need to Do

### E1 Team (energy-edge-nodes)
- Create a `k8s/` folder in your repository
- Add Kubernetes Deployment and Service YAML files for your ESP32 firmware service
- Argo CD will automatically pick up changes when you push to `main`

### E2 Team (data-intelligence)
- Create a `k8s/` folder in your repository
- Add Kubernetes manifests for each of your services:
  - Kafka ingestion (`Dockerfile.ingestion`)
  - Flink/Spark streaming (`Dockerfile.streaming`)
  - Forecasting model (`Dockerfile.forecasting`)
  - Anomaly detection (`Dockerfile.anomaly`)
  - FastAPI (`Dockerfile.api`)
- Argo CD will automatically pick up changes when you push to `main`

### E3 Team (ems-app)
- Create a `k8s/` folder in your repository (you currently have `docker-compose.yml` only)
- Convert your `docker-compose.yml` services into Kubernetes Deployment + Service YAMLs for:
  - Go backend
  - Next.js frontend
  - PostgreSQL
- Argo CD will automatically pick up changes when you push to `main`

> **Tip:** If you need help converting docker-compose to Kubernetes YAML, use the tool
> [Kompose](https://kompose.io/) — run `kompose convert` in your repo folder.

---

## How to Add a New Service to the Pipeline

To add a new service (e.g., a new E5 team or a new microservice):

1. **Create a new Argo CD app file** in `argocd/apps/`:
   ```bash
   # Copy an existing app as a template
   cp argocd/apps/e3-app.yaml argocd/apps/e5-app.yaml
   ```

2. **Edit the new file** — change these 4 fields:
   ```yaml
   metadata:
     name: e5-new-service          # unique name
   spec:
     source:
       repoURL: https://github.com/Prypiatos/new-repo.git   # their repo
     destination:
       namespace: e5-new-service   # their namespace
   ```

3. **Push to main** — Argo CD's e4-platform app will automatically detect the new file
   and register the new service. No manual steps needed.

---

## How Argo CD Connects to Kubernetes

```
GitHub Repository (platform-infra)
         │
         │  Argo CD polls for changes every 3 minutes
         │  (or immediately when triggered by the pipeline)
         ▼
    Argo CD Server
    (runs inside Kubernetes)
         │
         │  Reads the YAML manifests from Git
         │  Compares with what's already running in the cluster
         │  Applies only what changed
         ▼
  Kubernetes Cluster
  ┌──────────────────────────────────────────┐
  │  Namespace: e1-edge-nodes                │
  │  Namespace: e2-data-intelligence         │
  │  Namespace: e3-ems-app                   │
  │  Namespace: e4-platform                  │
  └──────────────────────────────────────────┘
```

### The "App of Apps" Pattern

`e4-app.yaml` is special — it is the **root application** that manages all other apps.
When you apply `e4-app.yaml` to the cluster, Argo CD reads the entire `argocd/apps/` folder
and automatically registers e1, e2, e3, and e4. This means the **entire system can be
bootstrapped with a single command**:

```bash
kubectl apply -f argocd/apps/e4-app.yaml
```

---

## Required GitHub Secrets

Before the Argo CD sync step can work, you must add two secrets to this repository.

**How to add secrets:**
1. Go to this repo on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

| Secret Name | What It Contains | Example Value |
|-------------|-----------------|---------------|
| `ARGOCD_SERVER` | The URL of the Argo CD server | `argocd.your-cluster.com` |
| `ARGOCD_TOKEN` | An Argo CD API token | (generate in Argo CD UI → Settings → Accounts) |

> These secrets are **never stored in code** — they are injected by GitHub Actions at runtime.

---

## Local Development / Testing

You do not need Kubernetes to test the YAML files locally.

**Test YAML syntax:**
```bash
pip install yamllint
yamllint -d relaxed .
```

**Test security scan:**
```bash
# Install Trivy: https://aquasecurity.github.io/trivy/
trivy fs .
```

**Apply Argo CD apps (once cluster is ready):**
```bash
# Apply just the root app — it handles the rest automatically
kubectl apply -f argocd/apps/e4-app.yaml
```

---

## Team Members — E4 Subgroup

| Member | Responsibility |
|--------|---------------|
| Member 1 | Docker & Kubernetes setup |
| **Member 2 (you)** | **CI/CD Pipelines (GitHub Actions + Argo CD)** |
| Member 3 | Monitoring (Prometheus, Grafana, ELK) |
| Member 4 | API Gateway & Security Scanning (Kong, Trivy, OWASP ZAP) |
| Member 5 | Authentication (Keycloak, Vault) |
