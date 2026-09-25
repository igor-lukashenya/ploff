# Ploff

Instructions for AI coding agents working in this repository. Tool-specific entry
points (`CLAUDE.md`, `.github/copilot-instructions.md`) build on this file.

## Project Info
- Tasks: TODO - link your issue tracker / project board

## Repos
| Module | Path | Tech |
|--------|------|------|
| sample-api | `apps/sample-api` | .NET 10 Minimal API |
| sample-api-tests | `apps/sample-api/tests/SampleApi.Tests` | xUnit |
| sample-web | `apps/sample-web` | React 19 + Vite 8 + TypeScript |
| infra-docker | `infra/docker` | Docker Compose |
| infra-terraform | `infra/terraform` | Terraform |

## Architecture
- Backend pattern: Minimal API (.NET 10) - load skill `service-layer-dotnet` when adding services
- Frontend pattern: React 19 (feature-based structure) - load skill `react-ui`
- Testing: xUnit + integration tests (.NET), Vitest + Testing Library (React) - load skill `dotnet-testing`
- No database yet - add when needed

## Conventions
- Use Conventional Commits: `<type>(<scope>): <description>`
- Use kebab-case for directory and file names
- Each app in `apps/` is independently deployable and versioned
- Shared code goes in `packages/` - never duplicate across apps
- Infrastructure changes go in `infra/`, not in app directories
- Architecture decisions recorded as ADRs in `docs/adr/`
- Run `make check` (lint + test) before committing
- Do NOT commit secrets, credentials, or `.env` files
- React features follow collocated structure: components/, hooks/, services/, types/
- Use TanStack Query for server state, React Router for navigation
