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

1. **Scaffold the package:**
   ```bash
   make new-package NAME=<package-name>
   ```

2. **Initialize the project** using your language/framework's tooling:
   ```bash
   # Examples:
   cd packages/<package-name>
   dotnet new classlib         # .NET
   npm init                    # Node.js / TypeScript
   uv init --lib               # Python
   go mod init                 # Go
   ```

3. **Reference it from consuming apps** (varies by ecosystem):
   - **.NET**: `<ProjectReference Include="../../packages/<package-name>/..." />`, and add
     the project to the root `.slnx`
   - **Node.js**: `"<package-name>": "file:../../packages/<package-name>"` in `package.json`
   - **Python**: path dependency in `pyproject.toml`
   - **Go**: `replace` directive in `go.mod` or a root `go.work`

4. **Add tests** following the [Testing Strategy](../docs/guides/testing.md).

5. **Update CI path filters** so that apps depending on the package are rebuilt when it
   changes (see `.github/workflows/ci.yml`).

## Conventions

- Packages can depend on other packages but **never on apps**
- Keep packages focused — one clear responsibility per package
- Every package has a `README.md` documenting its public API
- Breaking changes to a package must update all consuming apps in the same PR
