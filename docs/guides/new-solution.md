# Starting a New Solution

This template is the starting point for a **new solution**: one repository per client or
product, containing all of that solution's apps (web, mobile, services, tools) and shared
packages. This guide goes from an empty GitHub repository to the first released app.

!!! note "Template repository"
    The template repository itself must have **Settings → General → Template repository**
    enabled so that GitHub shows the **Use this template** button.

## 1. Create the Repository

1. On the template repository, click **Use this template → Create a new repository**.
2. Choose the owner (usually the client's organization) and the repository name. For client
   work, make it **private**.
3. Clone it:

    ```bash
    git clone git@github.com:<owner>/<repo>.git
    cd <repo>
    ```

## 2. Initialize the Solution

```bash
bash tools/scripts/init-project.sh
```

The script asks for:

| Prompt | Used for |
| --- | --- |
| Display name | Titles in README, docs, UI (replaces "Ploff") |
| Slug | Kebab-case name for Compose/Kubernetes names and URLs (replaces "ploff") |
| Copyright holder | `LICENSE` |
| Remove sample apps? | **Yes** for most solutions. The generators don't need the samples. Keep them only as a starting point you will adapt; their versions are then reset to 0.1.0 |

It also resets the changelog and can reset the git history (not needed for repositories
created with **Use this template**, which start with a single commit). At the end it prints
the GitHub settings checklist below, with links for your repository.

Commit the result:

```bash
git add -A
git commit -m "chore: initialize solution"
git push
```

## 3. Install the Toolchain

Once per machine:

1. Install the [.NET SDK](https://dotnet.microsoft.com/download) (version in `global.json`),
   Docker, Git and Make. On Windows, work in WSL or the devcontainer.
2. Install [proto](https://moonrepo.dev/proto) and **open a new terminal** afterwards:

    ```bash
    curl -fsSL https://moonrepo.dev/install/proto.sh | bash
    ```

Then, in the repository:

```bash
make setup              # moon + Node.js from .prototools, git hooks
make install-scanners   # gitleaks + trivy for the pre-commit hook and `make scan`
```

The devcontainer does all of this automatically.

## 4. Configure GitHub

These settings can't live in the repository, so set them once for every new solution:

| # | Setting | Where | Why |
| --- | --- | --- | --- |
| 1 | **Allow GitHub Actions to create and approve pull requests** | Settings → Actions → General → Workflow permissions | Release Please opens release PRs |
| 2 | **Pages source: GitHub Actions** | Settings → Pages | Documentation site |
| 3 | **`RELEASE_PLEASE_TOKEN` secret** | Settings → Secrets and variables → Actions | Release PRs get CI runs ([how to create it](release-process.md#setup)) |
| 4 | **Branch rule for `main`**: require `CI Gate` and `Conventional Commits`, require a PR | Settings → Rules (or Branches) | Nothing reaches `main` without passing checks |
| 5 | `ENABLE_CODEQL` variable = `true` | Settings → Secrets and variables → Actions → Variables | Only for **private** repositories with GitHub Code Security ([details](security.md#codeql-in-private-repositories)) |

Optional: add CODEOWNERS entries (`.github/CODEOWNERS`) and enable Dependabot security
updates (Settings → Code security).

## 5. Create the Solution's Projects

List the available stacks and generate what the requirements need:

```bash
make stacks
make new-app STACK=dotnet-service NAME=orders          # API / microservice
make new-app STACK=react-web NAME=portal               # web frontend
make new-app STACK=dotnet-console NAME=importer        # tool / job
make new-package STACK=dotnet-library NAME=shared-kernel
make check
```

Each generator creates a working project with tests, and registers it for CI, releases,
Docker Compose and Dependabot; see `apps/README.md` in the repository for details. Stacks without a generator are added manually following the same contract.

Commit each project with its scope, for example `feat(orders): initial scaffold`.

## 6. Verify the Pipeline

After pushing to `main`:

- [ ] **CI** is green (moon runs the new projects' build, lint and tests)
- [ ] **Deploy Dev** ran for the deployable apps (the deploy step is a placeholder until a
      deploy target is chosen)
- [ ] **Release Please** opened a release PR per app (0.1.x) with CI checks on it
- [ ] The **documentation site** is published (Settings → Pages shows the URL)

Merging a release PR tags `<app>/v<version>`, creates a GitHub Release and triggers the
production deployment workflow. See the [Release Process](release-process.md).

## Next Steps

- [Development Guide](development.md): day-to-day workflow
- [Release Process](release-process.md): versions, release PRs and hotfixes
- [Security Guide](security.md): what the security checks do and how to handle findings
- [ADR-003](../adr/003-monorepo-tooling.md): why the repository is organized this way
