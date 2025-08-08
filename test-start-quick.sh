#!/bin/bash
# Quick test version of start.sh without the 90-second wait

set -e

echo "🚀 EDB EFM Test Environment Setup (QUICK TEST)"
echo "=============================================="
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

# Wait for basic initialization (reduced time for testing)
echo "⏳ Waiting for services to initialize (30 seconds)..."
for i in {30..1}; do
    echo -ne "⏱️  Initialization in progress: $i seconds remaining...\r"
    sleep 1
done
echo ""

# Check container status
echo "🔍 Checking container status..."
docker-compose ps

# Check logs for obvious errors
echo "📋 Checking logs for errors..."
echo "--- Primary Logs (last 5 lines) ---"
docker-compose logs --tail=5 pg-primary

echo "--- Standby Logs (last 5 lines) ---"
docker-compose logs --tail=5 pg-standby

echo "--- Witness Logs (last 5 lines) ---"  
docker-compose logs --tail=5 efm-witness

echo ""
echo "✅ Quick test complete!"
echo "Use 'docker-compose logs [service]' to see full logs"
echo "Use 'docker-compose down' to stop the environment"