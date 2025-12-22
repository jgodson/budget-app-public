.PHONY: setup start seed console test lint stop

# Detect container engine (docker or podman)
DOCKER_CMD := $(shell command -v docker > /dev/null 2>&1 && echo docker || (command -v podman > /dev/null 2>&1 && echo podman || echo docker))

# Default target
all: start

# Setup the project (install dependencies, setup DB)
setup:
	@echo "Using container engine: $(DOCKER_CMD)"
	@echo "Installing dependencies..."
	@bundle install
	@npm install
	@echo "Setting up environment..."
	@[ -f .env ] || cp .env.example .env
	@echo "Setting up database..."
	@$(DOCKER_CMD) compose up -d
	@bin/rails db:prepare
	@echo "Setup complete!"

# Start the application
start:
	@echo "Using container engine: $(DOCKER_CMD)"
	@echo "Starting database..."
	@$(DOCKER_CMD) compose up -d
	@echo "Starting Rails server..."
	@bin/rails s

# Seed data
seed:
	@./scripts/seed-data.sh 2y CLEAN=true

# Open Rails console
console:
	@bin/rails c

# Run tests
test:
	@bin/rails test

# Stop containers
stop:
	@echo "Stopping containers..."
	@$(DOCKER_CMD) compose down
	@echo "Cleaning up..."
