# Contributing to Project Name

> **TODO**: Replace `Project Name` with your actual project name.

Thank you for contributing! This document outlines conventions and processes for contributing to this monorepo.

## Table of Contents

- [Getting Started](#getting-started)
- [Repository Structure](#repository-structure)
- [Development Workflow](#development-workflow)
- [Branching Strategy](#branching-strategy)
- [Commit Messages](#commit-messages)
- [Pull Requests](#pull-requests)
- [Code Style](#code-style)
- [Architecture Decisions](#architecture-decisions)

## Getting Started

1. Clone the repository
2. Read the [Getting Started Guide](docs/guides/getting-started.md)
3. Run `make setup` to install dependencies
4. Run `make test` to verify everything works

## Repository Structure

See [README.md](README.md#repository-structure) for the full layout. Key rule: **every deployable unit lives in `apps/`, shared code in `packages/`**.

## Development Workflow

1. Create a feature branch from `main`
2. Make changes, commit often with clear messages
3. Ensure tests pass: `make test`
4. Ensure linting passes: `make lint`
5. Open a Pull Request

## Branching Strategy

| Branch | Purpose |
| --- | --- |
| `main` | Production-ready code. Always deployable. |
| `develop` | Integration branch (optional, for teams that prefer it). |
| `feature/<name>` | New features. Branch from `main` or `develop`. |
| `fix/<name>` | Bug fixes. |
| `release/<version>` | Release preparation (optional). |
| `hotfix/<name>` | Urgent production fixes. |

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`

**Scope**: The app or package name (e.g., `api`, `web`, `shared-utils`, `infra`)

**Examples**:
```
feat(api): add user authentication endpoint
fix(web): resolve navigation state bug
docs(adr): add ADR for database selection
ci: add staging deployment workflow
```

## Pull Requests

- Use the [PR template](.github/PULL_REQUEST_TEMPLATE.md)
- Link related issues
- Request review from code owners (see [CODEOWNERS](.github/CODEOWNERS))
- All CI checks must pass
- At least one approval required

## Code Style

- Use `.editorconfig` for base formatting (indentation, line endings)
- Each app/package may have its own language-specific linting configuration
- Shared standards are documented in `.ai/shared/coding-standards.md`

## Architecture Decisions

Significant decisions should be recorded as **Architecture Decision Records (ADRs)**:

1. Copy `docs/adr/000-template.md`
2. Number it sequentially (e.g., `002-database-selection.md`)
3. Fill in the template
4. Submit as part of your PR

See [ADR Guide](docs/adr/000-template.md) for the template and examples.
