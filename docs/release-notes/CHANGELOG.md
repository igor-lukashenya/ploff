# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

Solution-level release notes. Each app's changes are recorded in its own
`apps/<app>/CHANGELOG.md`, maintained by Release Please:

| App | Latest release | Changelog |
| --- | --- | --- |
| sample-api | 0.1.1 (2026-09-26) | `apps/sample-api/CHANGELOG.md` |
| sample-web | 0.1.2 (2026-09-26) | `apps/sample-web/CHANGELOG.md` |

## [0.1.0] - 2026-10-04

First baseline of the template.

### Added
- Monorepo structure: `apps/`, `packages/`, `tools/`, `infra/`, `docs/`
- Sample apps: `sample-api` (.NET 10 Minimal API, xUnit) and `sample-web`
  (React 19 + Vite + TypeScript, Vitest)
- Task orchestration with moon and pinned toolchains via proto (ADR-003);
  `Makefile` as the entry point for common commands
  (`make install-proto`, `make setup`)
- Project generators (`make new-app` / `make new-package`) for the `dotnet-service`,
  `dotnet-console`, `dotnet-library` and `react-web` stacks, with a CI self-test
- New solution bootstrap (`tools/scripts/init-project.sh`) and sample removal script
- GitHub Actions: affected-only CI, deploys to dev and staging, Docs (GitHub Pages)
  and Conventional Commits check for pull requests
- Per-app versioning, changelogs and GitHub Releases with Release Please
- Security scanning: secrets, vulnerabilities and CodeQL, with git hooks (ADR-004)
- Dependabot update policy for app dependencies, Docker images, Terraform
  and GitHub Actions
- Infrastructure scaffolding: Docker Compose per app, Kubernetes (Kustomize), Terraform
- `.devcontainer` for VS Code / GitHub Codespaces and `.env.example`
- Documentation site (MkDocs Material): ADRs 001–004, guides (getting started,
  new solution, development, testing, deployment, observability, release process,
  git hooks, security) and investigations
- AI assistant configuration for Claude Code and GitHub Copilot
- SECURITY.md, CODE_OF_CONDUCT.md and CONTRIBUTING.md

### Changed
- `sample-api` adopts the standard .NET layout (`src/` + `tests/`)
- Containers run as non-root users; Docker builds are reproducible
- GitHub Actions are pinned to commit SHAs
- .NET builds fail on high and critical vulnerable packages

### Removed
- Azure DevOps pipelines - CI/CD is GitHub Actions only
- Per-app CI jobs - replaced by generic moon-based workflows

<!-- ## [Unreleased] -->
<!-- ### Added -->
<!-- ### Changed -->
<!-- ### Deprecated -->
<!-- ### Removed -->
<!-- ### Fixed -->
<!-- ### Security -->
