# Deployment Guide

How to deploy applications from this monorepo to various environments.

## Overview

This monorepo supports multiple deployment targets:

| Target | Tools | Configuration |
| --- | --- | --- |
| VPS / VM | Docker Compose + SSH | `infra/docker/docker-compose.yml` |
| Kubernetes | Kustomize + kubectl | `infra/kubernetes/` |
| Azure Cloud | Terraform + Azure CLI | `infra/terraform/` |
| Other Cloud | Terraform | `infra/terraform/` |

## CI/CD Platforms

| Platform | Configuration | Docs |
| --- | --- | --- |
| GitHub Actions | `.github/workflows/` | [GitHub Actions docs](https://docs.github.com/en/actions) |
| Azure DevOps | `.azure/pipelines/` | [Azure Pipelines docs](https://learn.microsoft.com/en-us/azure/devops/pipelines/) |

Choose one based on your platform. Both are pre-configured with CI and deployment templates.

## Environments

| Environment | Branch | Trigger | Approval |
| --- | --- | --- | --- |
| `dev` | `main` | Automatic | None |
| `staging` | `main` | Manual | Optional |
| `production` | `main` | Manual | Required |

## Docker-Based Deployment (VPS / VM)

### Prerequisites
- Target server with Docker and Docker Compose installed
- SSH access to the server
- Container registry access (GitHub Container Registry, Docker Hub, Azure ACR, etc.)

### Steps

1. **Build and push images:**
   ```bash
   docker build -f infra/docker/Dockerfile.<app> -t registry.example.com/<app>:latest .
   docker push registry.example.com/<app>:latest
   ```

2. **Deploy via SSH:**
   ```bash
   ssh user@server 'cd /opt/app && docker compose pull && docker compose up -d'
   ```

## Kubernetes Deployment

### Prerequisites
- Kubernetes cluster access
- `kubectl` and `kustomize` installed
- Container images pushed to a registry

### Steps

1. **Update image tags in the overlay:**
   ```bash
   cd infra/kubernetes/overlays/<env>
   kustomize edit set image <app>=registry.example.com/<app>:<tag>
   ```

2. **Apply:**
   ```bash
   kubectl apply -k infra/kubernetes/overlays/<env>
   ```

## Terraform (Cloud Infrastructure)

### Prerequisites
- Terraform CLI installed
- Cloud provider credentials configured
- Remote state backend configured

### Steps

1. **Initialize:**
   ```bash
   cd infra/terraform/environments/<env>
   terraform init
   ```

2. **Plan:**
   ```bash
   terraform plan
   # Or: make infra-plan TF_ENV=<env>
   ```

3. **Apply:**
   ```bash
   terraform apply
   # Or: make infra-apply TF_ENV=<env>
   ```

## Secrets Management

- **Never** commit secrets to the repository
- Use environment variables for runtime secrets
- Use your CI/CD platform's secret management:
  - GitHub Actions: Repository secrets / Environment secrets
  - Azure DevOps: Variable groups / Azure Key Vault
- For Kubernetes: Use Kubernetes Secrets or a secrets manager (e.g., Sealed Secrets, External Secrets)
- For Terraform: Use variables marked as `sensitive = true` and store in a vault
