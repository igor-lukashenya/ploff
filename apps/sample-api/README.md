# Sample API

A minimal .NET API demonstrating the Project LiftOff monorepo pattern.

## What's Included

- Minimal API with health check endpoints
- Docker multi-stage build
- Integration tests using `WebApplicationFactory`
- Wired into root Makefile and Docker Compose

## Endpoints

| Method | Path | Description |
| --- | --- | --- |
| `GET /` | Root | Returns API info (name, version, status) |
| `GET /health` | Liveness | Always returns 200 if the process is running |
| `GET /health/ready` | Readiness | Returns 200 if all dependencies are healthy |

## Running Locally

```bash
# From this directory
dotnet run

# Or from repo root via Docker
make up
```

## Testing

```bash
# From this directory
dotnet test

# Or from repo root
make test
```

## Environment Variables

| Variable | Description | Default |
| --- | --- | --- |
| `ASPNETCORE_URLS` | Listen URL | `http://+:8080` |
| `ASPNETCORE_ENVIRONMENT` | Environment name | `Production` |

## Docker

```bash
# Build from repo root
docker build -f infra/docker/Dockerfile.sample-api -t sample-api:latest .

# Run
docker run -p 8080:8080 sample-api:latest
```
