.PHONY: help build up down start stop restart logs clean ps status shell backup restore setup env-check

# Default target
.DEFAULT_GOAL := help

# Colors for output
YELLOW := \033[1;33m
GREEN := \033[1;32m
RED := \033[1;31m
NC := \033[0m # No Color

# Project variables
PROJECT_NAME := n8n-workflow
COMPOSE_FILE := docker-compose.yml
ENV_FILE := .env

## help: Display this help message
help:
	@echo "$(GREEN)Available targets:$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(GREEN)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup

## setup: Initial project setup (copy .env.example to .env and generate encryption key)
setup:
	@echo "$(GREEN)Setting up n8n project...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(YELLOW)Creating .env file from .env.example...$(NC)"; \
		cp .env.example $(ENV_FILE); \
		echo "$(GREEN).env file created$(NC)"; \
	else \
		echo "$(YELLOW).env file already exists$(NC)"; \
	fi
	@if [ -z "$$(grep -E '^N8N_ENCRYPTION_KEY=.+' $(ENV_FILE) 2>/dev/null)" ]; then \
		echo "$(YELLOW)Generating encryption key...$(NC)"; \
		ENCRYPTION_KEY=$$(openssl rand -base64 32); \
		if grep -q "^N8N_ENCRYPTION_KEY=" $(ENV_FILE); then \
			sed -i "s|^N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=$$ENCRYPTION_KEY|" $(ENV_FILE); \
		else \
			echo "N8N_ENCRYPTION_KEY=$$ENCRYPTION_KEY" >> $(ENV_FILE); \
		fi; \
		echo "$(GREEN)Encryption key generated and added to .env$(NC)"; \
	else \
		echo "$(GREEN)Encryption key already set$(NC)"; \
	fi
	@echo "$(GREEN)Setup complete!$(NC)"

## env-check: Check if .env file exists and has required variables
env-check:
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)Error: .env file not found. Run 'make setup' first.$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$$(grep -E '^N8N_ENCRYPTION_KEY=.+' $(ENV_FILE))" ]; then \
		echo "$(RED)Error: N8N_ENCRYPTION_KEY not set in .env file. Run 'make setup' first.$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Environment check passed$(NC)"

##@ Docker Operations

## build: Build the Docker image
build: env-check
	@echo "$(GREEN)Building Docker image...$(NC)"
	docker-compose -f $(COMPOSE_FILE) build

## up: Start n8n in detached mode
up: env-check
	@echo "$(GREEN)Starting n8n...$(NC)"
	docker-compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)n8n is running at http://localhost:5678$(NC)"

## down: Stop and remove containers, networks
down:
	@echo "$(YELLOW)Stopping n8n...$(NC)"
	docker-compose -f $(COMPOSE_FILE) down

## start: Start existing containers
start: env-check
	@echo "$(GREEN)Starting n8n containers...$(NC)"
	docker-compose -f $(COMPOSE_FILE) start

## stop: Stop running containers without removing them
stop:
	@echo "$(YELLOW)Stopping n8n containers...$(NC)"
	docker-compose -f $(COMPOSE_FILE) stop

## restart: Restart n8n containers
restart:
	@echo "$(YELLOW)Restarting n8n...$(NC)"
	docker-compose -f $(COMPOSE_FILE) restart

## logs: View n8n logs (follow mode)
logs:
	docker-compose -f $(COMPOSE_FILE) logs -f

## logs-tail: View last 100 lines of n8n logs
logs-tail:
	docker-compose -f $(COMPOSE_FILE) logs --tail=100

## ps: List running containers
ps:
	docker-compose -f $(COMPOSE_FILE) ps

## status: Show status of n8n services
status:
	@echo "$(GREEN)n8n Service Status:$(NC)"
	@docker-compose -f $(COMPOSE_FILE) ps

##@ Development

## shell: Open a shell in the n8n container
shell:
	@echo "$(GREEN)Opening shell in n8n container...$(NC)"
	docker exec -it n8n sh

## rebuild: Rebuild and restart n8n
rebuild: down build up

## update: Pull latest n8n image and restart
update:
	@echo "$(GREEN)Updating n8n...$(NC)"
	docker-compose -f $(COMPOSE_FILE) pull
	docker-compose -f $(COMPOSE_FILE) up -d --force-recreate
	@echo "$(GREEN)n8n updated successfully$(NC)"

##@ Backup & Restore

## backup: Backup n8n data (workflows and credentials)
backup:
	@echo "$(GREEN)Creating backup...$(NC)"
	@mkdir -p backups
	@BACKUP_FILE="backups/n8n-backup-$$(date +%Y%m%d-%H%M%S).tar.gz"; \
	docker-compose -f $(COMPOSE_FILE) exec -T n8n tar czf - -C /home/node/.n8n workflows credentials > $$BACKUP_FILE 2>/dev/null || \
	tar czf $$BACKUP_FILE ./workflows ./credentials 2>/dev/null; \
	echo "$(GREEN)Backup created: $$BACKUP_FILE$(NC)"

## restore: Restore n8n data from backup (usage: make restore BACKUP=backups/n8n-backup-YYYYMMDD-HHMMSS.tar.gz)
restore:
	@if [ -z "$(BACKUP)" ]; then \
		echo "$(RED)Error: Please specify BACKUP file. Usage: make restore BACKUP=backups/n8n-backup-YYYYMMDD-HHMMSS.tar.gz$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f $(BACKUP) ]; then \
		echo "$(RED)Error: Backup file $(BACKUP) not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restoring from $(BACKUP)...$(NC)"
	@tar xzf $(BACKUP) -C .
	@echo "$(GREEN)Restore complete. Restart n8n with 'make restart'$(NC)"

##@ Cleanup

## clean: Remove stopped containers and unused volumes
clean:
	@echo "$(YELLOW)Cleaning up...$(NC)"
	docker-compose -f $(COMPOSE_FILE) down -v
	@echo "$(GREEN)Cleanup complete$(NC)"

## clean-all: Remove everything including images and backups
clean-all: clean
	@echo "$(RED)Removing all n8n data, images, and backups...$(NC)"
	@read -p "Are you sure? This will delete all data! [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose -f $(COMPOSE_FILE) down -v --rmi all; \
		rm -rf backups; \
		echo "$(GREEN)All data removed$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

##@ Quick Commands

## install: Full installation (setup + build + up)
install: setup build up
	@echo "$(GREEN)n8n installation complete!$(NC)"
	@echo "$(GREEN)Access n8n at: http://localhost:5678$(NC)"

## dev: Start n8n with logs visible
dev: env-check
	@echo "$(GREEN)Starting n8n in development mode...$(NC)"
	docker-compose -f $(COMPOSE_FILE) up
