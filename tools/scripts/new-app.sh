#!/usr/bin/env bash
#
# new-app.sh — Scaffold a new application in apps/
#
# Usage:
#   ./tools/scripts/new-app.sh <app-name>
#
# Example:
#   ./tools/scripts/new-app.sh api
#   ./tools/scripts/new-app.sh web-admin

set -euo pipefail

# ─── Validation ──────────────────────────────────────────────────────────────

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <app-name>"
  echo "Example: $0 api"
  exit 1
fi

APP_NAME="$1"
APP_DIR="apps/${APP_NAME}"

if [ -d "$APP_DIR" ]; then
  echo "Error: ${APP_DIR} already exists."
  exit 1
fi

# Validate kebab-case name
if ! echo "$APP_NAME" | grep -qE '^[a-z][a-z0-9-]*$'; then
  echo "Error: App name must be kebab-case (lowercase letters, numbers, hyphens)."
  exit 1
fi

# ─── Create App Structure ────────────────────────────────────────────────────

echo "Creating app: ${APP_NAME}..."

mkdir -p "${APP_DIR}/src"
mkdir -p "${APP_DIR}/tests/unit"
mkdir -p "${APP_DIR}/tests/integration"

# README
cat > "${APP_DIR}/README.md" << EOF
# ${APP_NAME}

> TODO: Describe what this application does.

## Prerequisites

> TODO: List required tools and runtimes.

## Setup

\`\`\`bash
cd ${APP_DIR}
# TODO: Add setup commands (e.g., npm install, pip install -r requirements.txt)
\`\`\`

## Running Locally

\`\`\`bash
# TODO: Add run command
\`\`\`

## Testing

\`\`\`bash
# TODO: Add test command
\`\`\`

## Environment Variables

| Variable | Description | Default |
| --- | --- | --- |
| \`APP_PORT\` | Port the app listens on | \`3000\` |

## Docker

\`\`\`bash
docker build -f infra/docker/Dockerfile.${APP_NAME} -t ${APP_NAME}:latest .
docker run -p 3000:3000 ${APP_NAME}:latest
\`\`\`
EOF

# .env.example
cat > "${APP_DIR}/.env.example" << EOF
# Environment variables for ${APP_NAME}
# Copy to .env: cp .env.example .env

APP_PORT=3000
APP_ENV=development
EOF

# .gitkeep for empty dirs
touch "${APP_DIR}/src/.gitkeep"
touch "${APP_DIR}/tests/unit/.gitkeep"
touch "${APP_DIR}/tests/integration/.gitkeep"

# Dockerfile template
mkdir -p infra/docker
cat > "infra/docker/Dockerfile.${APP_NAME}" << EOF
# Dockerfile for ${APP_NAME}
#
# Build:  docker build -f infra/docker/Dockerfile.${APP_NAME} -t ${APP_NAME}:latest .
# Run:    docker run -p 3000:3000 ${APP_NAME}:latest

# TODO: Replace with the appropriate base image for your tech stack
# FROM node:20-alpine
# FROM python:3.12-slim
# FROM mcr.microsoft.com/dotnet/aspnet:8.0
# FROM golang:1.22-alpine

# WORKDIR /app

# TODO: Copy dependencies and install
# COPY apps/${APP_NAME}/package*.json ./
# RUN npm ci --production

# TODO: Copy application code
# COPY apps/${APP_NAME}/src ./src
# COPY packages/ ../packages/

# TODO: Set the default command
# CMD ["node", "src/index.js"]

# Placeholder — replace with your actual build steps
FROM alpine:latest
CMD ["echo", "TODO: Configure Dockerfile for ${APP_NAME}"]
EOF

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "✅ App '${APP_NAME}' created successfully!"
echo ""
echo "   ${APP_DIR}/"
echo "   ├── README.md"
echo "   ├── .env.example"
echo "   ├── src/"
echo "   └── tests/"
echo "       ├── unit/"
echo "       └── integration/"
echo ""
echo "   infra/docker/Dockerfile.${APP_NAME}"
echo ""
echo "Next steps:"
echo "  1. Initialize the project with your framework's tooling"
echo "  2. Update the README with setup/run/test instructions"
echo "  3. Add the service to infra/docker/docker-compose.yml"
echo "  4. Add build/test targets to the root Makefile"
