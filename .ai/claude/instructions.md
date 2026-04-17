# Claude Code — Detailed Instructions

This file contains detailed instructions for Claude Code when working in this repository.

## Working With This Monorepo

### Adding a New Application

1. Create a new directory under `apps/<app-name>/`
2. Add a `README.md` with setup and run instructions
3. Add a `Dockerfile` in `infra/docker/Dockerfile.<app-name>`
4. Add the service to `infra/docker/docker-compose.yml`
5. Add build/test/lint targets to the root `Makefile`
6. Add CI/CD pipeline configuration if needed

### Adding a Shared Package

1. Create a new directory under `packages/<package-name>/`
2. Add a `README.md` explaining the package's purpose
3. Configure it so apps can import from it (varies by language/ecosystem)
4. Add tests

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
