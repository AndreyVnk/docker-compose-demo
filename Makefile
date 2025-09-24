.PHONY: help build up down restart logs clean test health

# Colors for output
BLUE=\033[0;34m
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
NC=\033[0m # No Color

# Main commands
help: ## Show command help
	@echo "$(BLUE)Docker Compose Demo - Available commands:$(NC)\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

build: ## Build all images
	@echo "$(BLUE)🏗️ Building Docker images...$(NC)"
	docker compose build

up: ## Start all services
	@echo "$(BLUE)🚀 Starting all services...$(NC)"
	docker compose up -d
	@echo "$(GREEN)✅ All services started!$(NC)"
	@echo "$(YELLOW)🌐 Application available at: http://localhost$(NC)"

down: ## Stop all services
	@echo "$(BLUE)🛑 Stopping all services...$(NC)"
	docker compose down
	@echo "$(GREEN)✅ All services stopped!$(NC)"

restart: down up ## Restart all services

logs: ## Show logs for all services
	@echo "$(BLUE)📋 Logs for all services:$(NC)"
	docker compose logs -f

logs-web: ## Show Flask application logs
	@echo "$(BLUE)📋 Flask application logs:$(NC)"
	docker compose logs -f web

logs-db: ## Show PostgreSQL logs
	@echo "$(BLUE)📋 PostgreSQL logs:$(NC)"
	docker compose logs -f db

logs-nginx: ## Show Nginx logs
	@echo "$(BLUE)📋 Nginx logs:$(NC)"
	docker compose logs -f nginx

ps: ## Show container status
	@echo "$(BLUE)📊 Container status:$(NC)"
	docker compose ps

health: ## Check health of all services
	@echo "$(BLUE)🏥 Checking service health...$(NC)"
	@echo "$(YELLOW)Nginx Health:$(NC)"
	@curl -s http://localhost/nginx-health || echo "$(RED)❌ Nginx unavailable$(NC)"
	@echo "\n$(YELLOW)Flask Health:$(NC)"
	@curl -s http://localhost/health | jq '.' || echo "$(RED)❌ Flask unavailable$(NC)"
	@echo "$(YELLOW)Database Connection:$(NC)"
	@docker compose exec -T db pg_isready -U devops_user -d devops_db && echo "$(GREEN)✅ PostgreSQL available$(NC)" || echo "$(RED)❌ PostgreSQL unavailable$(NC)"

test: ## Execute test requests
	@echo "$(BLUE)🧪 Executing test requests...$(NC)"
	@echo "$(YELLOW)1. Main page:$(NC)"
	@curl -s http://localhost/ | jq '.'
	@echo "\n$(YELLOW)2. Health check:$(NC)"
	@curl -s http://localhost/health | jq '.'
	@echo "\n$(YELLOW)3. Statistics:$(NC)"
	@curl -s http://localhost/stats | jq '.'

shell-web: ## Connect to Flask container
	@echo "$(BLUE)🐚 Connecting to Flask container...$(NC)"
	docker compose exec web bash

shell-db: ## Connect to PostgreSQL
	@echo "$(BLUE)🐚 Connecting to PostgreSQL...$(NC)"
	docker compose exec db psql -U devops_user -d devops_db

shell-nginx: ## Connect to Nginx container
	@echo "$(BLUE)🐚 Connecting to Nginx container...$(NC)"
	docker compose exec nginx sh

clean: ## Clean everything (containers, images, volumes)
	@echo "$(RED)⚠️  WARNING: This will delete ALL data!$(NC)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] && \
	docker compose down -v --rmi all --remove-orphans && \
	echo "$(GREEN)✅ Cleanup completed!$(NC)" || \
	echo "$(YELLOW)❌ Cleanup cancelled$(NC)"

clean-soft: ## Soft cleanup (containers only)
	@echo "$(BLUE)🧹 Soft cleanup...$(NC)"
	docker compose down --remove-orphans
	@echo "$(GREEN)✅ Soft cleanup completed!$(NC)"

stats: ## Show resource usage statistics
	@echo "$(BLUE)📈 Resource usage statistics:$(NC)"
	docker stats --no-stream

volume-backup: ## Create database backup
	@echo "$(BLUE)💾 Creating database backup...$(NC)"
	@mkdir -p ./backups
	docker compose exec -T db pg_dump -U devops_user devops_db > ./backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✅ Backup created in ./backups/ folder$(NC)"

dev: ## Run in development mode with hot reload
	@echo "$(BLUE)🔧 Starting in development mode...$(NC)"
	FLASK_ENV=development FLASK_DEBUG=1 docker compose up

prod: ## Run in production mode
	@echo "$(BLUE)🚀 Starting in production mode...$(NC)"
	FLASK_ENV=production FLASK_DEBUG=0 docker compose up -d

scale-web: ## Scale Flask application (make scale-web replicas=3)
	@echo "$(BLUE)📈 Scaling Flask application...$(NC)"
	docker compose up -d --scale web=$(or $(replicas),2)
	@echo "$(GREEN)✅ Flask application scaled to $(or $(replicas),2) replicas$(NC)"

network-info: ## Show network information
	@echo "$(BLUE)🌐 Docker network information:$(NC)"
	@docker network ls | grep docker-compose-demo || echo "Network not created"
	@echo "\n$(YELLOW)Detailed information:$(NC)"
	@docker network inspect docker-compose-demo_app-network 2>/dev/null | jq '.[0].Containers' || echo "Network not found"

install-deps: ## Install development dependencies
	@echo "$(BLUE)📦 Installing dependencies...$(NC)"
	@which jq >/dev/null || (echo "$(RED)Need to install jq: sudo apt install jq$(NC)" && exit 1)
	@which curl >/dev/null || (echo "$(RED)Need to install curl: sudo apt install curl$(NC)" && exit 1)
	@echo "$(GREEN)✅ All dependencies installed$(NC)"

# Command aliases
start: up ## Alias for up
stop: down ## Alias for down
rebuild: clean-soft build up ## Rebuild and restart
