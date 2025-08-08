#!/bin/bash
# Quick restart script to test the fixes

set -e

echo "🔄 Restarting EFM environment to test fixes..."
echo ""

# Stop current environment
echo "🛑 Stopping containers..."
docker-compose down

# Start environment 
echo "▶️  Starting EFM environment with fixes..."
docker-compose up -d

# Wait for initialization
echo "⏳ Waiting 45 seconds for initialization..."
for i in {45..1}; do
    echo -ne "⏱️  Initialization in progress: $i seconds remaining...\r"
    sleep 1
done
echo ""

# Check container status
echo "📋 Container Status:"
docker-compose ps

echo ""
echo "🔍 Checking for errors in logs..."

echo "--- Primary Container (last 10 lines) ---"
docker-compose logs --tail=10 pg-primary

echo ""
echo "--- Standby Container (last 10 lines) ---"
docker-compose logs --tail=10 pg-standby

echo ""
echo "--- Witness Container (last 10 lines) ---"
docker-compose logs --tail=10 efm-witness

echo ""
echo "✅ Restart test complete!"
echo ""
echo "To check EFM cluster status:"
echo "  ./scripts/monitor-cluster.sh"
echo ""
echo "To see full logs:"
echo "  docker-compose logs [pg-primary|pg-standby|efm-witness]"