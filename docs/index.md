# Project Name

> **TODO**: Replace with your project's overview.

Welcome to the **Project Name** documentation. This monorepo contains all applications,
shared packages, infrastructure code, and documentation.

## Quick Start

```bash
git clone <repo-url>
cd <project-name>
make setup   # install dependencies
make up      # start local environment
make help    # see all commands
```

## Documentation

<div class="grid cards" markdown>

-   :material-rocket-launch:{ .lg .middle } **Getting Started**

    ---

    Set up your development environment and run the project locally.

    [:octicons-arrow-right-24: Getting Started](guides/getting-started.md)

-   :material-code-braces:{ .lg .middle } **Development**

    ---

    Day-to-day workflows, branching, code review, and debugging.

    [:octicons-arrow-right-24: Development Guide](guides/development.md)

-   :material-test-tube:{ .lg .middle } **Testing**

    ---

    Testing strategy, conventions, and how to run tests.

    [:octicons-arrow-right-24: Testing Strategy](guides/testing.md)

-   :material-cloud-upload:{ .lg .middle } **Deployment**

    ---

    Deploy to VPS, Kubernetes, or Azure Cloud.

    [:octicons-arrow-right-24: Deployment Guide](guides/deployment.md)

-   :material-chart-line:{ .lg .middle } **Observability**

    ---

    Logging, health checks, metrics, and distributed tracing.

    [:octicons-arrow-right-24: Observability Guide](guides/observability.md)

-   :material-source-branch:{ .lg .middle } **Architecture Decisions**

    ---

    Records of significant technical decisions and their context.

    [:octicons-arrow-right-24: ADRs](adr/index.md)

</div>

## Repository Structure

```
apps/           → Deployable applications (APIs, web apps, workers)
packages/       → Shared internal libraries
tools/          → Developer scripts and generators
infra/          → Infrastructure as Code (Docker, K8s, Terraform)
docs/           → Documentation (you are here)
```
