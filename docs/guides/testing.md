# Testing Strategy

This guide defines the testing approach for all applications and packages in the monorepo.

## Test Pyramid

We follow the **test pyramid** model. Most tests should be fast unit tests; fewer
integration tests; minimal end-to-end tests.

```
        ╱  E2E  ╲           Few — slow, expensive, high confidence
       ╱─────────╲
      ╱Integration╲         Some — test boundaries and contracts
     ╱─────────────╲
    ╱   Unit Tests   ╲      Many — fast, isolated, cheap
   ╱───────────────────╲
```

| Level | Scope | Speed | Dependencies | Where |
| --- | --- | --- | --- | --- |
| **Unit** | Single function/class | < 1 sec | None (mocked) | `apps/<app>/tests/unit/` |
| **Integration** | Service boundaries, DB, APIs | Seconds | Docker Compose | `apps/<app>/tests/integration/` |
| **E2E** | Full user flows | Minutes | Full stack | `apps/<app>/tests/e2e/` or `tests/e2e/` |
| **Contract** | API contracts between services | < 1 sec | None | `apps/<app>/tests/contract/` |

## Directory Structure

Each app and package organizes tests alongside or within its source code.

### Option A: Separate `tests/` directory (recommended for most languages)

```
apps/api/
├── src/
│   └── ...
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
└── ...
```

### Option B: Co-located tests (common in JS/TS, Go, Rust)

```
apps/api/
├── src/
│   ├── users/
│   │   ├── user.service.ts
│   │   └── user.service.test.ts
│   └── ...
└── ...
```

Choose one pattern per app and be consistent within it.

## Test Naming

Use descriptive names that express intent:

```
# Pattern: <what>_<condition>_<expected result>
test_user_creation_with_valid_data_returns_created
test_login_with_wrong_password_returns_unauthorized

# Or describe-style:
describe("UserService")
  it("creates a user with valid data")
  it("returns error when email already exists")
```

## Running Tests

```bash
# Run all tests across all apps
make test

# Run only unit tests
make test-unit

# Run only integration tests (requires Docker services)
make test-integration

# Run tests for a specific app
cd apps/<app-name> && <test-command>
```

## Unit Tests

**Goal**: Verify individual functions, methods, and classes in isolation.

**Guidelines**:
- No external dependencies (no database, no network, no filesystem)
- Mock/stub all dependencies
- Fast — the entire unit test suite should run in seconds
- Each test should be independent and idempotent
- Follow the **Arrange-Act-Assert** (AAA) pattern:

```
// Arrange — set up test data and mocks
// Act — call the function under test
// Assert — verify the result
```

## Integration Tests

**Goal**: Verify that components work correctly together (database queries, API calls, message queues).

**Guidelines**:
- Use Docker Compose for external dependencies (databases, caches, queues)
- Each test should set up and tear down its own data
- Can be slower than unit tests but should still be reasonably fast
- Focus on boundaries: repository implementations, HTTP clients, message handlers

**Running dependencies for integration tests**:

```bash
# Start only the infrastructure services (DB, Redis, etc.)
docker compose -f infra/docker/docker-compose.yml up -d db redis

# Run integration tests
make test-integration

# Tear down
docker compose -f infra/docker/docker-compose.yml down
```

## End-to-End (E2E) Tests

**Goal**: Verify complete user flows across the full stack.

**Guidelines**:
- Keep the number of E2E tests small — they're slow and brittle
- Test critical happy paths and key error scenarios
- Run against a fully deployed (or Docker Compose) environment
- Can live in a specific app or in a top-level `tests/e2e/` directory for cross-app flows

## Contract Tests

**Goal**: Ensure API contracts between services remain compatible.

Useful when you have multiple apps that communicate (e.g., `api` and `web`, or `api` and `api-admin`). Contract tests verify that the producer's API matches what the consumer expects.

## Shared Package Tests

Packages in `packages/` should have comprehensive unit tests because multiple apps depend on them. A breaking change in a package affects all consumers.

```bash
cd packages/<package-name> && <test-command>
```

## Test Configuration

### Environment Variables

Tests should use dedicated environment variables or `.env.test` files:

```bash
# .env.test (not committed — add to .gitignore)
DATABASE_URL=postgres://postgres:postgres@localhost:5432/app_test
REDIS_URL=redis://localhost:6379/1
```

### CI Integration

Tests run automatically in CI pipelines:

- **GitHub Actions**: `.github/workflows/ci.yml` — lint + test on every PR
- **Azure DevOps**: `.azure/pipelines/ci.yml` — lint + test stages

Test results should be published in CI using JUnit XML format (supported by both platforms).

## Coverage

- Aim for meaningful coverage, not 100%
- Cover business logic thoroughly
- Don't test trivial getters/setters or framework boilerplate
- Configure coverage thresholds per app if needed

## What NOT to Test

- Framework internals (trust your framework)
- Third-party library behavior
- Trivial code (simple getters, data classes)
- Implementation details — test behavior, not internal state
