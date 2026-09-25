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

## CI/CD Platform

CI/CD runs on GitHub Actions (`.github/workflows/`). All workflows are generic:

- `deploy-app.yml` deploys one app: it runs `moon run <app>:test <app>:publish` and ships the
  artifact in `apps/<app>/dist`. Replace its `Deploy` step with your target's commands.
- `deploy-dev.yml` deploys every affected app tagged `deployable` (in `moon.yml`) on merge
  to `main`, including apps that depend on a changed shared package.
- `release-please.yml` deploys each app released by Release Please to production.

See [ADR-003](../adr/003-monorepo-tooling.md).

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
- For Kubernetes: Use Kubernetes Secrets or a secrets manager (e.g., Sealed Secrets, External Secrets)
- For Terraform: Use variables marked as `sensitive = true` and store in a vault
