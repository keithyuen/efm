#!/bin/bash
# Script to perform manual switchover between primary and standby

echo "=== EFM Manual Switchover Test Script ==="
echo "This script will perform a manual switchover from primary to standby."
echo ""

# Function to check EFM cluster status
check_cluster_status() {
    echo "Current EFM cluster status:"
    docker exec pg-primary /usr/edb/efm-5.0/bin/efm cluster-status efm_cluster 2>/dev/null || echo "Primary may be unreachable"
    docker exec pg-standby /usr/edb/efm-5.0/bin/efm cluster-status efm_cluster 2>/dev/null || echo "Standby may be unreachable"
    docker exec efm-witness /usr/edb/efm-5.0/bin/efm cluster-status efm_cluster 2>/dev/null || echo "Witness may be unreachable"
    echo ""
}

# Function to check replication lag
check_replication_lag() {
    echo "Checking replication lag:"
    docker exec pg-primary psql -U postgres -c "
        SELECT 
            client_addr,
            application_name,
            state,
            pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn) AS lag_bytes
        FROM pg_stat_replication;
    " 2>/dev/null || echo "Could not check replication status"
    echo ""
}

echo "Step 1: Check initial cluster status"
check_cluster_status
check_replication_lag

echo "Step 2: Insert test data before switchover"
docker exec pg-primary psql -U postgres -d testdb -c "INSERT INTO test_replication (message) VALUES ('Before manual switchover at $(date)');" 2>/dev/null || echo "Could not insert test data"

echo "Step 3: Wait for replication to catch up"
sleep 5

echo "Step 4: Perform manual switchover"
echo "Promoting standby to primary..."
docker exec pg-standby /usr/edb/efm-5.0/bin/efm promote efm_cluster -switchover

echo "Waiting 20 seconds for switchover to complete..."
sleep 20

echo "Step 5: Check cluster status after switchover"
check_cluster_status

echo "Step 6: Verify new primary can accept writes"
echo "Writing to new primary (former standby):"
docker exec pg-standby psql -U postgres -d testdb -c "INSERT INTO test_replication (message) VALUES ('After manual switchover at $(date)');" 2>/dev/null || echo "Write test failed"

echo "Step 7: Verify old primary is now standby"
echo "Checking if old primary is in recovery mode:"
docker exec pg-primary psql -U postgres -c "SELECT pg_is_in_recovery();" 2>/dev/null || echo "Old primary status unknown"

echo "Step 8: Show test data to verify switchover worked"
docker exec pg-standby psql -U postgres -d testdb -c "SELECT * FROM test_replication ORDER BY created_at DESC LIMIT 5;" 2>/dev/null || echo "Could not read test data"

echo ""
echo "=== Manual switchover test complete ==="
echo "Note: The roles have now switched - pg-standby container is now the primary!"
echo "Check the EFM logs for detailed switchover information:"
echo "docker exec pg-primary tail -f /var/log/efm-5.0/efm-5.0.log"
echo "docker exec pg-standby tail -f /var/log/efm-5.0/efm-5.0.log"
echo "docker exec efm-witness tail -f /var/log/efm-5.0/efm-5.0.log"