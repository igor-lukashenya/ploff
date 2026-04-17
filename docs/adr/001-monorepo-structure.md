# 001. Monorepo Structure

**Date**: 2026-04-18

**Status**: Accepted

**Deciders**: Team

## Context

We need to decide how to organize our codebase. The project consists of multiple
applications (frontends, APIs, background workers), shared libraries, infrastructure
code, documentation, and CI/CD pipelines. We need a structure that:

- Supports multiple deployable applications
- Allows sharing code between applications
- Keeps infrastructure and documentation alongside application code
- Works with different CI/CD platforms (GitHub Actions, Azure DevOps)
- Supports different deployment targets (VPS, Kubernetes, Azure Cloud)
- Is language-agnostic and does not impose a specific tech stack

## Decision

We will use a **monorepo** structure with the following top-level directories:

| Directory | Purpose |
| --- | --- |
| `apps/` | Deployable applications |
| `packages/` | Shared internal libraries |
| `tools/` | Developer scripts and utilities |
| `infra/` | Infrastructure as Code |
| `docs/` | Documentation (ADRs, guides, release notes) |
| `.github/` | GitHub Actions and GitHub-specific configuration |
| `.azure/` | Azure DevOps pipeline definitions |
| `.ai/` | AI assistant instructions |

We will use `Makefile` as a universal, language-agnostic task runner for common commands
(build, test, lint, deploy).

## Consequences

### Positive

- **Atomic changes**: Cross-cutting changes (e.g., shared library + all consuming apps)
  can be made in a single commit/PR
- **Single source of truth**: All code, docs, and infrastructure live together
- **Shared tooling**: Linting, CI/CD, and formatting configured once at the root
- **Easier onboarding**: New developers clone one repo and have everything
- **Flexible**: No language-specific monorepo tool; each app uses its own build system

### Negative

- **Repository size**: Grows over time as all code lives together
- **CI complexity**: Need path-based filtering to avoid building everything on every change
- **Access control**: Fine-grained permissions are harder (mitigated by CODEOWNERS)

### Neutral

- Developers need to learn the monorepo conventions
- Some tooling (IDE, search) may need configuration for large repos

## Alternatives Considered

### Option A: Multi-repo (one repo per app)

- Pros: Clear boundaries, independent deployments, simpler CI per repo
- Cons: Sharing code requires publishing packages, cross-repo changes need coordination,
  infrastructure and docs scattered across repos

### Option B: Language-specific monorepo tool (Nx, Turborepo)

- Pros: Caching, task orchestration, dependency graph awareness
- Cons: Tied to Node.js/TypeScript ecosystem, adds complexity for non-JS apps,
  learning curve for the specific tool
