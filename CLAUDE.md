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
- `tools/` — Developer scripts and project generators (moon templates)
- `infra/` — Infrastructure as Code (Docker, Kubernetes, Terraform)
- `docs/` — Documentation (ADRs, guides, release notes)
- `.github/` — GitHub Actions workflows, Copilot config, issue/PR templates
- `.moon/` — moon workspace, toolchains and shared per-language tasks
- `.ai/` — Shared AI assistant instructions and coding standards
- `.claude/` — Claude Code project skills and settings

## Conventions

### Naming
- Use kebab-case for directory and file names
- Use Conventional Commits for commit messages: `<type>(<scope>): <description>`
- Scope should be the app or package name (e.g., `api`, `web`, `shared-utils`)

### Code Organization
- Each app in `apps/` is independently deployable and versioned, and is a moon project (`moon.yml`)
- Apps may depend on `packages/`, never on other apps; declare dependencies in `dependsOn`
- Shared code goes in `packages/`; never duplicate logic across apps
- Infrastructure changes go in `infra/`, not in app directories
- Architecture decisions must be recorded as ADRs in `docs/adr/`

### Build & Run
- Tasks are orchestrated by moon (see `docs/adr/003-monorepo-tooling.md`); `make help` lists commands
- `make check` lints, type-checks and tests everything; `make ci` runs only affected tasks (like CI)
- `make run APP=<project> TASK=<task>` runs one task (`build`, `test`, `lint`, `typecheck`, `format`, `publish`, `dev`)
- `make up` starts the local Docker development environment
- New apps/packages: `make new-app STACK=<stack> NAME=<name>` / `make new-package ...` (`make stacks` lists stacks) - never hand-roll CI or Makefile entries
- CI/CD is GitHub Actions only; scripts are Bash only

### Testing
- Every app should have unit tests
- Integration tests should run against Docker Compose services
- Tests must pass before merging any PR

### Documentation
- Update relevant docs when making changes
- New architectural decisions require an ADR (see `docs/adr/000-template.md`)
- API changes should be reflected in `docs/api/`

## AI Task Instructions

The following files are imported into this context automatically:

- Project structure and conventions: @AGENTS.md
- Detailed Claude-specific instructions: @.ai/claude/instructions.md
- Coding standards for all AI assistants: @.ai/shared/coding-standards.md

Project skills live in `.claude/skills/<skill-name>/SKILL.md`.

## Important Notes

- Do NOT commit secrets, credentials, or `.env` files
- Always run `make check` (lint + test) before committing
- Prefer editing existing files over creating new ones to avoid duplication
- When adding a new app, follow the pattern in `apps/README.md`
- When adding a new package, follow the pattern in `packages/README.md`
