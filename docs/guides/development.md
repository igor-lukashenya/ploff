# Development Guide

Day-to-day development workflows for working in this monorepo.

## Branching

```bash
# Create a feature branch
git checkout -b feature/my-feature main

# Create a bug fix branch
git checkout -b fix/the-bug main
```

See [CONTRIBUTING.md](https://github.com) for the full branching strategy.

## Working on an App

Every project (app or package) is a [moon](https://moonrepo.dev) project with the same task
names, whatever its stack: `build`, `test`, `lint`, `typecheck` (TypeScript), `format`,
`publish` and `dev`.

```bash
# Run the app's dev server
make dev APP=<app-name>

# Run one task of one app
make run APP=<app-name> TASK=test

# Run everything affected by your changes (the same check CI runs)
make ci

# Run the whole stack in Docker
make up
```

moon caches task results: re-running a task whose inputs didn't change is instant. Use
`moon run <app>:<task> --force` to bypass the cache.

## Working on a Shared Package

When modifying code in `packages/`, remember:
- Changes affect all consuming apps: every app that lists the package in its `moon.yml`
  `dependsOn` is rebuilt and retested by `make ci` and in CI, and redeployed to dev
- Consider backward compatibility
- `make graph` shows which projects depend on which

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
# View Docker logs for all services
make logs

# Inspect a project's resolved configuration and tasks
moon project <app-name>
moon task <app-name>:build

# Check container status
make ps
```

## Adding an ADR

When making a significant architectural decision:

1. Create it from the template: `make new-adr NAME=short-title`
2. Fill in the sections
3. Include the ADR in your PR
