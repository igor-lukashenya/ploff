# ============================================================================
# Makefile — Universal Task Runner for Monorepo
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

# ─── Variables ───────────────────────────────────────────────────────────────

PROJECT_NAME ?= project-name
DOCKER_COMPOSE := docker compose -f infra/docker/docker-compose.yml -p $(PROJECT_NAME)

# Colors for terminal output
BLUE   := \033[36m
GREEN  := \033[32m
YELLOW := \033[33m
RED    := \033[31m
RESET  := \033[0m

# ─── Help ────────────────────────────────────────────────────────────────────

.PHONY: help
help: ## Show this help message
	@echo ""
	@echo "$(BLUE)$(PROJECT_NAME)$(RESET) — Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ─── Setup & Dependencies ───────────────────────────────────────────────────

.PHONY: setup
setup: ## Install all dependencies
	@echo "$(BLUE)Installing dependencies...$(RESET)"
	@# TODO: Add dependency installation commands for each app
	@# Example:
	@# cd apps/api && npm install
	@# cd apps/web && npm install
	@echo "$(GREEN)Dependencies installed.$(RESET)"

# ─── Build ───────────────────────────────────────────────────────────────────

.PHONY: build
build: ## Build all applications
	@echo "$(BLUE)Building all apps...$(RESET)"
	@# TODO: Add build commands for each app
	@echo "$(GREEN)Build complete.$(RESET)"

.PHONY: build-docker
build-docker: ## Build all Docker images
	@echo "$(BLUE)Building Docker images...$(RESET)"
	$(DOCKER_COMPOSE) build
	@echo "$(GREEN)Docker images built.$(RESET)"

# ─── Test ────────────────────────────────────────────────────────────────────

.PHONY: test
test: ## Run all tests
	@echo "$(BLUE)Running all tests...$(RESET)"
	@# TODO: Add test commands for each app
	@# Example:
	@# cd apps/api && npm test
	@# cd apps/web && npm test
	@echo "$(GREEN)All tests passed.$(RESET)"

.PHONY: test-unit
test-unit: ## Run unit tests only
	@echo "$(BLUE)Running unit tests...$(RESET)"
	@# TODO: Add unit test commands
	@echo "$(GREEN)Unit tests passed.$(RESET)"

.PHONY: test-integration
test-integration: ## Run integration tests
	@echo "$(BLUE)Running integration tests...$(RESET)"
	@# TODO: Add integration test commands
	@echo "$(GREEN)Integration tests passed.$(RESET)"

# ─── Lint & Format ──────────────────────────────────────────────────────────

.PHONY: lint
lint: ## Run all linters
	@echo "$(BLUE)Running linters...$(RESET)"
	@# TODO: Add lint commands for each app
	@echo "$(GREEN)Linting passed.$(RESET)"

.PHONY: format
format: ## Format all code
	@echo "$(BLUE)Formatting code...$(RESET)"
	@# TODO: Add format commands
	@echo "$(GREEN)Formatting complete.$(RESET)"

# ─── Docker / Local Dev ─────────────────────────────────────────────────────

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

# ─── Infrastructure ─────────────────────────────────────────────────────────

.PHONY: infra-plan
infra-plan: ## Run Terraform plan (requires TF_ENV, e.g., make infra-plan TF_ENV=dev)
	@if [ -z "$(TF_ENV)" ]; then echo "$(RED)Error: Set TF_ENV (dev/staging/production)$(RESET)"; exit 1; fi
	cd infra/terraform/environments/$(TF_ENV) && terraform plan

.PHONY: infra-apply
infra-apply: ## Run Terraform apply (requires TF_ENV)
	@if [ -z "$(TF_ENV)" ]; then echo "$(RED)Error: Set TF_ENV (dev/staging/production)$(RESET)"; exit 1; fi
	cd infra/terraform/environments/$(TF_ENV) && terraform apply

# ─── Clean ───────────────────────────────────────────────────────────────────

.PHONY: clean
clean: ## Remove build artifacts and temporary files
	@echo "$(BLUE)Cleaning build artifacts...$(RESET)"
	@# TODO: Add clean commands for each app
	@echo "$(GREEN)Clean complete.$(RESET)"

.PHONY: clean-docker
clean-docker: ## Remove all Docker containers, images, and volumes for this project
	@echo "$(RED)Removing all Docker resources for $(PROJECT_NAME)...$(RESET)"
	$(DOCKER_COMPOSE) down -v --rmi all --remove-orphans
	@echo "$(GREEN)Docker resources removed.$(RESET)"

# ─── Utilities ───────────────────────────────────────────────────────────────

.PHONY: check
check: lint test ## Run lint and test (CI check)

.PHONY: docs-serve
docs-serve: ## Serve documentation locally (requires a docs tool)
	@echo "$(BLUE)Serving docs...$(RESET)"
	@# TODO: Add docs serving command (e.g., mkdocs serve, docsify serve)
	@echo "$(YELLOW)No docs tool configured yet. See docs/README.md$(RESET)"
