# GitHub Copilot Instructions

Repository-wide instructions automatically loaded by GitHub Copilot.
See also [`AGENTS.md`](../AGENTS.md) for project structure and conventions.

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
5. Tasks are orchestrated by moon; use the `Makefile` entry points (`make help`, `make check`,
   `make run APP=<project> TASK=<task>`)
6. Create new apps/packages with `make new-app` / `make new-package`, never by hand-editing CI
7. Never commit secrets or credentials
