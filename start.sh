#!/bin/bash
# Quick start script for EFM test environment

set -e

echo "🚀 EDB EFM Test Environment Setup"
echo "=================================="
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose >/dev/null 2>&1; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Make scripts executable
echo "📝 Making scripts executable..."
chmod +x scripts/*.sh

# Build images
echo "🔨 Building Docker images..."
docker-compose build

# Start environment
echo "▶️  Starting EFM test environment..."
docker-compose up -d

# Wait for initialization
echo "⏳ Waiting for services to initialize (90 seconds)..."
for i in {90..1}; do
    echo -ne "⏱️  Initialization in progress: $i seconds remaining...\r"
    sleep 1
done
echo ""

# Check status
echo "🔍 Checking cluster status..."
./scripts/monitor-cluster.sh

echo ""
echo "✅ EFM Test Environment is ready!"
echo ""
echo "📚 Quick Commands:"
echo ""
echo "  Monitoring & Testing:"
echo "    ./scripts/monitor-cluster.sh     - Check cluster status"
echo "    ./scripts/monitor-cluster.sh -c - Continuous monitoring"
echo "    ./scripts/test-failover.sh       - Test automatic failover"
echo "    ./scripts/test-switchover.sh     - Test manual switchover"
echo "    ./scripts/reset-cluster.sh       - Reset to initial state"
echo ""
echo "  Log Management:"
echo "    ./scripts/view-logs.sh           - Interactive log viewer"
echo "    ./scripts/analyze-logs.sh        - Analyze logs for issues"
echo "    ./scripts/export-logs.sh         - Export logs for analysis"
echo "    ls logs/                         - Browse logs directory"
echo ""
echo "🔗 Database Connections:"
echo "  Primary:  psql -h localhost -p 5432 -U postgres"
echo "  Standby:  psql -h localhost -p 5433 -U postgres"
echo ""
echo "📊 EFM Web Interfaces:"
echo "  Primary EFM:  http://localhost:7800"
echo "  Standby EFM:  http://localhost:7801" 
echo "  Witness EFM:  http://localhost:7802"
echo ""
echo "📖 See README.md for detailed documentation."