# Makefile for DMS Outlet Service
.PHONY: help build run test migrate clean docker

help: ## Show help
	@echo "DMS Outlet Service - Enterprise FMCG Backend"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build binary
	go build -o bin/outlet-service ./cmd

run: ## Run server
	go run ./cmd

test: ## Run tests
	go test ./... -v

migrate: ## Run DB migrations
	psql -U postgres -d dms -f scripts/run_migrations.sql

migrate-value-set: ## Run value set schema
	psql -U postgres -d dms -f ../sql/01_schema_value_set.sql

migrate-outlets: ## Run outlets schema
	psql -U postgres -d dms -f ../sql/02_schema_outlets.sql

clean: ## Clean build artifacts
	rm -rf bin/

docker-build: ## Build Docker image
	docker build -t dms-outlet-service:latest .

docker-run: ## Run Docker container
	docker run -p 3001:3001 --env-file .env dms-outlet-service:latest

mod: ## Download go modules
	go mod download
	go mod tidy

lint: ## Run linter
	golangci-lint run ./...