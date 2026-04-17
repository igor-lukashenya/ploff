# Coding Standards

This document defines coding standards that apply across all applications and packages
in this monorepo. These standards are shared with all AI assistants (Claude, Copilot)
and should be followed by all contributors.

## General Principles

1. **Readability over cleverness** — Code is read far more than it is written
2. **Consistency** — Follow the existing style in each app/package
3. **Simplicity** — Prefer the simplest solution that works correctly
4. **Testability** — Write code that is easy to test in isolation

## Naming Conventions

| Element | Convention | Example |
| --- | --- | --- |
| Directories | kebab-case | `user-service`, `shared-utils` |
| Files | kebab-case | `user-controller.ts`, `auth_middleware.py` |
| Environment variables | UPPER_SNAKE_CASE | `DATABASE_URL`, `API_PORT` |
| Git branches | `type/description` | `feature/user-auth`, `fix/login-bug` |

Language-specific naming (classes, functions, variables) should follow the idiomatic
conventions of each language.

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short description>

[optional body]

[optional footer(s)]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`

## Error Handling

- Always handle errors explicitly
- Never swallow exceptions silently
- Log errors with sufficient context for debugging
- Use structured logging where possible

## Security

- Never commit secrets, tokens, or credentials
- Use environment variables or secret managers for sensitive configuration
- Validate all external input (API requests, user input, file uploads)
- Keep dependencies up to date

## Testing

- Write tests for all business logic
- Unit tests should be fast and isolated (no external dependencies)
- Integration tests may use Docker Compose services
- Aim for meaningful coverage, not 100% coverage of trivial code

## Documentation

- Every app and package must have a README
- Complex logic should have inline comments explaining *why*, not *what*
- API endpoints should be documented
- Architectural decisions should be recorded as ADRs
