# EFM Test Environment Makefile

.PHONY: help build up down logs status clean test-failover test-switchover monitor reset view-logs analyze-logs export-logs export-logs-archive efm-logs start debug-packages

# Default target
help:
	@echo "EFM Test Environment Commands:"
	@echo ""
	@echo "Environment Management:"
	@echo "  make build        - Build Docker images"
	@echo "  make up          - Start the environment"
	@echo "  make down        - Stop the environment"
	@echo "  make clean       - Clean up everything"
	@echo "  make start       - Build and start (quick start)"
	@echo ""
	@echo "Monitoring & Testing:"
	@echo "  make status      - Show cluster status"
	@echo "  make monitor     - Monitor cluster (continuous)"
	@echo "  make test-failover   - Test automatic failover"
	@echo "  make test-switchover - Test manual switchover"
	@echo "  make reset       - Reset cluster to initial state"
	@echo ""
	@echo "Log Management:"
	@echo "  make view-logs   - Interactive log viewer"
	@echo "  make analyze-logs - Analyze logs for issues"
	@echo "  make export-logs - Export logs for analysis"
	@echo "  make export-logs-archive - Export and archive logs"
	@echo ""
	@echo "Debugging:"
	@echo "  make debug-packages - Check EFM package availability"
	@echo ""
	@echo "System Logs:"
	@echo "  make logs        - Show Docker container logs"
	@echo "  make efm-logs    - Show EFM logs from containers"

# Build Docker images
build:
	@echo "Building Docker images..."
	docker-compose build --no-cache

# Start the environment
up:
	@echo "Starting EFM test environment..."
	docker-compose up -d
	@echo "Waiting 60 seconds for initialization..."
	@sleep 60
	@echo "Environment ready! Use 'make status' to check cluster status."

# Stop the environment
down:
	@echo "Stopping EFM test environment..."
	docker-compose down

# Show logs
logs:
	@echo "Showing container logs (press Ctrl+C to exit)..."
	docker-compose logs -f

# Show cluster status
status:
	@echo "Checking cluster status..."
	@./scripts/monitor-cluster.sh

# Monitor cluster continuously
monitor:
	@echo "Starting continuous cluster monitoring..."
	@./scripts/monitor-cluster.sh --continuous

# Test automatic failover
test-failover:
	@echo "Running automatic failover test..."
	@./scripts/test-failover.sh

# Test manual switchover
test-switchover:
	@echo "Running manual switchover test..."
	@./scripts/test-switchover.sh

# Reset cluster
reset:
	@echo "Resetting cluster..."
	@./scripts/reset-cluster.sh

# Clean up everything
clean:
	@echo "Cleaning up Docker resources..."
	docker-compose down -v
	docker image prune -f
	docker volume prune -f
	@echo "Cleanup complete."

# Quick start (build and run)
start: build up

# Log management commands
view-logs:
	@echo "Opening interactive log viewer..."
	@./scripts/view-logs.sh

analyze-logs:
	@echo "Opening log analyzer..."
	@./scripts/analyze-logs.sh

export-logs:
	@echo "Exporting logs..."
	@./scripts/export-logs.sh

export-logs-archive:
	@echo "Exporting and archiving logs..."
	@./scripts/export-logs.sh --archive

# Debug EFM package availability
debug-packages:
	@echo "Checking EFM package availability..."
	@./scripts/debug-efm-packages.sh

# Show EFM logs from containers (legacy command)
efm-logs:
	@echo "EFM logs from containers (use 'make view-logs' for local logs):"
	@echo "=== Primary EFM Logs ==="
	@docker exec pg-primary tail -20 /var/log/efm-5.0/efm-5.0.log 2>/dev/null || echo "Primary logs not available"
	@echo "=== Standby EFM Logs ==="
	@docker exec pg-standby tail -20 /var/log/efm-5.0/efm-5.0.log 2>/dev/null || echo "Standby logs not available"
	@echo "=== Witness EFM Logs ==="
	@docker exec efm-witness tail -20 /var/log/efm-5.0/efm-5.0.log 2>/dev/null || echo "Witness logs not available"