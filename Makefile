.PHONY: help dev test lint migrate-up migrate-down migrate-create sqlc-generate docker-up docker-down backend-run mobile-run

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Docker commands
docker-up: ## Start all Docker services
	docker-compose up -d

docker-down: ## Stop all Docker services
	docker-compose down

dev: docker-up ## Start development environment
	@echo "✅ Development environment is running!"
	@echo "  - PostgreSQL: localhost:5432"
	@echo "  - Redis: localhost:6379"
	@echo "  - LiveKit: localhost:7880"
	@echo "  - Grafana: http://localhost:3100"
	@echo ""
	@echo "Run 'make backend-run' or 'make mobile-run' to start services"

# Database migrations
migrate-up: ## Run database migrations up
	cd backend && go run cmd/migrate/main.go up

migrate-down: ## Run database migrations down
	cd backend && go run cmd/migrate/main.go down

migrate-create: ## Create new migration (usage: make migrate-create name=my_migration)
	@if [ -z "$(name)" ]; then \
		echo "Error: name parameter is required. Usage: make migrate-create name=my_migration"; \
		exit 1; \
	fi
	@cd backend && go run cmd/migrate/main.go create $(name)

# SQLc code generation
sqlc-generate: ## Generate Go code from SQL queries using sqlc
	cd backend && sqlc generate

# Backend commands
backend-build: ## Build backend Go binary
	cd backend && go build -o bin/api cmd/api/main.go
	cd backend && go build -o bin/worker cmd/worker/main.go

backend-run: ## Run backend API server (requires dev environment)
	cd backend && go run cmd/api/main.go

backend-worker: ## Run backend worker
	cd backend && go run cmd/worker/main.go

backend-test: ## Run backend tests
	cd backend && go test -v -cover ./...

backend-lint: ## Run backend linters
	cd backend && go vet ./...
	cd backend && golangci-lint run ./... || echo "golangci-lint not installed, skipping"

# Mobile commands
mobile-install: ## Install mobile dependencies
	cd mobile && npm install --legacy-peer-deps

mobile-run: ## Run mobile app with Expo
	cd mobile && npx expo start

mobile-run-android: ## Run mobile app on Android emulator
	cd mobile && npx expo run:android

mobile-run-ios: ## Run mobile app on iOS simulator (macOS only)
	cd mobile && npx expo run:ios

mobile-test: ## Run mobile tests
	cd mobile && npm test

mobile-lint: ## Run mobile linters
	cd mobile && npm run lint || echo "lint script not defined"

mobile-build-android: ## Build Android app with EAS
	cd mobile && npx eas build --profile development --platform android

mobile-build-ios: ## Build iOS app with EAS
	cd mobile && npx eas build --profile development --platform ios

# Combined commands
test: backend-test mobile-test ## Run all tests

lint: backend-lint mobile-lint ## Run all linters

# Setup commands
setup-backend: ## Setup backend (install dependencies, generate code)
	cd backend && go mod download
	cd backend && go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
	$(MAKE) sqlc-generate

setup-mobile: mobile-install ## Setup mobile (install dependencies)

setup: setup-backend setup-mobile ## Setup everything

# Clean commands
clean: ## Clean build artifacts
	rm -rf backend/bin
	rm -rf mobile/node_modules
	rm -rf mobile/.expo
	docker-compose down -v

# Full rebuild
rebuild: clean setup dev ## Clean and rebuild everything

