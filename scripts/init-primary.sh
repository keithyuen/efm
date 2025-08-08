#!/bin/bash
# Initialize PostgreSQL Primary for EFM

set -e

echo "Initializing PostgreSQL Primary for EFM..."

# Wait for PostgreSQL to be ready
until pg_isready -U postgres -h localhost; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

# Create replication user
echo "Creating replication user..."
psql -U postgres -c "
  DO \$\$
  BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'replicator') THEN
      CREATE USER replicator WITH REPLICATION LOGIN PASSWORD 'replicator';
    END IF;
  END
  \$\$;
"

# # Create EFM monitoring user
# echo "Creating EFM monitoring user..."
# psql -U postgres -c "
#   DO \$\$
#   BEGIN
#     IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'efm') THEN
#       CREATE USER efm WITH LOGIN PASSWORD 'efm';
#       GRANT CONNECT ON DATABASE postgres TO efm;
#     END IF;
#   END
#   \$\$;
# "

# # Grant necessary permissions to EFM user
# echo "Granting permissions to EFM user..."
# psql -U postgres -d postgres -c "
#   GRANT ALL PRIVILEGES ON DATABASE postgres TO efm;
# "

# # Grant EFM monitoring roles and permissions
# echo "Granting EFM monitoring roles and permissions..."
# psql -U postgres -c "
#   -- Grant required roles for EFM monitoring
#   GRANT pg_read_all_settings TO efm;
#   GRANT pg_read_all_stats TO efm;
#   GRANT pg_monitor TO efm;
#   -- Grant specific permissions for WAL replay functions
#   GRANT EXECUTE ON FUNCTION pg_wal_replay_pause() TO efm;
#   GRANT EXECUTE ON FUNCTION pg_wal_replay_resume() TO efm;
#   GRANT EXECUTE ON FUNCTION pg_reload_conf() TO efm;
#   -- Additional monitoring permissions
#   GRANT EXECUTE ON FUNCTION pg_is_in_recovery() TO efm;
#   GRANT EXECUTE ON FUNCTION pg_last_wal_receive_lsn() TO efm;
#   GRANT EXECUTE ON FUNCTION pg_last_wal_replay_lsn() TO efm;
# "

# Create a test table for verification
echo "Creating test table..."
psql -U postgres -d postgres -c "
  CREATE TABLE IF NOT EXISTS test_replication (
    id SERIAL PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
  );
  INSERT INTO test_replication (message) VALUES ('Primary node initialized at $(date)');
"

echo "Primary initialization complete."