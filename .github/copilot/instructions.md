# GitHub Copilot Instructions
#
# This file is automatically discovered by GitHub Copilot.
# It provides repository-wide context for AI-assisted coding.

## Project Context

This is a language-agnostic monorepo with multiple applications, shared packages,
infrastructure code, and documentation.

## Repository Layout

- `apps/` — Deployable applications (APIs, web apps, workers)
- `packages/` — Shared internal libraries
- `tools/` — Developer scripts and generators
- `infra/` — Infrastructure as Code (Docker, Kubernetes, Terraform)
- `docs/` — Documentation (ADRs, guides, release notes)

## Coding Conventions

- Follow existing code style in each app/package
- Use Conventional Commits: `<type>(<scope>): <description>`
- Keep shared logic in `packages/`, not duplicated across apps
- All infrastructure is defined as code in `infra/`
- Architectural decisions must be documented as ADRs in `docs/adr/`

## Key Principles

1. Each app in `apps/` is independently deployable
2. Shared code belongs in `packages/`
3. Infrastructure changes go in `infra/`, not in app directories
4. Every change should have tests
5. Use `Makefile` as the universal task runner (`make help` for commands)
6. Never commit secrets or credentials
