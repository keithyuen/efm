# EDB EFM (EnterpriseDB Failover Manager) Docker Test Environment

A complete Docker Compose setup for testing EDB EFM with PostgreSQL v17, featuring automatic failover and manual switchover capabilities.

## 🏗️ Architecture

This environment consists of three containers:

1. **pg-primary**: PostgreSQL v17 Primary with EFM
2. **pg-standby**: PostgreSQL v17 Standby with streaming replication and EFM
3. **efm-witness**: EFM Witness node (no PostgreSQL)

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   pg-primary    │    │   pg-standby    │    │  efm-witness    │
│                 │    │                 │    │                 │
│ PostgreSQL v17  │────│ PostgreSQL v17  │    │   EFM Only      │
│ EFM Primary     │    │ EFM Standby     │    │ EFM Witness     │
│ 172.20.0.10     │    │ 172.20.0.11     │    │ 172.20.0.12     │
│ Port: 5432      │    │ Port: 5432      │    │ Port: 7800      │
│ EFM Port: 7800  │    │ EFM Port: 7800  │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 2GB RAM available for the containers
- Ports 5432, 5433, 7800, 7801, 7802 available on host

### 1. Clone and Setup

```bash
gh repo clone keithyuen/efm
cd efm
```

### 2. Make scripts executable

```bash
chmod +x scripts/*.sh
```

### 3. Start the environment

```bash
docker-compose up -d
```

### 4. Wait for initialization (about 2 minutes)

```bash
# Monitor the startup process
docker-compose logs -f
```

### 5. Verify cluster status

```bash
./scripts/monitor-cluster.sh
```

## 📋 Container Details

### Primary Node (pg-primary)
- **IP**: 172.20.0.10
- **PostgreSQL Port**: 5432 (host: 5432)
- **EFM Port**: 7800 (host: 7800)
- **Role**: Primary database with EFM agent

### Standby Node (pg-standby)
- **IP**: 172.20.0.11  
- **PostgreSQL Port**: 5432 (host: 5433)
- **EFM Port**: 7800 (host: 7801)
- **Role**: Hot standby with streaming replication

### Witness Node (efm-witness)
- **IP**: 172.20.0.12
- **EFM Port**: 7800 (host: 7802)
- **Role**: EFM witness for quorum decisions

## 🔧 Configuration Files

### PostgreSQL Configuration
- `config/postgresql-primary.conf` - Primary node settings
- `config/postgresql-standby.conf` - Standby node settings
- `config/pg_hba.conf` - Authentication settings for both nodes

### EFM Configuration
- `config/efm-primary.properties` - Primary EFM agent settings
- `config/efm-standby.properties` - Standby EFM agent settings  
- `config/efm-witness.properties` - Witness EFM agent settings

**Key EFM Settings:**
- `bind.address`: EFM cluster communication (port 7800)
- `admin.port`: Administration server port (7809) for cluster-status commands
- `node.priority`: Node priority for failover decisions (100=primary, 50=standby, 1=witness)

## 🧪 Testing Scripts

### Monitor Cluster Status
```bash
./scripts/monitor-cluster.sh           # Single check
./scripts/monitor-cluster.sh -c        # Continuous monitoring
```

### Test Automatic Failover
```bash
./scripts/test-failover.sh
```
This script will:
1. Check initial cluster status
2. Insert test data on primary
3. Simulate primary database crash
4. Wait for EFM to detect and perform automatic failover
5. Verify the standby has been promoted
6. Test write operations on new primary

### Test Manual Switchover
```bash
./scripts/test-switchover.sh
```
This script will:
1. Check initial cluster status and replication lag
2. Insert test data and wait for replication
3. Perform graceful manual switchover
4. Verify role switch completed successfully
5. Test write operations on new primary

### Reset Cluster
```bash
./scripts/reset-cluster.sh
```
Completely resets the cluster to initial state (destroys all data).

## 📄 Log Management

All PostgreSQL and EFM logs are automatically exported to local directories for easy access and analysis.

### Log Directory Structure
```
logs/
├── pg-primary/
│   ├── postgresql/     # PostgreSQL logs from primary
│   └── efm/           # EFM logs from primary
├── pg-standby/
│   ├── postgresql/     # PostgreSQL logs from standby
│   └── efm/           # EFM logs from standby
└── efm-witness/
    └── efm/           # EFM logs from witness
```

### Interactive Log Viewer
```bash
./scripts/view-logs.sh
```
Interactive menu to:
- View logs from specific nodes
- View all logs by type (PostgreSQL/EFM)
- Live tail all logs
- Check log file sizes

### Log Export and Archiving
```bash
./scripts/export-logs.sh                    # Export logs to ./exported-logs/
./scripts/export-logs.sh --archive          # Create compressed archive
./scripts/export-logs.sh --dir /path/to/dir # Export to custom directory
./scripts/export-logs.sh --clean            # Clean old exports
```

### Log Analysis
```bash
./scripts/analyze-logs.sh                   # Interactive analysis menu
./scripts/analyze-logs.sh --full            # Generate full analysis report
./scripts/analyze-logs.sh --search "error"  # Search for specific patterns
```
Analyze logs for:
- Failover and switchover events
- Cluster membership changes
- Replication issues
- Errors and warnings
- Log statistics

### Direct Log Access
All logs are also available directly in the `./logs/` directory:
```bash
# View latest PostgreSQL logs
tail -f logs/pg-primary/postgresql/*.log

# View latest EFM logs
tail -f logs/pg-primary/efm/*.log

# Search all logs
grep -r "error" logs/

# View log sizes
du -sh logs/*/
```

## 🔍 Monitoring and Troubleshooting

### Check EFM Status
```bash
# Check cluster status from any node
docker exec pg-primary /usr/edb/efm-5.0/bin/efm cluster-status efm_cluster
docker exec pg-standby /usr/edb/efm-5.0/bin/efm cluster-status efm_cluster
docker exec efm-witness /usr/edb/efm-5.0/bin/efm cluster-status efm_cluster
```

### View Logs (Container Access)
```bash
# EFM logs from containers (alternative to local logs)
docker exec pg-primary tail -f /var/log/efm-5.0/efm-5.0.log
docker exec pg-standby tail -f /var/log/efm-5.0/efm-5.0.log
docker exec efm-witness tail -f /var/log/efm-5.0/efm-5.0.log

# PostgreSQL logs from containers
docker exec pg-primary tail -f /var/log/postgresql/postgresql-*.log
docker exec pg-standby tail -f /var/log/postgresql/postgresql-*.log

# Note: Logs are also available locally in ./logs/ directory
# Use ./scripts/view-logs.sh for easier log access
```

### Check Replication Status
```bash
# From primary
docker exec pg-primary psql -U postgres -c "SELECT * FROM pg_stat_replication;"

# From standby
docker exec pg-standby psql -U postgres -c "SELECT pg_is_in_recovery();"
```

### Connect to Databases
```bash
# Connect to primary
docker exec -it pg-primary psql -U postgres

# Connect to standby (read-only)
docker exec -it pg-standby psql -U postgres

# Connect from host
psql -h localhost -p 5432 -U postgres    # Primary
psql -h localhost -p 5433 -U postgres    # Standby
```

## 🔐 Authentication Details

### Database Users
- **postgres**: Superuser (password: postgres)
- **replicator**: Replication user (password: replicator)
- **efm**: EFM monitoring user (password: efm)

### Test Database
- **Database**: testdb
- **Test Table**: test_replication

## 🐛 Common Issues and Solutions

### 1. EFM Agents Not Starting
**Problem**: EFM services fail to start or join cluster

**Solution**: Check that all nodes can communicate:
```bash
# Test network connectivity
docker exec pg-primary ping pg-standby
docker exec pg-primary ping efm-witness

# Check EFM configuration
docker exec pg-primary cat /etc/edb/efm-5.0/efm_cluster.properties
```

### 2. Replication Not Working  
**Problem**: Standby not receiving updates from primary

**Solution**: Check replication setup:
```bash
# Verify replication user exists
docker exec pg-primary psql -U postgres -c "\du replicator"

# Check pg_hba.conf allows replication
docker exec pg-primary cat /var/lib/postgresql/data/pg_hba.conf | grep replication

# Verify standby connection
docker exec pg-standby psql -h pg-primary -U replicator -c "SELECT 1"
```

### 3. Failover Not Triggering
**Problem**: Automatic failover doesn't occur when primary fails

**Solution**: 
1. Ensure witness node is running and connected
2. Check EFM timeout settings in properties files
3. Verify majority nodes are available for quorum
4. Check EFM logs for error messages

### 4. Cannot Connect to Database
**Problem**: Database connections are refused

**Solution**:
```bash
# Check if PostgreSQL is running
docker exec pg-primary pg_isready -U postgres

# Check container status
docker-compose ps

# Restart if needed
docker-compose restart pg-primary
```

### 5. EFM Package Installation Failed
**Problem**: `E: Unable to locate package edb-efm50` during Docker build

**Solutions**:
1. **Use Debian 12** (recommended - already configured):
   ```bash
   # Dockerfile.efm-witness now uses debian:12
   docker-compose build --no-cache
   ```

2. **Debug package availability**:
   ```bash
   ./scripts/debug-efm-packages.sh
   ```

3. **Manual package verification**:
   ```bash
   # Check available EFM versions in container
   docker run --rm debian:12 bash -c "
     apt-get update && apt-get install -y curl gnupg2 ca-certificates
     curl -1sSLf 'https://downloads.enterprisedb.com/a42f0873c732be6edafe2e22849eb0ff/enterprise/setup.deb.sh' | bash
     apt-get update && apt-cache search edb-efm
   "
   ```

**Common causes**:
- Using wrong repository URL (must use enterprise repository)
- Missing ca-certificates or apt-transport-https packages
- ARM64 architecture may have limited package availability
- Repository might not support the specific OS/architecture combination

**Note**: The `efm` user is created automatically during EFM installation, no manual user creation needed.

## 📊 Performance Tuning

### PostgreSQL Settings
Key settings in `postgresql.conf` that can be tuned:
- `shared_buffers`: Memory for shared buffer pool
- `max_connections`: Maximum concurrent connections
- `wal_keep_size`: WAL segments to keep for replication
- `checkpoint_completion_target`: Checkpoint timing

### EFM Settings
Key settings in `efm.properties` files:
- `local.period`: Local monitoring frequency
- `remote.period`: Remote monitoring frequency  
- `node.timeout`: Node failure detection timeout
- `node.priority`: Node priority for promotion decisions

## 🔄 Advanced Operations

### Manual EFM Commands
```bash
# Stop EFM on a node
docker exec pg-primary /usr/edb/efm-5.0/bin/runefm.sh stop efm_cluster

# Start EFM on a node  
docker exec pg-primary /usr/edb/efm-5.0/bin/runefm.sh start efm_cluster

# Promote standby manually
docker exec pg-standby /usr/edb/efm-5.0/bin/efm promote efm_cluster

# Graceful switchover
docker exec pg-standby /usr/edb/efm-5.0/bin/efm promote efm_cluster -switchover
```

### Adding New Standby
To add another standby node:
1. Create new container with EFM configuration
2. Use `pg_basebackup` to create replica
3. Configure EFM properties with unique IP
4. Join cluster using EFM commands

## 📚 Additional Resources

- [EDB Failover Manager Documentation](https://www.enterprisedb.com/docs/efm/latest/)
- [PostgreSQL Streaming Replication](https://www.postgresql.org/docs/17/warm-standby.html#STREAMING-REPLICATION)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 🤝 Contributing

This test environment can be extended with:
- Additional monitoring tools (Grafana, Prometheus)
- More complex network topologies
- Integration with external load balancers
- Custom failover scripts
- Performance benchmarking tools

## 📝 License

This project is provided as-is for testing and educational purposes.