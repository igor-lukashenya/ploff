# ============================================================================
# Makefile - Entry point for common commands
# ============================================================================
#
# Build, test, and lint tasks are orchestrated by moon (https://moonrepo.dev),
# which knows every project in apps/ and packages/ and only runs what is needed.
# This Makefile is a thin, discoverable wrapper - see docs/adr/003-monorepo-tooling.md.
#
# Usage:
#   make help                       Show all available commands
#   make setup                      Install toolchains and dependencies
#   make check                      Lint + typecheck + test everything
#   make run APP=sample-api TASK=dev   Run any task of one project
#   make new-app STACK=dotnet-service NAME=orders
#
# ============================================================================

.DEFAULT_GOAL := help

# ---- Variables ----

PROJECT_NAME ?= ploff
# Base file (shared infra) + one compose.<app>.yml fragment per app
COMPOSE_FILES := infra/docker/docker-compose.yml $(sort $(wildcard infra/docker/compose.*.yml))
DOCKER_COMPOSE := docker compose $(addprefix -f ,$(COMPOSE_FILES)) -p $(PROJECT_NAME)
MOON := moon

# Colors for terminal output
BLUE   := \033[36m
GREEN  := \033[32m
YELLOW := \033[33m
RED    := \033[31m
RESET  := \033[0m

# ---- Help ----

.PHONY: help
help: ## Show this help message
	@echo ""
	@echo "$(BLUE)$(PROJECT_NAME)$(RESET) - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ---- Setup ----

.PHONY: setup
setup: ## Install pinned toolchains (.prototools) and project dependencies
	@command -v proto >/dev/null 2>&1 || { \
		echo "$(RED)proto is not installed.$(RESET) Install it, then re-run 'make setup':"; \
		echo "  curl -fsSL https://moonrepo.dev/install/proto.sh | bash"; \
		echo "See docs/guides/getting-started.md"; exit 1; }
	proto install
	$(MOON) setup
	$(MOON) sync
	$(MOON) sync hooks
	@command -v gitleaks >/dev/null 2>&1 || echo "$(YELLOW)Tip: run 'make install-scanners' to enable the secret-scanning pre-commit hook.$(RESET)"
	@echo "$(GREEN)Toolchains ready. Run 'make check' to verify.$(RESET)"

# ---- Build / Test / Lint (all projects) ----

.PHONY: build
build: ## Build all projects
	$(MOON) run :build

.PHONY: test
test: ## Run all tests
	$(MOON) run :test

.PHONY: lint
lint: ## Run all linters
	$(MOON) run :lint

.PHONY: typecheck
typecheck: ## Type-check all projects that support it
	$(MOON) run :typecheck

.PHONY: format
format: ## Apply formatting fixes in all projects
	$(MOON) run :format

.PHONY: check
check: ## Lint, type-check and test all projects (run before committing)
	$(MOON) run :lint :typecheck :test

.PHONY: ci
ci: ## Run only tasks affected by your changes, incl. dependents (same as CI)
	$(MOON) ci --include-relations --downstream deep

# ---- Single project ----

.PHONY: run
run: ## Run a task of one project (usage: make run APP=sample-api TASK=dev)
	@if [ -z "$(APP)" ] || [ -z "$(TASK)" ]; then echo "$(RED)Error: Set APP and TASK (e.g., make run APP=sample-api TASK=dev)$(RESET)"; exit 1; fi
	$(MOON) run $(APP):$(TASK)

.PHONY: dev
dev: ## Start one project's dev server (usage: make dev APP=sample-web)
	@if [ -z "$(APP)" ]; then echo "$(RED)Error: Set APP (e.g., make dev APP=sample-web)$(RESET)"; exit 1; fi
	$(MOON) run $(APP):dev

.PHONY: projects
projects: ## List all projects in the workspace
	$(MOON) projects

.PHONY: graph
graph: ## Open the interactive project dependency graph
	$(MOON) project-graph

# ---- Docker / Local Dev ----

.PHONY: build-docker
build-docker: ## Build all Docker images
	$(DOCKER_COMPOSE) build

.PHONY: up
up: ## Start local development environment (Docker Compose)
	@echo "$(BLUE)Starting local environment...$(RESET)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Environment is up.$(RESET)"

.PHONY: down
down: ## Stop local development environment
	$(DOCKER_COMPOSE) down
	@echo "$(YELLOW)Environment stopped.$(RESET)"

.PHONY: logs
logs: ## Tail logs from all services
	$(DOCKER_COMPOSE) logs -f

.PHONY: ps
ps: ## Show running containers
	$(DOCKER_COMPOSE) ps

# ---- Infrastructure ----

.PHONY: infra-plan
infra-plan: ## Run Terraform plan (requires TF_ENV, e.g., make infra-plan TF_ENV=dev)
	@if [ -z "$(TF_ENV)" ]; then echo "$(RED)Error: Set TF_ENV (dev/staging/production)$(RESET)"; exit 1; fi
	cd infra/terraform/environments/$(TF_ENV) && terraform plan

.PHONY: infra-apply
infra-apply: ## Run Terraform apply (requires TF_ENV)
	@if [ -z "$(TF_ENV)" ]; then echo "$(RED)Error: Set TF_ENV (dev/staging/production)$(RESET)"; exit 1; fi
	cd infra/terraform/environments/$(TF_ENV) && terraform apply

# ---- Clean ----

.PHONY: clean
clean: ## Remove build artifacts and moon cache
	@echo "$(BLUE)Cleaning build artifacts...$(RESET)"
	find apps packages -type d \( -name bin -o -name obj -o -name dist \) -prune -exec rm -rf {} + 2>/dev/null || true
	$(MOON) clean --lifetime '0 seconds'
	@echo "$(GREEN)Clean complete.$(RESET)"

.PHONY: clean-docker
clean-docker: ## Remove all Docker containers, images, and volumes for this project
	@echo "$(RED)Removing all Docker resources for $(PROJECT_NAME)...$(RESET)"
	$(DOCKER_COMPOSE) down -v --rmi all --remove-orphans

# ---- Docs ----

.PHONY: docs-serve
docs-serve: ## Serve documentation locally (requires: pip install -r docs/requirements.txt)
	mkdocs serve

.PHONY: docs-build
docs-build: ## Build documentation site
	mkdocs build --strict

# ---- Scaffolding ----

.PHONY: stacks
stacks: ## List available app/package generators
	$(MOON) templates

.PHONY: new-app
new-app: ## Scaffold a new app (usage: make new-app STACK=dotnet-service NAME=orders)
	@if [ -z "$(STACK)" ] || [ -z "$(NAME)" ]; then echo "$(RED)Error: Set STACK and NAME (e.g., make new-app STACK=dotnet-service NAME=orders). See 'make stacks'.$(RESET)"; exit 1; fi
	bash tools/scripts/new-project.sh app $(STACK) $(NAME)

.PHONY: new-package
new-package: ## Scaffold a shared package (usage: make new-package STACK=dotnet-library NAME=shared-kernel)
	@if [ -z "$(STACK)" ] || [ -z "$(NAME)" ]; then echo "$(RED)Error: Set STACK and NAME (e.g., make new-package STACK=dotnet-library NAME=shared-kernel). See 'make stacks'.$(RESET)"; exit 1; fi
	bash tools/scripts/new-project.sh package $(STACK) $(NAME)

.PHONY: install-scanners
install-scanners: ## Install pinned, checksum-verified gitleaks and trivy into ~/.local/bin
	bash tools/scripts/install-scanners.sh

.PHONY: scan
scan: ## Scan git history for secrets and dependencies/IaC for vulnerabilities
	bash tools/scripts/scan-security.sh secrets
	bash tools/scripts/scan-security.sh vulns

.PHONY: check-commits
check-commits: ## Check that commits since origin/main are Conventional Commits
	bash tools/scripts/check-conventional.sh --range origin/main..HEAD

.PHONY: test-generators
test-generators: ## Generate one project per stack in a scratch copy and verify it
	bash tools/scripts/test-generators.sh

.PHONY: sync-templates
sync-templates: ## Copy dependency versions from the sample apps into generator templates
	bash tools/scripts/sync-templates.sh

.PHONY: new-adr
new-adr: ## Create a new ADR (usage: make new-adr NAME=database-selection)
	@if [ -z "$(NAME)" ]; then echo "$(RED)Error: Set NAME (e.g., make new-adr NAME=database-selection)$(RESET)"; exit 1; fi
	bash tools/scripts/new-adr.sh $(NAME)
