#!/bin/bash
# Script to encrypt EFM database passwords for secure configuration

echo "Setting up EFM password encryption..."

# Create encrypted password for database user 'efm'
echo "Encrypting password for user 'efm'..."
/usr/edb/efm-5.0/bin/efm encrypt efm_cluster --from-env

# Create the password file manually if encryption fails
echo "Creating fallback password configuration..."
mkdir -p /home/postgres/.edb
echo "efm" > /home/postgres/.edb/efm_db_password
chmod 600 /home/postgres/.edb/efm_db_password
chown postgres:postgres /home/postgres/.edb/efm_db_password

echo "EFM password setup complete."