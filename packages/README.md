# Shared Packages

This directory contains internal libraries shared between applications in `apps/`.
Packages are consumed directly from source — they are not published to a registry.

## Structure

Each package should be in its own subdirectory:

```
packages/
├── shared-models/     # Domain models, DTOs
├── shared-utils/      # Utility functions
├── shared-config/     # Shared configuration schemas
└── ...
```

## Adding a New Package

1. **Scaffold the package** from a generator:
   ```bash
   make new-package STACK=dotnet-library NAME=<package-name>
   ```
   For stacks without a generator (`make stacks`), create the package manually with a
   `moon.yml` (`layer: 'library'`) and the standard tasks (see [apps/README.md](../apps/README.md)).

2. **Declare the dependency** in each consuming app's `moon.yml`:
   ```yaml
   dependsOn:
     - '<package-name>'
   ```
   This is what makes CI rebuild, retest and redeploy the app when the package changes.

3. **Reference it from consuming apps** (varies by ecosystem):
   - **.NET**: `<ProjectReference Include="..\..\..\..\packages\<package-name>\src\<Name>\<Name>.csproj" />`
     from the app's `src/<Name>/<Name>.csproj` (the generator adds the package to the root `.slnx`)
   - **Node.js**: `"<package-name>": "file:../../packages/<package-name>"` in `package.json`
   - **Python**: path dependency in `pyproject.toml`
   - **Go**: `replace` directive in `go.mod` or a root `go.work`

4. **Copy the package into Docker builds** of consuming apps (`infra/docker/Dockerfile.<app>`).

5. **Add tests** following the [Testing Strategy](../docs/guides/testing.md).

## Conventions

- Packages can depend on other packages but **never on apps** (enforced by moon)
- Packages are not released on their own - they ship inside the apps that use them. A
  package change is deployed to dev for every dependent app automatically, but a production
  release of an app needs a commit scoped to it (e.g. `fix(orders): pick up shared-kernel fix`)
  because Release Please only looks at the app's own path
- Keep packages focused — one clear responsibility per package
- Every package has a `README.md` documenting its public API
- Breaking changes to a package must update all consuming apps in the same PR
