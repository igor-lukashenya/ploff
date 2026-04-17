# CLAUDE.md — Project Instructions for Claude Code
#
# This file is automatically discovered by Claude Code at the repository root.
# It provides context and instructions for AI-assisted development.

## Project Overview

This is a monorepo containing multiple applications, shared packages, infrastructure
code, and documentation. The repository is language-agnostic and infrastructure-agnostic.

## Repository Structure

- `apps/` — Deployable applications (APIs, web apps, workers, services)
- `packages/` — Shared internal libraries and packages
- `tools/` — Developer scripts, generators, and utilities
- `infra/` — Infrastructure as Code (Docker, Kubernetes, Terraform)
- `docs/` — Documentation (ADRs, guides, release notes)
- `.github/` — GitHub Actions workflows, Copilot config, issue/PR templates
- `.azure/` — Azure DevOps pipeline definitions
- `.ai/` — AI assistant configuration (tasks, skills, instructions)

## Conventions

### Naming
- Use kebab-case for directory and file names
- Use Conventional Commits for commit messages: `<type>(<scope>): <description>`
- Scope should be the app or package name (e.g., `api`, `web`, `shared-utils`)

### Code Organization
- Each app in `apps/` is independently deployable and has its own build system
- Shared code goes in `packages/`; never duplicate logic across apps
- Infrastructure changes go in `infra/`, not in app directories
- Architecture decisions must be recorded as ADRs in `docs/adr/`

### Build & Run
- Use `make help` to see all available commands
- `make up` starts the local Docker development environment
- `make test` runs all tests across all apps
- `make lint` runs all linters

### Testing
- Every app should have unit tests
- Integration tests should run against Docker Compose services
- Tests must pass before merging any PR

### Documentation
- Update relevant docs when making changes
- New architectural decisions require an ADR (see `docs/adr/000-template.md`)
- API changes should be reflected in `docs/api/`

## AI Task Instructions

For more specific task instructions and skills, see:
- `.ai/claude/instructions.md` — Detailed Claude-specific instructions
- `.ai/claude/tasks/` — Reusable task definitions
- `.ai/claude/skills/` — Skill configurations
- `.ai/shared/coding-standards.md` — Coding standards for all AI assistants

## Important Notes

- Do NOT commit secrets, credentials, or `.env` files
- Always run `make check` (lint + test) before committing
- Prefer editing existing files over creating new ones to avoid duplication
- When adding a new app, follow the pattern in `apps/README.md`
- When adding a new package, follow the pattern in `packages/README.md`
