#!/bin/bash
# Script to simulate primary database failure for testing automatic failover

echo "=== EFM Failover Test Script ==="
echo "This script will simulate a primary database failure to test automatic failover."
echo ""

# Function to check EFM cluster status
check_cluster_status() {
    echo "Current EFM cluster status:"
    docker exec pg-primary /usr/edb/efm-5.0/bin/efm cluster-status efm_cluster 2>/dev/null || echo "Primary may be down"
    docker exec pg-standby /usr/edb/efm-5.0/bin/efm cluster-status efm_cluster 2>/dev/null || echo "Standby status unavailable"
    docker exec efm-witness /usr/edb/efm-5.0/bin/efm cluster-status efm_cluster 2>/dev/null || echo "Witness status unavailable"
    echo ""
}

# Function to check replication status
check_replication() {
    echo "Checking replication status:"
    echo "--- Primary ---"
    docker exec pg-primary psql -U postgres -c "SELECT client_addr, state FROM pg_stat_replication;" 2>/dev/null || echo "Primary may be down"
    echo "--- Standby ---"
    docker exec pg-standby psql -U postgres -c "SELECT pg_is_in_recovery();" 2>/dev/null || echo "Standby may be down"
    echo ""
}

echo "Step 1: Check initial cluster status"
check_cluster_status
check_replication

echo "Step 2: Insert test data on primary"
docker exec pg-primary psql -U postgres -d testdb -c "INSERT INTO test_replication (message) VALUES ('Before failover test at $(date)');" 2>/dev/null || echo "Could not insert test data"

echo "Step 3: Simulate primary database crash"
echo "Stopping PostgreSQL service on primary node..."
docker exec pg-primary pkill -f postgres || echo "PostgreSQL may already be stopped"

echo "Waiting 30 seconds for EFM to detect failure and perform failover..."
sleep 30

echo "Step 4: Check cluster status after simulated failure"
check_cluster_status

echo "Step 5: Verify new primary can accept writes"
echo "Attempting to write to new primary (should be the former standby):"
docker exec pg-standby psql -U postgres -d testdb -c "INSERT INTO test_replication (message) VALUES ('After failover test at $(date)');" 2>/dev/null || echo "Write test failed"

echo "Step 6: Show test data to verify replication worked"
docker exec pg-standby psql -U postgres -d testdb -c "SELECT * FROM test_replication ORDER BY created_at DESC LIMIT 5;" 2>/dev/null || echo "Could not read test data"

echo ""
echo "=== Failover test complete ==="
echo "Check the EFM logs for detailed failover information:"
echo "docker exec pg-standby tail -f /var/log/efm-5.0/efm-5.0.log"
echo "docker exec efm-witness tail -f /var/log/efm-5.0/efm-5.0.log"