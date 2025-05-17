# Makefile for Ad Agency Budget Management System

# Variables
COMPOSE_FILE = docker-compose.yml
DJANGO_SERVICE = web
DB_SERVICE = db
WORKER_SERVICE = celery_worker
BEAT_SERVICE = celery_beat

# Colors for output
CYAN = \033[0;36m
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

## Help
help: ## Show this help message
	@echo '$(CYAN)Ad Agency Budget Management System$(NC)'
	@echo '$(CYAN)=====================================$(NC)'
	@echo ''
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## Setup and Build
build: ## Build all Docker images
	@echo '$(GREEN)Building Docker images...$(NC)'
	docker-compose -f $(COMPOSE_FILE) build

rebuild: ## Rebuild all Docker images without cache
	@echo '$(GREEN)Rebuilding Docker images without cache...$(NC)'
	docker-compose -f $(COMPOSE_FILE) build --no-cache

setup: ## Initial setup - build and setup test data
	@echo '$(GREEN)Setting up the application...$(NC)'
	@make build
	@make up
	@make wait-for-db
	@make migrate
	@make setup-test-data
	@echo '$(GREEN)Setup complete! Access admin at http://localhost:8000/admin (admin/admin)$(NC)'

## Application Control
up: ## Start all services
	@echo '$(GREEN)Starting all services...$(NC)'
	docker-compose -f $(COMPOSE_FILE) up -d

up-build: ## Build and start all services
	@echo '$(GREEN)Building and starting all services...$(NC)'
	docker-compose -f $(COMPOSE_FILE) up -d --build

down: ## Stop all services
	@echo '$(YELLOW)Stopping all services...$(NC)'
	docker-compose -f $(COMPOSE_FILE) down

destroy: ## Stop all services and remove volumes
	@echo '$(RED)Destroying all services and volumes...$(NC)'
	docker-compose -f $(COMPOSE_FILE) down -v
	docker system prune -f

restart: ## Restart all services
	@echo '$(YELLOW)Restarting all services...$(NC)'
	@make down
	@make up

restart-web: ## Restart only the web service
	@echo '$(YELLOW)Restarting web service...$(NC)'
	docker-compose -f $(COMPOSE_FILE) restart $(DJANGO_SERVICE)

restart-celery: ## Restart Celery services
	@echo '$(YELLOW)Restarting Celery services...$(NC)'
	docker-compose -f $(COMPOSE_FILE) restart $(WORKER_SERVICE) $(BEAT_SERVICE)

## Development
migrate: ## Run Django migrations
	@echo '$(GREEN)Running migrations...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) python manage.py migrate

makemigrations: ## Create Django migrations
	@echo '$(GREEN)Creating migrations...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) python manage.py makemigrations

superuser: ## Create a Django superuser
	@echo '$(GREEN)Creating superuser...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) python manage.py createsuperuser

shell: ## Access Django shell
	@echo '$(GREEN)Opening Django shell...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) python manage.py shell

bash: ## Access bash shell in web container
	@echo '$(GREEN)Opening bash shell...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) bash

## Database
db-shell: ## Access PostgreSQL shell
	@echo '$(GREEN)Opening PostgreSQL shell...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DB_SERVICE) psql -U adagency -d adagency

db-reset: ## Reset database and apply migrations
	@echo '$(YELLOW)Resetting database...$(NC)'
	@make down
	docker volume rm $$(docker volume ls -q | grep postgres) 2>/dev/null || true
	@make up
	@make wait-for-db
	@make migrate

wait-for-db: ## Wait for database to be ready
	@echo '$(YELLOW)Waiting for database...$(NC)'
	@timeout 60 bash -c 'until docker-compose -f $(COMPOSE_FILE) exec $(DB_SERVICE) pg_isready -U adagency -d adagency; do sleep 1; done'

## Testing
setup-test-data: ## Setup initial test data
	@echo '$(GREEN)Setting up test data...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) python manage.py test_budget_system --test setup

test-full: ## Run comprehensive test suite
	@echo '$(GREEN)Running full test suite...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) python manage.py test_budget_system --test full

test-spend: ## Test spend tracking (usage: make test-spend BRAND="Test Brand A" AMOUNT=100)
	@echo '$(GREEN)Testing spend tracking...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) python manage.py test_budget_system --test spend $(if $(BRAND),--brand "$(BRAND)") $(if $(AMOUNT),--amount $(AMOUNT))

test-dayparting: ## Test dayparting functionality
	@echo '$(GREEN)Testing dayparting...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) python manage.py test_budget_system --test dayparting

test-reset: ## Test reset functionality
	@echo '$(GREEN)Testing reset functionality...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) python manage.py test_budget_system --test reset

simulate-spend: ## Simulate ad spend (usage: make simulate-spend MIN=10 MAX=50)
	@echo '$(GREEN)Simulating ad spend...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) python manage.py record_spend --min $(or $(MIN),10) --max $(or $(MAX),50)

simulate-time: ## Simulate different time for dayparting (usage: make simulate-time HOUR=9)
	@echo '$(GREEN)Simulating time...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) python manage.py simulate_time $(if $(HOUR),--hour $(HOUR)) $(if $(DAY),--day $(DAY))

load-test: ## Run load testing with multiple spend simulations
	@echo '$(GREEN)Running load test...$(NC)'
	@for i in {1..20}; do \
		make simulate-spend MIN=5 MAX=25; \
		sleep 2; \
	done

## Monitoring
monitor: ## Real-time system monitoring
	@echo '$(GREEN)Starting system monitor...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(DJANGO_SERVICE) python manage.py monitor_system --interval 30

logs: ## View all logs
	@echo '$(GREEN)Viewing all logs...$(NC)'
	docker-compose -f $(COMPOSE_FILE) logs

logs-web: ## View web service logs
	@echo '$(GREEN)Viewing web logs...$(NC)'
	docker-compose -f $(COMPOSE_FILE) logs -f $(DJANGO_SERVICE)

logs-worker: ## View Celery worker logs
	@echo '$(GREEN)Viewing worker logs...$(NC)'
	docker-compose -f $(COMPOSE_FILE) logs -f $(WORKER_SERVICE)

logs-beat: ## View Celery beat logs
	@echo '$(GREEN)Viewing beat logs...$(NC)'
	docker-compose -f $(COMPOSE_FILE) logs -f $(BEAT_SERVICE)

logs-db: ## View database logs
	@echo '$(GREEN)Viewing database logs...$(NC)'
	docker-compose -f $(COMPOSE_FILE) logs -f $(DB_SERVICE)

status: ## Show status of all services
	@echo '$(GREEN)Service status:$(NC)'
	docker-compose -f $(COMPOSE_FILE) ps

top: ## Show running processes
	@echo '$(GREEN)Running processes:$(NC)'
	docker-compose -f $(COMPOSE_FILE) top

## Celery
celery-shell: ## Access Celery shell
	@echo '$(GREEN)Opening Celery shell...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(WORKER_SERVICE) celery -A ad_agency shell

celery-inspect: ## Inspect Celery workers
	@echo '$(GREEN)Inspecting Celery workers...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(WORKER_SERVICE) celery -A ad_agency inspect active

celery-scheduled: ## View scheduled Celery tasks
	@echo '$(GREEN)Viewing scheduled tasks...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(BEAT_SERVICE) celery -A ad_agency inspect scheduled

celery-events: ## Monitor Celery events
	@echo '$(GREEN)Monitoring Celery events...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(WORKER_SERVICE) celery -A ad_agency events

## Manual Task Execution
task-budget-check: ## Manually execute budget check task
	@echo '$(GREEN)Executing budget check task...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(WORKER_SERVICE) celery -A ad_agency call app.tasks.check_all_budgets

task-dayparting: ## Manually execute dayparting check task
	@echo '$(GREEN)Executing dayparting check task...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(WORKER_SERVICE) celery -A ad_agency call app.tasks.check_dayparting

task-daily-reset: ## Manually execute daily reset task
	@echo '$(GREEN)Executing daily reset task...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(WORKER_SERVICE) celery -A ad_agency call app.tasks.reset_daily_spend

task-monthly-reset: ## Manually execute monthly reset task
	@echo '$(GREEN)Executing monthly reset task...$(NC)'
	docker-compose -f $(COMPOSE_FILE) exec $(WORKER_SERVICE) celery -A ad_agency call app.tasks.reset_monthly_spend

## Cleanup
clean: ## Remove unused Docker resources
	@echo '$(YELLOW)Cleaning up Docker resources...$(NC)'
	docker system prune -f

clean-all: ## Remove all Docker resources including volumes
	@echo '$(RED)Cleaning up all Docker resources...$(NC)'
	docker system prune -a -f --volumes

## Quick Actions
quick-test: setup-test-data simulate-spend test-dayparting ## Setup data, simulate spend, and test dayparting

demo: ## Run a demonstration of the system
	@echo '$(CYAN)Starting demo...$(NC)'
	@make setup-test-data
	@echo '$(YELLOW)Simulating normal spend...$(NC)'
	@make simulate-spend MIN=20 MAX=40
	@echo '$(YELLOW)Testing budget enforcement...$(NC)'
	@make test-spend BRAND="Test Brand A" AMOUNT=150
	@echo '$(YELLOW)Testing dayparting...$(NC)'
	@make test-dayparting
	@echo '$(GREEN)Demo complete! Check http://localhost:8000/admin for results$(NC)'

dev-reset: ## Full development reset
	@echo '$(YELLOW)Performing full development reset...$(NC)'
	@make down
	@make clean
	@make setup

## Health Checks
health: ## Check health of all services
	@echo '$(GREEN)Checking service health...$(NC)'
	@echo '$(YELLOW)Database status:$(NC)'
	@docker-compose -f $(COMPOSE_FILE) exec $(DB_SERVICE) pg_isready -U adagency -d adagency && echo '$(GREEN)✓ Database is ready$(NC)' || echo '$(RED)✗ Database is not ready$(NC)'
	@echo '$(YELLOW)Redis status:$(NC)'
	@docker-compose -f $(COMPOSE_FILE) exec redis redis-cli ping && echo '$(GREEN)✓ Redis is ready$(NC)' || echo '$(RED)✗ Redis is not ready$(NC)'
	@echo '$(YELLOW)Django status:$(NC)'
	@curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/admin/ | grep -q 200 && echo '$(GREEN)✓ Django is ready$(NC)' || echo '$(RED)✗ Django is not ready$(NC)'

.PHONY: help build rebuild setup up up-build down destroy restart restart-web restart-celery migrate makemigrations superuser shell bash db-shell db-reset wait-for-db setup-test-data test-full test-spend test-dayparting test-reset simulate-spend simulate-time load-test monitor logs logs-web logs-worker logs-beat logs-db status top celery-shell celery-inspect celery-scheduled celery-events task-budget-check task-dayparting task-daily-reset task-monthly-reset clean clean-all quick-test demo dev-reset health