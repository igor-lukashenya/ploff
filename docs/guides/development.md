# Development Guide

Day-to-day development workflows for working in this monorepo.

## Branching

```bash
# Create a feature branch
git checkout -b feature/my-feature main

# Create a bug fix branch
git checkout -b fix/the-bug main
```

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the full branching strategy.

## Working on an App

```bash
# Navigate to the app
cd apps/<app-name>

# Follow the app's README for specific setup/run instructions

# Run the whole stack locally
make up

# Run just this app's tests
cd apps/<app-name> && <test-command>

# Run all tests
make test
```

## Working on a Shared Package

When modifying code in `packages/`, remember:
- Changes affect all consuming apps
- Run tests for all consuming apps, not just the package
- Consider backward compatibility

## Environment Variables

- Copy `.env.example` to `.env` for local development
- Never commit `.env` files (they're in `.gitignore`)
- Document all required environment variables in the app's README

## Code Review

1. Push your branch and open a Pull Request
2. Fill in the PR template
3. Wait for CI to pass
4. Request review from the appropriate code owners
5. Address feedback and merge

## Debugging

```bash
# View Docker logs for a specific service
docker compose -f infra/docker/docker-compose.yml logs -f <service-name>

# Shell into a running container
docker compose -f infra/docker/docker-compose.yml exec <service-name> sh

# Check container status
make ps
```

## Adding an ADR

When making a significant architectural decision:

1. Copy the template: `cp docs/adr/000-template.md docs/adr/NNN-short-title.md`
2. Fill in the sections
3. Include the ADR in your PR
