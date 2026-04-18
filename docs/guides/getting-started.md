# Getting Started

Welcome to the project! This guide will help you set up your development environment.

## Prerequisites

- [Git](https://git-scm.com/) (2.x+)
- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/)
- [Make](https://www.gnu.org/software/make/) (usually pre-installed on macOS/Linux; on Windows use WSL or install via `choco install make`)
- [Python](https://www.python.org/) (3.9+) — for MkDocs documentation (`pip install mkdocs-material`)
- Language-specific tools as needed by individual apps (see each app's README)

## Clone the Repository

```bash
git clone <repo-url>
cd <project-name>
```

## Repository Overview

```
apps/           → Deployable applications (APIs, web apps, workers)
packages/       → Shared internal libraries
tools/          → Developer scripts and generators
infra/          → Infrastructure as Code (Docker, K8s, Terraform)
docs/           → Documentation (you are here)
```

See the root [README.md](../index.md) for the full structure.

## Setup

```bash
# Install dependencies for all apps
make setup

# Start the local development environment (Docker Compose)
make up

# Verify everything is running
make ps
```

## Common Commands

```bash
make help              # Show all available commands
make up                # Start local Docker environment
make down              # Stop local Docker environment
make test              # Run all tests
make lint              # Run all linters
make build             # Build all applications
make logs              # Tail logs from all services
make docs-serve         # Serve docs locally (http://localhost:8000)
make docs-build         # Build static docs site
```

## Adding Your First App

See `apps/README.md` for step-by-step instructions on adding a new application.

## Next Steps

- Read the [Development Guide](development.md) for day-to-day workflows
- Read the [Testing Strategy](testing.md) for testing conventions and patterns
- Read the [Observability Guide](observability.md) for logging, metrics, and tracing
- Read the [Deployment Guide](deployment.md) for deployment procedures
- Read the [Release Process](release-process.md) for versioning and release workflow
- Read the [Git Hooks Guide](git-hooks.md) for pre-commit validation setup
- Review existing [Architecture Decision Records](../adr/index.md) for context on past decisions
