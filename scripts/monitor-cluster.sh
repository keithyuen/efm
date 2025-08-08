#!/bin/bash
# Script to monitor EFM cluster status and replication health

echo "=== EFM Cluster Monitoring Script ==="
echo ""

# Function to display cluster status
show_cluster_status() {
    echo "╔════════════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                    EFM CLUSTER STATUS                                  ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "--- Primary Node Status ---"
    docker exec pg-primary /usr/edb/efm-5.0/bin/efm cluster-status efm_cluster 2>/dev/null || echo "❌ Primary node unreachable"
    echo ""
    
    echo "--- Standby Node Status ---"
    docker exec pg-standby /usr/edb/efm-5.0/bin/efm cluster-status efm_cluster 2>/dev/null || echo "❌ Standby node unreachable"
    echo ""
    
    echo "--- Witness Node Status ---"
    docker exec efm-witness /usr/edb/efm-5.0/bin/efm cluster-status efm_cluster 2>/dev/null || echo "❌ Witness node unreachable"
    echo ""
}

# Function to check replication status
show_replication_status() {
    echo "╔════════════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                 REPLICATION STATUS                                     ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "--- Replication from Primary ---"
    docker exec pg-primary psql -U postgres -c "
        SELECT 
            'Primary -> ' || COALESCE(client_addr::text, 'N/A') AS connection,
            application_name,
            state,
            CASE 
                WHEN pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn) < 1024 THEN '✅ < 1KB'
                WHEN pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn) < 1048576 THEN '⚠️ ' || pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn)::bigint)
                ELSE '❌ ' || pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn)::bigint)
            END AS replication_lag
        FROM pg_stat_replication;
    " 2>/dev/null || echo "❌ Could not get replication status from primary"
    echo ""
    
    echo "--- Recovery Status on Standby ---"
    docker exec pg-standby psql -U postgres -c "
        SELECT 
            CASE pg_is_in_recovery() 
                WHEN true THEN '✅ In recovery mode (standby)' 
                ELSE '⚠️ NOT in recovery mode (may be promoted)' 
            END AS recovery_status;
    " 2>/dev/null || echo "❌ Could not get recovery status from standby"
    echo ""
}

# Function to show database connectivity
show_database_status() {
    echo "╔════════════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                 DATABASE CONNECTIVITY                                 ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "--- Primary Database ---"
    if docker exec pg-primary pg_isready -U postgres -h localhost >/dev/null 2>&1; then
        echo "✅ Primary database is accepting connections"
        docker exec pg-primary psql -U postgres -c "SELECT 'Primary DB: ' || version();" 2>/dev/null | grep "Primary DB:"
    else
        echo "❌ Primary database is not accepting connections"
    fi
    echo ""
    
    echo "--- Standby Database ---"
    if docker exec pg-standby pg_isready -U postgres -h localhost >/dev/null 2>&1; then
        echo "✅ Standby database is accepting connections"
        docker exec pg-standby psql -U postgres -c "SELECT 'Standby DB: ' || version();" 2>/dev/null | grep "Standby DB:"
    else
        echo "❌ Standby database is not accepting connections"
    fi
    echo ""
}

# Function to show recent test data
show_test_data() {
    echo "╔════════════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                    TEST DATA                                           ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "--- Recent test_replication entries ---"
    docker exec pg-primary psql -U postgres -d testdb -c "SELECT id, message, created_at FROM test_replication ORDER BY created_at DESC LIMIT 3;" 2>/dev/null || {
        echo "Trying standby database..."
        docker exec pg-standby psql -U postgres -d testdb -c "SELECT id, message, created_at FROM test_replication ORDER BY created_at DESC LIMIT 3;" 2>/dev/null || echo "❌ Could not retrieve test data"
    }
    echo ""
}

# Function for continuous monitoring
continuous_monitor() {
    echo "Starting continuous monitoring (press Ctrl+C to stop)..."
    echo ""
    
    while true; do
        clear
        echo "EFM Cluster Monitor - $(date)"
        echo ""
        show_cluster_status
        show_replication_status
        show_database_status
        show_test_data
        
        echo "Next update in 30 seconds..."
        sleep 30
    done
}

# Main script logic
if [[ "$1" == "--continuous" || "$1" == "-c" ]]; then
    continuous_monitor
else
    echo "Single snapshot monitoring:"
    echo ""
    show_cluster_status
    show_replication_status
    show_database_status
    show_test_data
    
    echo "╔════════════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                     USAGE                                             ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════════════╝"
    echo "Run with --continuous or -c for continuous monitoring"
    echo "Available test scripts:"
    echo "  ./scripts/test-failover.sh    - Test automatic failover"
    echo "  ./scripts/test-switchover.sh  - Test manual switchover"
    echo ""
fi