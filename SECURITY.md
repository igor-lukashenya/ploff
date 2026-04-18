# Security Policy

## Reporting a Vulnerability

> **TODO**: Replace contact details with your actual security contact.

If you discover a security vulnerability in this project, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead:

1. **Email**: Send details to `security@example.com`
2. **GitHub Security Advisories**: Use the [Security tab](../../security/advisories) to report privately (if enabled)

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Affected app(s) or package(s)
- Potential impact
- Suggested fix (if any)

### Response Timeline

| Action | Timeframe |
| --- | --- |
| Acknowledgment | Within 48 hours |
| Initial assessment | Within 5 business days |
| Fix or mitigation | Depends on severity |
| Public disclosure | After fix is deployed |

## Supported Versions

| Version | Supported |
| --- | --- |
| Latest (`main`) | ✅ |
| Previous releases | Best effort |

## Security Best Practices

All contributors should follow these practices:

- **Never commit secrets** — Use environment variables and secret managers
- **Keep dependencies updated** — Dependabot/Renovate PRs should be reviewed promptly
- **Validate all input** — Never trust external data (API requests, file uploads, user input)
- **Use HTTPS everywhere** — No plain HTTP in production
- **Principle of least privilege** — Services and users get only the permissions they need
- **Audit logging** — Log security-relevant events (auth, access control, config changes)

## Dependency Management

This repository uses automated dependency updates. Security patches should be reviewed and merged promptly.

See `.github/dependabot.yml` for configuration.
