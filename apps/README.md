# Applications

This directory contains all deployable applications and tools in the monorepo.

## Structure

Each application is in its own subdirectory and is a [moon](https://moonrepo.dev) project
(it has a `moon.yml`):

```
apps/
├── sample-api/        # .NET Minimal API (reference for the dotnet-service stack)
├── sample-web/        # React + Vite SPA (reference for the react-web stack)
└── ...
```

The sample apps are removed when a new solution is initialized (`init-project.sh`, or
`make remove-samples` later); the generators don't depend on them.

## Adding a New Application

Scaffold it from a generator:

```bash
make stacks                                      # List available stacks
make new-app STACK=dotnet-service NAME=orders    # .NET API / microservice
make new-app STACK=react-web NAME=portal         # React web app
make new-app STACK=dotnet-console NAME=importer  # CLI tool / job
```

The generator creates a working app (source, tests, `README.md`, `moon.yml`) and, for
services and web apps, `infra/docker/Dockerfile.<name>` plus a compose fragment
`infra/docker/compose.<name>.yml`. It then registers the app in:

- `release-please-config.json` / `.release-please-manifest.json` (independent versioning)
- the root `.slnx` (.NET apps)
- `.github/dependabot.yml`

**No CI/CD changes are needed**: CI runs the app's tasks when it's affected, and apps
tagged `deployable` in `moon.yml` are deployed by the existing workflows.

After generating:

1. Verify: `make run APP=<name> TASK=test`
2. Describe the app in its `README.md` and `moon.yml` (`project.description`)
3. If it uses shared packages, add them to `dependsOn` in `moon.yml` (see
   [packages/README.md](../packages/README.md))
4. Commit with the app scope: `feat(<name>): initial scaffold`

### Stacks without a generator

For a stack without a generator yet, create the app manually and follow the same contract:

1. A `moon.yml` with `language`, `layer`, `stack` and `tags` (add `deployable` if it
   should be deployed)
2. The standard tasks `build`, `test`, `lint`, `format`, `publish` (artifact in `dist/`),
   and `dev`: inherited from `.moon/tasks/<language>.yml`, or defined in `moon.yml`
3. A Dockerfile and compose fragment in `infra/docker/` if it runs as a container
4. An entry in `release-please-config.json` and `.release-please-manifest.json`

Then consider turning it into a generator in `tools/generators/`.

## Conventions

- Each app is **independently deployable and versioned** (Release Please, tag `<app>/vX.Y.Z`)
- Apps can depend on code in `packages/` but **never on other apps** (enforced by moon)
- Each app manages its own dependencies
- Shared code belongs in `packages/`, not duplicated across apps
- Environment-specific configuration uses environment variables (see `.env.example`)
- .NET apps use `<Name>.slnx` + `src/<Name>/` + `tests/<Name>.Tests/`
