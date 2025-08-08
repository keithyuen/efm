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

# Create EFM monitoring user
echo "Creating EFM monitoring user..."
psql -U postgres -c "
  DO \$\$
  BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'efm') THEN
      CREATE USER efm WITH LOGIN PASSWORD 'efm';
      GRANT CONNECT ON DATABASE postgres TO efm;
      GRANT CONNECT ON DATABASE testdb TO efm;
    END IF;
  END
  \$\$;
"

# Create test database if it doesn't exist
echo "Creating test database..."
psql -U postgres -c "
  SELECT 'CREATE DATABASE testdb'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'testdb')\gexec
"

# Grant necessary permissions to EFM user
echo "Granting permissions to EFM user..."
psql -U postgres -d testdb -c "
  GRANT ALL PRIVILEGES ON DATABASE testdb TO efm;
"

# Create a test table for verification
echo "Creating test table..."
psql -U postgres -d testdb -c "
  CREATE TABLE IF NOT EXISTS test_replication (
    id SERIAL PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
  );
  INSERT INTO test_replication (message) VALUES ('Primary node initialized at $(date)');
"

echo "Primary initialization complete."