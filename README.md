# Ploff

A monorepo boilerplate - your launchpad for new projects. Contains everything you need:
applications, shared packages, infrastructure code, and documentation.

## Repository Structure

```
├── apps/                  # Application projects (APIs, web apps, services)
├── packages/              # Shared libraries and packages
├── tools/                 # Developer scripts and project generators
├── infra/                 # Infrastructure as Code
│   ├── docker/            # Docker configurations
│   ├── kubernetes/        # Kubernetes manifests
│   └── terraform/         # Terraform modules & environments
├── docs/                  # Documentation
│   ├── adr/               # Architecture Decision Records
│   ├── guides/            # Developer guides
│   └── release-notes/     # Changelogs and release notes
├── .github/               # GitHub Actions, Copilot config, templates
├── .ai/                   # Shared AI assistant instructions
├── .claude/               # Claude Code skills and settings
├── .moon/                 # moon workspace, toolchains and shared tasks
├── .prototools            # Pinned tool versions (moon, Node.js)
└── Makefile               # Entry point for common commands
```

## Quick Start

```bash
# Clone the repository
git clone <repo-url>
cd ploff

# One-time: install proto (toolchain manager), then restart your shell
curl -fsSL https://moonrepo.dev/install/proto.sh | bash

# Install pinned toolchains and verify everything
make setup
make check

# Add projects the solution needs
make stacks
make new-app STACK=dotnet-service NAME=orders

# Start local development environment
make up
```

Builds, tests and CI are orchestrated by [moon](https://moonrepo.dev) - see
[ADR-003](docs/adr/003-monorepo-tooling.md). Run `make help` for all commands.

## Key Conventions

### Applications (`apps/`)

Each application lives in its own directory under `apps/`. An app is anything with its own
release cycle: APIs and microservices, web frontends, mobile apps, tools and jobs.

```
apps/
├── orders/        # Microservice      (make new-app STACK=dotnet-service NAME=orders)
├── portal/        # Web frontend      (make new-app STACK=react-web NAME=portal)
└── importer/      # CLI tool / job    (make new-app STACK=dotnet-console NAME=importer)
```

Each app has:
- A `moon.yml` (language, layer, tags, dependencies) and the standard tasks:
  `build`, `test`, `lint`, `format`, `publish`, `dev`
- Its own README, version (Release Please) and changelog
- A Dockerfile and compose fragment in `infra/docker/` if it runs as a container

See [apps/README.md](apps/README.md).

### Shared Packages (`packages/`)

Shared code that is used by multiple apps. These are internal packages — not published to any
registry. Apps declare them in `dependsOn`, so CI retests and redeploys dependents when a
package changes. See [packages/README.md](packages/README.md).

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

GitHub Actions (`.github/workflows/`). The workflows are generic: no changes are needed when
apps are added.

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `ci.yml` | Push / PR to `main` | `moon ci` - runs tasks of affected projects and their dependents |
| `deploy-dev.yml` | Merge to `main` | Deploys affected `deployable` apps to dev |
| `deploy-staging.yml` | Push to `release/<app>/<version>` | Deploys that app to staging |
| `release-please.yml` | Merge to `main` | Release PRs per app; deploys released apps to production |
| `deploy-app.yml` | Called / manual | Tests, publishes and deploys one app |

See the [Deployment Guide](docs/guides/deployment.md) for details.

## AI Assistants

Configuration for AI coding assistants:

| Assistant | Configuration |
| --- | --- |
| **Claude Code** | `CLAUDE.md` (root) + `.claude/` + `.ai/` |
| **GitHub Copilot** | `.github/copilot-instructions.md` |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting and security practices.

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

See [LICENSE](LICENSE).
