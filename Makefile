# Oracle Instant Client Dev Container Makefile
# Provides convenient commands for development and testing

.PHONY: help build test test-db clean check-deps

# Default target
help:
	@echo "Oracle Instant Client Dev Container - Available Commands:"
	@echo ""
	@echo "  make build      - Build the dev container"
	@echo "  make test       - Run SQLPlus installation tests"
	@echo "  make test-db    - Run tests including database connectivity"
	@echo "  make clean      - Clean up containers and images"
	@echo "  make check-deps - Check required dependencies"
	@echo "  make shell      - Open shell in dev container"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - Docker Desktop"
	@echo "  - VS Code with Dev Containers extension"
	@echo "  - Node.js (for dev container CLI)"

# Check if required dependencies are available
check-deps:
	@echo "Checking dependencies..."
	@command -v docker >/dev/null 2>&1 || { echo "❌ Docker not found. Please install Docker Desktop."; exit 1; }
	@command -v node >/dev/null 2>&1 || { echo "❌ Node.js not found. Please install Node.js."; exit 1; }
	@command -v devcontainer >/dev/null 2>&1 || { echo "Installing Dev Container CLI..."; npm install -g @devcontainers/cli; }
	@echo "✅ All dependencies are available"

# Build the dev container
build: check-deps
	@echo "Building dev container..."
	devcontainer build --workspace-folder .

# Run basic tests (no database connection)
test: build
	@echo "Running SQLPlus installation tests..."
	@chmod +x test/test-sqlplus.sh
	devcontainer exec --workspace-folder . ./test/test-sqlplus.sh

# Run tests with database connection
test-db: build
	@echo "Starting Oracle database and running full tests..."
	@echo "This will start a temporary Oracle XE database..."
	docker run -d --name oracle-test-db \
		-p 1521:1521 \
		-e ORACLE_PASSWORD=testpass \
		gvenzl/oracle-xe:21-slim || true
	@echo "Waiting for Oracle database to be ready..."
	@timeout=60; \
	while [ $$timeout -gt 0 ]; do \
		if docker exec oracle-test-db healthcheck.sh >/dev/null 2>&1; then \
			echo "✅ Oracle database is ready"; \
			break; \
		fi; \
		echo "Waiting for Oracle database... ($$timeout seconds remaining)"; \
		sleep 5; \
		timeout=$$((timeout-5)); \
	done
	@chmod +x test/test-sqlplus.sh
	devcontainer exec --workspace-folder . bash -c " \
		export ORACLE_TEST_CONNECTION='system/testpass@//host.docker.internal:1521/xe' && \
		./test/test-sqlplus.sh \
	"
	@echo "Cleaning up test database..."
	docker stop oracle-test-db >/dev/null 2>&1 || true
	docker rm oracle-test-db >/dev/null 2>&1 || true

# Open shell in dev container
shell: build
	@echo "Opening shell in dev container..."
	devcontainer exec --workspace-folder . bash

# Clean up containers and images
clean:
	@echo "Cleaning up dev container resources..."
	@echo "Stopping and removing test containers..."
	docker stop oracle-test-db >/dev/null 2>&1 || true
	docker rm oracle-test-db >/dev/null 2>&1 || true
	@echo "Removing dev container images..."
	docker images | grep "vsc-ora_instantclient" | awk '{print $$3}' | xargs -r docker rmi || true
	@echo "✅ Cleanup completed"

# Quick status check
status:
	@echo "=== Dev Container Status ==="
	@echo "Docker:"
	@docker --version
	@echo ""
	@echo "Node.js:"
	@node --version
	@echo ""
	@echo "Dev Container CLI:"
	@devcontainer --version || echo "Not installed"
	@echo ""
	@echo "Available Oracle images:"
	@docker images | grep oracle || echo "No Oracle images found"
