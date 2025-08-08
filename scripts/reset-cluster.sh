#!/bin/bash
# Script to reset the EFM cluster to initial state

echo "=== EFM Cluster Reset Script ==="
echo "This script will reset the cluster to its initial state."
echo ""

read -p "Are you sure you want to reset the cluster? This will destroy all data! (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Reset cancelled."
    exit 1
fi

echo "Step 1: Stopping all containers..."
docker-compose down

echo "Step 2: Removing persistent volumes..."
docker volume prune -f

echo "Step 3: Cleaning up any remaining containers..."
docker container prune -f

echo "Step 4: Starting fresh cluster..."
docker-compose up -d

echo "Step 5: Waiting for services to initialize..."
sleep 60

echo "Step 6: Checking cluster status..."
./scripts/monitor-cluster.sh

echo ""
echo "=== Cluster reset complete ==="
echo "The cluster has been reset to its initial state."
echo "- pg-primary: Primary PostgreSQL node"
echo "- pg-standby: Standby PostgreSQL node"  
echo "- efm-witness: EFM witness node"
echo ""
echo "Use ./scripts/monitor-cluster.sh to check status"
echo "Use ./scripts/test-failover.sh to test automatic failover"
echo "Use ./scripts/test-switchover.sh to test manual switchover"