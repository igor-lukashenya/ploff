# ============================================================================
# Makefile - Universal Task Runner for Monorepo
# ============================================================================
#
# Usage:
#   make help          Show all available commands
#   make setup         Install dependencies for all apps
#   make build         Build all apps
#   make test          Run all tests
#   make lint          Run all linters
#   make up            Start local development environment
#   make down          Stop local development environment
#
# ============================================================================

.DEFAULT_GOAL := help

# ---- Variables ----

PROJECT_NAME ?= ploff
DOCKER_COMPOSE := docker compose -f infra/docker/docker-compose.yml -p $(PROJECT_NAME)

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

# ---- Setup & Dependencies ----

.PHONY: setup
setup: ## Install all dependencies
	@echo "$(BLUE)Installing dependencies...$(RESET)"
	cd apps/sample-api && dotnet restore
	cd apps/sample-web && npm install
	@echo "$(GREEN)Dependencies installed.$(RESET)"

.PHONY: setup-api
setup-api: ## Install sample-api dependencies
	cd apps/sample-api && dotnet restore

.PHONY: setup-web
setup-web: ## Install sample-web dependencies
	cd apps/sample-web && npm install

# ---- Build ----

.PHONY: build
build: build-api build-web ## Build all applications

.PHONY: build-api
build-api: ## Build sample-api
	@echo "$(BLUE)Building sample-api...$(RESET)"
	cd apps/sample-api && dotnet build --no-restore
	@echo "$(GREEN)sample-api built.$(RESET)"

.PHONY: build-web
build-web: ## Build sample-web
	@echo "$(BLUE)Building sample-web...$(RESET)"
	cd apps/sample-web && npm run build
	@echo "$(GREEN)sample-web built.$(RESET)"

.PHONY: build-docker
build-docker: ## Build all Docker images
	@echo "$(BLUE)Building Docker images...$(RESET)"
	$(DOCKER_COMPOSE) build
	@echo "$(GREEN)Docker images built.$(RESET)"

# ---- Test ----

.PHONY: test
test: test-api test-web ## Run all tests

.PHONY: test-api
test-api: ## Run sample-api tests
	@echo "$(BLUE)Running sample-api tests...$(RESET)"
	cd apps/sample-api && dotnet test --verbosity normal
	@echo "$(GREEN)sample-api tests passed.$(RESET)"

.PHONY: test-web
test-web: ## Run sample-web tests
	@echo "$(BLUE)Running sample-web tests...$(RESET)"
	cd apps/sample-web && npm test
	@echo "$(GREEN)sample-web tests passed.$(RESET)"

.PHONY: test-web-watch
test-web-watch: ## Run sample-web tests in watch mode
	cd apps/sample-web && npm run test:watch

# ---- Lint & Format ----

.PHONY: lint
lint: lint-api lint-web ## Run all linters

.PHONY: lint-api
lint-api: ## Lint sample-api
	@echo "$(BLUE)Linting sample-api...$(RESET)"
	cd apps/sample-api && dotnet format --verify-no-changes --verbosity normal
	@echo "$(GREEN)sample-api lint passed.$(RESET)"

.PHONY: lint-web
lint-web: ## Lint sample-web
	@echo "$(BLUE)Linting sample-web...$(RESET)"
	cd apps/sample-web && npm run lint
	@echo "$(GREEN)sample-web lint passed.$(RESET)"

.PHONY: format
format: ## Format all code
	@echo "$(BLUE)Formatting code...$(RESET)"
	cd apps/sample-api && dotnet format
	cd apps/sample-web && npm run lint:fix
	@echo "$(GREEN)Formatting complete.$(RESET)"

# ---- Docker / Local Dev ----

.PHONY: up
up: ## Start local development environment (Docker Compose)
	@echo "$(BLUE)Starting local environment...$(RESET)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Environment is up.$(RESET)"

.PHONY: down
down: ## Stop local development environment
	@echo "$(BLUE)Stopping local environment...$(RESET)"
	$(DOCKER_COMPOSE) down
	@echo "$(YELLOW)Environment stopped.$(RESET)"

.PHONY: logs
logs: ## Tail logs from all services
	$(DOCKER_COMPOSE) logs -f

.PHONY: ps
ps: ## Show running containers
	$(DOCKER_COMPOSE) ps

# ---- Dev Servers ----

.PHONY: dev-api
dev-api: ## Run sample-api in development mode
	cd apps/sample-api && dotnet run

.PHONY: dev-web
dev-web: ## Run sample-web dev server (Vite)
	cd apps/sample-web && npm run dev

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
clean: ## Remove build artifacts and temporary files
	@echo "$(BLUE)Cleaning build artifacts...$(RESET)"
	cd apps/sample-api && dotnet clean --verbosity quiet
	rm -rf apps/sample-web/dist apps/sample-web/node_modules/.vite
	@echo "$(GREEN)Clean complete.$(RESET)"

.PHONY: clean-docker
clean-docker: ## Remove all Docker containers, images, and volumes for this project
	@echo "$(RED)Removing all Docker resources for $(PROJECT_NAME)...$(RESET)"
	$(DOCKER_COMPOSE) down -v --rmi all --remove-orphans
	@echo "$(GREEN)Docker resources removed.$(RESET)"

# ---- Utilities ----

.PHONY: check
check: lint test ## Run lint and test (CI check)

.PHONY: type-check
type-check: ## Run TypeScript type checking for web apps
	cd apps/sample-web && npm run type-check

.PHONY: docs-serve
docs-serve: ## Serve documentation locally (MkDocs Material)
	mkdocs serve

.PHONY: docs-build
docs-build: ## Build documentation site
	mkdocs build

.PHONY: docs-deploy
docs-deploy: ## Deploy docs to GitHub Pages
	mkdocs gh-deploy --force

# ---- Scaffolding ----

.PHONY: new-app
new-app: ## Scaffold a new app (usage: make new-app NAME=my-api)
	@if [ -z "$(NAME)" ]; then echo "$(RED)Error: Set NAME (e.g., make new-app NAME=my-api)$(RESET)"; exit 1; fi
	bash tools/scripts/new-app.sh $(NAME)

.PHONY: new-package
new-package: ## Scaffold a new shared package (usage: make new-package NAME=shared-utils)
	@if [ -z "$(NAME)" ]; then echo "$(RED)Error: Set NAME (e.g., make new-package NAME=shared-utils)$(RESET)"; exit 1; fi
	bash tools/scripts/new-package.sh $(NAME)

.PHONY: new-adr
new-adr: ## Create a new ADR (usage: make new-adr NAME=database-selection)
	@if [ -z "$(NAME)" ]; then echo "$(RED)Error: Set NAME (e.g., make new-adr NAME=database-selection)$(RESET)"; exit 1; fi
	bash tools/scripts/new-adr.sh $(NAME)
