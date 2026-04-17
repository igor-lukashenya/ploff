# Applications

This directory contains all deployable applications in the monorepo.

## Structure

Each application should be in its own subdirectory:

```
apps/
├── api/               # Primary API service
├── api-admin/         # Admin API (example)
├── web/               # Frontend web application
├── worker/            # Background job processor
└── ...
```

## Adding a New Application

1. **Create the directory:**
   ```bash
   mkdir -p apps/<app-name>
   ```

2. **Initialize the project** using your language/framework's tooling:
   ```bash
   # Examples:
   cd apps/<app-name>
   npm init                    # Node.js
   dotnet new webapi           # .NET
   django-admin startproject   # Python/Django
   go mod init                 # Go
   ```

3. **Add a README.md** with:
   - What the app does
   - How to install dependencies
   - How to run it locally
   - How to run tests
   - Environment variables it needs

4. **Add a Dockerfile** (in `infra/docker/Dockerfile.<app-name>` or within the app):
   ```dockerfile
   # infra/docker/Dockerfile.<app-name>
   FROM <base-image>
   WORKDIR /app
   COPY apps/<app-name>/ .
   # ... build and run steps
   ```

5. **Add to docker-compose** (`infra/docker/docker-compose.yml`):
   ```yaml
   services:
     <app-name>:
       build:
         context: ../../
         dockerfile: infra/docker/Dockerfile.<app-name>
       ports:
         - "<host-port>:<container-port>"
   ```

6. **Add Makefile targets** in the root `Makefile`:
   ```makefile
   .PHONY: build-<app-name>
   build-<app-name>: ## Build <app-name>
       cd apps/<app-name> && <build-command>
   ```

7. **Add tests** following the [Testing Strategy](../docs/guides/testing.md):
   - Unit tests for business logic
   - Integration tests for database/API boundaries
   - Wire test commands into `make test`

8. **Add CI/CD configuration** if the app should be built/deployed independently.

## Conventions

- Each app is **independently deployable**
- Apps can depend on code in `packages/` but **never on other apps**
- Each app manages its own dependencies
- Shared code belongs in `packages/`, not duplicated across apps
- Environment-specific configuration uses environment variables (see `.env.example`)
