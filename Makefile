.PHONY: help install test lint format check-migrations migrate createsuperuser runserver shell celery-worker celery-beat flower test-coverage clean docker-build docker-up docker-down docker-logs docker-bash docker-db-bash docker-redis-cli check-services setup-ssl backup-db restore-db

# Colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

# Help target
help:
	@echo '\n${YELLOW}Available commands:${RESET}'
	@echo ''
	@echo '${YELLOW}Project setup:${RESET}'
	@echo '  ${GREEN}make install${RESET}            - Install dependencies and set up the project'
	@echo '  ${GREEN}make setup-ssl${RESET}          - Set up SSL certificates with Let\'s Encrypt'
	@echo ''
	@echo '${YELLOW}Development:${RESET}'
	@echo '  ${GREEN}make runserver${RESET}          - Start the development server'
	@echo '  ${GREEN}make shell${RESET}              - Open a Django shell'
	@echo '  ${GREEN}make createsuperuser${RESET}    - Create a superuser'
	@echo '  ${GREEN}make migrate${RESET}            - Run database migrations'
	@echo '  ${GREEN}make check-migrations${RESET}   - Check for missing migrations'
	@echo ''
	@echo '${YELLOW}Celery:${RESET}'
	@echo '  ${GREEN}make celery-worker${RESET}      - Start Celery worker'
	@echo '  ${GREEN}make celery-beat${RESET}        - Start Celery beat'
	@echo '  ${GREEN}make flower${RESET}             - Start Flower monitoring'
	@echo ''
	@echo '${YELLOW}Testing & Quality:${RESET}'
	@echo '  ${GREEN}make test${RESET}               - Run tests'
	@echo '  ${GREEN}make test-coverage${RESET}      - Run tests with coverage report'
	@echo '  ${GREEN}make lint${RESET}               - Run code linters'
	@echo '  ${GREEN}make format${RESET}             - Format code using Black and isort'
	@echo ''
	@echo '${YELLOW}Docker:${RESET}'
	@echo '  ${GREEN}make docker-build${RESET}       - Build Docker images'
	@echo '  ${GREEN}make docker-up${RESET}          - Start all services with Docker Compose'
	@echo '  ${GREEN}make docker-down${RESET}        - Stop all services'
	@echo '  ${GREEN}make docker-logs${RESET}        - View logs from all services'
	@echo '  ${GREEN}make docker-bash${RESET}        - Open a bash shell in the web container'
	@echo '  ${GREEN}make docker-db-bash${RESET}     - Open a bash shell in the database container'
	@echo '  ${GREEN}make docker-redis-cli${RESET}   - Open a Redis CLI'
	@echo ''
	@echo '${YELLOW}Database:${RESET}'
	@echo '  ${GREEN}make backup-db${RESET}          - Create a database backup'
	@echo '  ${GREEN}make restore-db${RESET}         - Restore the database from a backup'
	@echo ''
	@echo '${YELLOW}Maintenance:${RESET}'
	@echo '  ${GREEN}make check-services${RESET}     - Check the status of all services'
	@echo '  ${GREEN}make clean${RESET}              - Remove Python and build artifacts'

# Project setup
install:
	@echo "\n${GREEN}Installing dependencies and setting up the project...${RESET}"
	python -m pip install --upgrade pip
	pip install -r requirements.txt
	pre-commit install
	@echo "\n${GREEN}Project setup complete!${RESET}"
	@echo "Run 'make runserver' to start the development server"

# Development
runserver:
	python manage.py runserver

shell:
	python manage.py shell

createsuperuser:
	python manage.py createsuperuser

migrate:
	python manage.py migrate

check-migrations:
	python manage.py makemigrations --dry-run --check

# Celery
celery-worker:
	celery -A core worker -l info

celery-beat:
	celery -A core beat -l info -S django

flower:
	celery -A core flower --port=5555

# Testing & Quality
test:
	pytest

test-coverage:
	pytest --cov=.

lint:
	black --check .
	isort --check-only .
	flake8 .
	mypy .

format:
	black .
	isort .

# Docker
docker-build:
	docker-compose build

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f

docker-bash:
	docker-compose exec web bash

docker-db-bash:
	docker-compose exec db bash

docker-redis-cli:
	docker-compose exec redis redis-cli

# Database
backup-db:
	@echo "${GREEN}Creating database backup...${RESET}"
	@mkdir -p backups
	@docker-compose exec -T db pg_dump -U $$(grep POSTGRES_USER .env | cut -d '=' -f2) $$(grep POSTGRES_DB .env | cut -d '=' -f2) > backups/backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "${GREEN}Backup created in backups/ directory${RESET}
"

restore-db:
	@if [ -z "$${BACKUP_FILE}" ]; then \
		echo "${YELLOW}Usage: make restore-db BACKUP_FILE=path/to/backup.sql${RESET}"; \
		echo "${YELLOW}Available backups:${RESET}"; \
		ls -l backups/; \
		exit 1; \
	fi
	@echo "${YELLOW}This will delete all current data and restore from $${BACKUP_FILE}${RESET}"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "${GREEN}Restoring database from $${BACKUP_FILE}...${RESET}"; \
		docker-compose stop web celery celery-beat; \
		cat $${BACKUP_FILE} | docker-compose exec -T db psql -U $$(grep POSTGRES_USER .env | cut -d '=' -f2) $$(grep POSTGRES_DB .env | cut -d '=' -f2); \
		echo "${GREEN}Database restored. Starting services...${RESET}"; \
		docker-compose up -d; \
	else \
		echo "${YELLOW}Restore cancelled${RESET}"; \
	fi

# Maintenance
check-services:
	@./scripts/check_services.sh

setup-ssl:
	@if [ -z "$${DOMAIN}" ]; then \
		echo "${YELLOW}Usage: make setup-ssl DOMAIN=yourdomain.com${RESET}"; \
		exit 1; \
	fi
	@./scripts/setup_ssl.sh $${DOMAIN}

# Cleanup
clean:
	@echo "${YELLOW}Cleaning up...${RESET}"
	find . -type d -name "__pycache__" -exec rm -r {} +
	find . -type d -name ".pytest_cache" -exec rm -r {} +
	find . -type d -name "*.egg-info" -exec rm -r {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.pyd" -delete
	rm -rf .coverage htmlcov/
	rm -rf build/ dist/ *.egg-info/
	rf -rf .mypy_cache/
	@echo "${GREEN}Cleanup complete!${RESET}"
