# Project Name

> **TODO**: Replace `Project Name` with your actual project name.

A monorepo containing all applications, shared packages, infrastructure code, and documentation for **Project Name**.

## Repository Structure

```
├── apps/                  # Application projects (APIs, web apps, services)
├── packages/              # Shared libraries and packages
├── tools/                 # Developer scripts, generators, utilities
├── infra/                 # Infrastructure as Code
│   ├── docker/            # Docker configurations
│   ├── kubernetes/        # Kubernetes manifests
│   └── terraform/         # Terraform modules & environments
├── docs/                  # Documentation
│   ├── adr/               # Architecture Decision Records
│   ├── guides/            # Developer guides
│   └── release-notes/     # Changelogs and release notes
├── .github/               # GitHub Actions, Copilot config, templates
├── .azure/                # Azure DevOps pipeline definitions
├── .ai/                   # AI assistant instructions (Claude, etc.)
└── Makefile               # Common commands (universal task runner)
```

## Quick Start

```bash
# Clone the repository
git clone <repo-url>
cd <project-name>

# See all available commands
make help

# Start local development environment
make up

# Run all tests
make test

# Run linting
make lint
```

## Key Conventions

### Applications (`apps/`)

Each application lives in its own directory under `apps/`. An app is anything that gets deployed independently — APIs, web frontends, background workers, etc.

```
apps/
├── web/           # Frontend application
├── api/           # Primary REST/GraphQL API
├── api-admin/     # Admin API
└── worker/        # Background job processor
```

Each app should have:
- Its own `Dockerfile` (in `infra/docker/` or within the app)
- Its own README with setup instructions
- Its own build/test commands wired into the root `Makefile`

### Shared Packages (`packages/`)

Shared code that is used by multiple apps. These are internal packages — not published to any registry.

```
packages/
├── shared-models/    # Domain models, DTOs
├── shared-utils/     # Utility functions
└── shared-config/    # Shared configuration schemas
```

### Infrastructure (`infra/`)

All infrastructure is defined as code. See [Infrastructure Guide](docs/guides/deployment.md).

### Documentation (`docs/`)

- **ADRs**: Record architectural decisions in `docs/adr/`. See the [ADR template](docs/adr/000-template.md).
- **Guides**: Developer onboarding and operational guides in `docs/guides/`.
- **Testing**: Testing strategy and conventions in [Testing Strategy](docs/guides/testing.md).
- **Release Notes**: Track releases in `docs/release-notes/`.

## CI/CD

This repository supports two CI/CD approaches:

| Approach | Configuration |
| --- | --- |
| **GitHub Actions** | `.github/workflows/` |
| **Azure DevOps** | `.azure/pipelines/` |

Choose one (or both) depending on your platform. See [Deployment Guide](docs/guides/deployment.md) for details.

## AI Assistants

Configuration for AI coding assistants:

| Assistant | Configuration |
| --- | --- |
| **Claude Code** | `CLAUDE.md` (root) + `.ai/claude/` |
| **GitHub Copilot** | `.github/copilot/instructions.md` |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

See [LICENSE](LICENSE).
