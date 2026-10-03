# Getting Started

Welcome to the project! This guide will help you set up your development environment.

> Starting a **new solution** from this template? Follow [Starting a New Solution](new-solution.md) first.

## Prerequisites

- [Git](https://git-scm.com/) (2.x+)
- Bash — all scripts in `tools/scripts/` are Bash (on Windows use WSL or the devcontainer)
- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/)
- [Make](https://www.gnu.org/software/make/) (usually pre-installed on macOS/Linux; on Windows use WSL)
- [proto](https://moonrepo.dev/proto) — installs the pinned versions of moon and Node.js from `.prototools`
- [.NET SDK](https://dotnet.microsoft.com/download) — version from `global.json` (for .NET projects)
- [Python](https://www.python.org/) (3.9+) — for MkDocs documentation (`pip install -r docs/requirements.txt`)
- Language-specific tools as needed by individual apps (see each app's README)

## Clone the Repository

```bash
git clone <repo-url>
cd ploff
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
# One-time: install proto (toolchain manager), then restart your shell
make install-proto

# Install moon + Node.js (pinned in .prototools), sync the workspace and git hooks
make setup

# Security scanners for the pre-commit hook and `make scan` (pinned, checksum-verified)
make install-scanners

# Lint, type-check and test every project
make check

# Start the local development environment (Docker Compose)
make up
make ps
```

Tasks are orchestrated by [moon](https://moonrepo.dev) — see
[ADR-003](../adr/003-monorepo-tooling.md). The Makefile wraps the common commands.

## Common Commands

```bash
make help                          # Show all available commands
make projects                      # List all projects (apps and packages)
make check                         # Lint + type-check + test everything
make ci                            # Run only tasks affected by your changes (like CI)
make run APP=sample-api TASK=test  # Run one task of one project
make dev APP=sample-web            # Start one project's dev server
make build                         # Build all projects
make up / make down / make logs    # Local Docker Compose environment
make docs-serve                    # Serve docs locally (http://localhost:8000)
```

## Adding Your First App

```bash
make stacks                                  # List available generators
make new-app STACK=dotnet-service NAME=orders
make run APP=orders TASK=test
```

See `apps/README.md` for details.

## Next Steps

- Read the [Development Guide](development.md) for day-to-day workflows
- Read the [Testing Strategy](testing.md) for testing conventions and patterns
- Read the [Observability Guide](observability.md) for logging, metrics, and tracing
- Read the [Deployment Guide](deployment.md) for deployment procedures
- Read the [Release Process](release-process.md) for versioning and release workflow
- Read the [Git Hooks Guide](git-hooks.md) for pre-commit validation setup
- Review existing [Architecture Decision Records](../adr/index.md) for context on past decisions
