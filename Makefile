.PHONY: dev test build lint clean

dev:
	@echo "Starting all services in development mode..."
	docker compose -f docker-compose.dev.yml up

test:
	@echo "Running all tests..."
	npm run test

build:
	@echo "Building all packages..."
	npm run build

lint:
	@echo "Linting all code..."
	npm run lint

type-check:
	@echo "Type checking..."
	npm run type-check

infra-synth:
	cd infrastructure/aws-cdk && npm run synth

infra-deploy:
	cd infrastructure/aws-cdk && npm run deploy

clean:
	find . -name "node_modules" -type d -prune -exec rm -rf {} +
	find . -name "dist" -type d -prune -exec rm -rf {} +
	find . -name ".next" -type d -prune -exec rm -rf {} +
