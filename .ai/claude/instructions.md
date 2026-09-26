# Claude Code — Detailed Instructions

This file contains detailed instructions for Claude Code when working in this repository.

## Working With This Monorepo

### Adding a New Application

1. Pick a stack: `make stacks`
2. Generate it: `make new-app STACK=<stack> NAME=<app-name>` - this creates the app, its
   Dockerfile and compose fragment, and registers it in Release Please, the root `.slnx`
   and Dependabot
3. Verify: `make run APP=<app-name> TASK=test`
4. Fill in the app's `README.md` and `moon.yml` description
5. Do NOT add per-app CI jobs or Makefile targets - the workflows and Makefile are generic

If no generator exists for the stack, follow "Stacks without a generator" in `apps/README.md`.

### Adding a Shared Package

1. Generate it: `make new-package STACK=<stack> NAME=<package-name>`
2. Reference it from consuming apps (e.g. `ProjectReference`) AND add it to their
   `moon.yml` `dependsOn` so CI and deploys track the dependency
3. Add tests

### Making Infrastructure Changes

1. Docker changes go in `infra/docker/`
2. Kubernetes manifests in `infra/kubernetes/`
3. Terraform modules in `infra/terraform/modules/`
4. Environment-specific config in `infra/terraform/environments/<env>/`
5. Always test infrastructure changes in `dev` before `staging` or `production`

### Writing Documentation

- ADRs: Copy `docs/adr/000-template.md`, number sequentially
- Guides: Add to `docs/guides/`
- API docs: Add to `docs/api/`
- Release notes: Add to `docs/release-notes/releases/`

## Error Handling

- Check existing tests to understand expected behavior before making changes
- Run `make test` after changes to verify nothing breaks
- If tests fail, investigate the failure before making further changes

## Preferred Patterns

- Prefer composition over inheritance
- Keep functions/methods small and focused
- Use meaningful names over comments
- Handle errors explicitly, don't swallow exceptions
- Log at appropriate levels (debug, info, warn, error)
