# Infrastructure as Code

This directory contains all infrastructure definitions. Everything needed to provision,
configure, and deploy the project's infrastructure is defined here as code.

## Structure

```
infra/
├── docker/                    # Docker configurations
│   ├── .dockerignore          # Files to exclude from Docker builds
│   ├── docker-compose.yml     # Local development compose
│   └── Dockerfile.<app>       # Per-app Dockerfiles
├── kubernetes/                # Kubernetes manifests
│   ├── base/                  # Base manifests (shared across environments)
│   └── overlays/              # Environment-specific overlays (Kustomize)
│       ├── dev/
│       ├── staging/
│       └── production/
└── terraform/                 # Terraform IaC
    ├── modules/               # Reusable Terraform modules
    └── environments/          # Per-environment configurations
        ├── dev/
        ├── staging/
        └── production/
```

## Docker

Used for both local development and production deployments.

```bash
# Start local dev environment
make up

# Stop local dev environment
make down

# Build all images
make build-docker

# View logs
make logs
```

## Kubernetes

Uses [Kustomize](https://kustomize.io/) for environment-specific overlays.

```bash
# Apply to dev
kubectl apply -k infra/kubernetes/overlays/dev

# Apply to production
kubectl apply -k infra/kubernetes/overlays/production
```

## Terraform

Cloud infrastructure provisioning. Supports any cloud provider.

```bash
# Plan changes for dev
make infra-plan TF_ENV=dev

# Apply changes to dev
make infra-apply TF_ENV=dev
```

## Adding Infrastructure for a New App

1. Create `infra/docker/Dockerfile.<app-name>`
2. Add the service to `infra/docker/docker-compose.yml`
3. (If using K8s) Add base manifests to `infra/kubernetes/base/`
4. (If using K8s) Add overlays for each environment
5. (If using Terraform) Add or update modules as needed

## Environments

| Environment | Purpose | Deployment |
| --- | --- | --- |
| `dev` | Development / testing | Automatic on merge to main |
| `staging` | Pre-production validation | Manual trigger |
| `production` | Live environment | Manual trigger with approvals |
