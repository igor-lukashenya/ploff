# 003. Monorepo Tooling: moon, Release Please and Generators

**Date**: 2026-09-26

**Status**: Accepted

**Deciders**: Igor Lukashenya

## Context

This repository is a **template**. Each client or solution gets its own repository created
from it; everything inside one repository belongs to that single solution. A typical solution
combines several kinds of projects, each with an **independent release cycle**:

- Web UIs (React)
- Mobile apps
- Microservices (.NET today, other stacks possible)
- Tools (CLIs, jobs, importers)
- Shared packages used by several of the above

The original setup ([ADR-001](001-monorepo-structure.md)) used a hand-written Makefile and
per-app CI jobs with `dorny/paths-filter`. Every new app required editing about eight files
(Makefile, CI, deploy workflows, Release Please workflow, compose, solution file, Dependabot),
path filters could not see that an app depends on a changed shared package, and there was no
way to bootstrap a new project type consistently.

Constraints:

- Must handle several languages equally, without making one ecosystem (e.g. Node.js) the
  center of the build
- CI/CD targets **GitHub Actions only** (Azure DevOps support was removed)
- Developer scripts are **Bash only** (Windows users work in WSL or the devcontainer)
- A new solution must be bootstrapped with only the project types its requirements need

## Decision

### 1. Orchestration: moon

We use [moon](https://moonrepo.dev) (v2) as the task runner and build orchestrator.

- Every project has a `moon.yml` declaring `language`, `layer`
  (`application` / `tool` / `library`), `stack`, `tags` and `dependsOn`.
- Standard tasks are defined **once per language** in `.moon/tasks/` and inherited by every
  project of that language:

  | Task | .NET (`dotnet.yml`) | Node/TS (`node.yml`) |
  | --- | --- | --- |
  | `build` | `dotnet build -c Release` | `npm run build` |
  | `test` | `dotnet test` | `npm test` |
  | `lint` | `dotnet format --verify-no-changes` | `npm run lint` |
  | `typecheck` | - | `npm run type-check` |
  | `format` | `dotnet format` | `npm run lint:fix` |
  | `publish` | per project, output in `dist/` | `build` (output in `dist/`) |
  | `dev` | per project | `npm run dev` |

- `build` depends on the builds of the project's dependencies (`^:build`), so
  `moon ci --include-relations --downstream deep` also rebuilds and retests every project
  that depends on a changed shared package.
- `constraints.enforceLayerRelationships` enforces that apps never depend on other apps.
- Tool versions are pinned in `.prototools` (moon, Node.js) and installed by proto; the .NET
  SDK is pinned by `global.json` because moon has no .NET toolchain plugin (.NET tasks call the
  system `dotnet`).
- The root `Makefile` stays as a thin, discoverable entry point (`make check`, `make ci`,
  `make run APP=… TASK=…`, `make new-app …`).

### 2. CI/CD: generic GitHub Actions workflows

- `ci.yml` runs `moon ci --include-relations --downstream deep` in a single job: only affected
  tasks run, and no per-app jobs exist.
- `deploy-dev.yml` deploys every affected project tagged `deployable`, computed with
  `moon query projects --affected --downstream deep` for the pushed commit range.
- `release-please.yml` deploys every app Release Please released, built from its
  `paths_released` output.
- `deploy-app.yml` is stack-agnostic: it runs `moon run <app>:test <app>:publish` and ships
  `apps/<app>/dist`.

**Adding an app requires no workflow changes.**

### 3. Releases: Release Please (unchanged)

[Release Please](https://github.com/googleapis/release-please) remains the versioning tool: one
release PR, changelog and `<app>/v<semver>` tag per app, driven by Conventional Commits scoped
to the app name. How releases are gated per environment is out of scope here and will be
recorded in a separate ADR.

### 4. Bootstrapping: generators

Project types are **moon templates** in `tools/generators/<stack>/`, invoked through
`make new-app STACK=<stack> NAME=<name>` / `make new-package …`
(`tools/scripts/new-project.sh`):

| Stack | Kind | Creates |
| --- | --- | --- |
| `dotnet-service` | app | ASP.NET Core Minimal API, tests, Dockerfile, compose fragment |
| `dotnet-console` | app (tool) | Console tool with testable entry point, tests |
| `dotnet-library` | package | Shared class library, tests |
| `react-web` | app | React 19 + Vite SPA, tests, nginx Dockerfile, compose fragment |

Templates only **create** new files. The wrapper script then registers the project in shared
files, with targeted edits: Release Please config and manifest, root `.slnx`, Dependabot, and
`npm ci` from the lockfile the template ships. (moon's generator overwrites existing files
instead of merging them, so shared files are never template outputs.)

Docker Compose is split into one `infra/docker/compose.<app>.yml` fragment per app; the
Makefile loads all fragments, so no shared compose file is edited either.

### 5. .NET project layout

Every .NET project uses `<Name>.slnx` + `src/<Name>/` + `tests/<Name>.Tests/`, so each
`dotnet` command in the project root resolves exactly one solution.

## Consequences

### Positive

- **Adding a project is one command**, with no hand edits to CI, deploy workflows or the
  Makefile.
- **Correct change detection**: a change in a shared package rebuilds, retests and redeploys
  exactly the dependent apps (the path filters it replaces could not do this).
- **One interface across stacks**: `make run APP=x TASK=test` works the same for .NET, React
  and future stacks.
- **Pinned toolchains**: the same moon and Node.js versions locally and in CI.
- **Local caching**: unchanged tasks are skipped (a remote cache can be added later).

### Negative

- **New tool to learn**: developers install proto once (`make setup` then installs moon and
  Node.js) and need basic `moon.yml` concepts.
- **No .NET toolchain in moon**: the .NET SDK is managed separately (`global.json` +
  `actions/setup-dotnet`), and .NET build outputs are not cached by moon.
- **Template maintenance**: generator templates (including the `react-web` lockfile) must be
  kept in sync with the sample apps and dependency updates. Dependabot only updates the sample
  apps; `make sync-templates` copies their versions into the templates, and CI warns on drift.
- **Pre-1.0 GitHub Actions**: `moonrepo/setup-toolchain` is on `v0`.
- **Package changes don't create app releases**: Release Please attributes commits to an app
  by path only (it has no option to watch dependency paths). A change only inside
  `packages/` is rebuilt, retested and deployed to dev for every dependent app, but a
  production release of a dependent app still needs a commit scoped to that app, e.g.
  `fix(orders): pick up shared-kernel fix`.

### Neutral

- Sample apps (`sample-api`, `sample-web`) remain as reference implementations of the
  `dotnet-service` and `react-web` stacks.
- Repositories created from the template don't receive template updates automatically; they
  are bootstrapped once and then evolve independently.

## Alternatives Considered

### Option A: Nx (+ Nx Release)

- Pros: Most complete feature set: inferred project graph (including a `.csproj`-aware .NET
  plugin), first-class React/React Native/Expo support, built-in independent releases that
  bump dependents.
- Cons: Requires Node.js at the root of every repository and a plugin per language; heavy for
  .NET-centric solutions; would reverse ADR-001's "no JS-ecosystem tool at the root".
- Revisit if solutions become predominantly TypeScript (React + React Native + Node services).

### Option B: Makefile + app manifests + path filters (status quo, improved)

- Pros: No new tool.
- Cons: Custom glue for everything moon provides (dependency graph, affected detection,
  task inheritance, caching, toolchain pinning); path filters can't see project dependencies.

### Option C: Bazel / Pants / Buck2

- Pros: Precise, hermetic builds and remote execution at very large scale.
- Cons: Very high setup and maintenance cost; far beyond the needs of a single-solution repo.

### Option D: Turborepo / Rush / Lerna

- Pros: Mature for JavaScript monorepos.
- Cons: JavaScript-only; unsuitable for .NET services and tools.

### Option E: Copier for templates (instead of moon generators)

- Pros: `copier update` can bring template improvements into existing repositories.
- Cons: Adds Python tooling. The current workflow bootstraps a solution once and lets it
  evolve independently, so the update path isn't needed yet. Templates are plain folders
  and can be migrated later if it is.

## Follow-ups

- Mobile generator, once the mobile stack is chosen (React Native/Expo, Flutter or native)
- TypeScript shared-library generator (for code shared between web and mobile)
- ~~CI job that generates each stack into a scratch workspace and runs its tasks~~ - done
  (`make test-generators`, CI job "generator self-test")
- ADR for release gating and environment promotion, including how package-only changes
  should trigger releases of dependent apps
