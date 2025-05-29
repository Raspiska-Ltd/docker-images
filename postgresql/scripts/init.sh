#!/bin/bash

# PostgreSQL Initialization Script
# This script initializes the PostgreSQL database with custom users and extensions

set -e

# Create application database and user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create application user with password from environment variable
    CREATE USER app_user WITH PASSWORD '$APP_USER_PASSWORD';
    
    -- Create application database
    CREATE DATABASE app_db;
    
    -- Grant privileges to application user
    GRANT ALL PRIVILEGES ON DATABASE app_db TO app_user;
    
    -- Connect to application database
    \c app_db
    
    -- Create extensions
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "btree_gin";
    CREATE EXTENSION IF NOT EXISTS "btree_gist";
    
    -- Create schema for application
    CREATE SCHEMA app;
    
    -- Grant privileges on schema to application user
    GRANT ALL ON SCHEMA app TO app_user;
    
    -- Set search path
    ALTER DATABASE app_db SET search_path TO app, public;
EOSQL

# Create monitoring user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create monitoring user with password from environment variable
    CREATE USER monitoring WITH PASSWORD '$MONITORING_PASSWORD';
    
    -- Grant read-only privileges to monitoring user
    GRANT pg_monitor TO monitoring;
EOSQL

# Create replication user if replication is enabled
if [ "$ENABLE_REPLICATION" = "true" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        -- Create replication user with password from environment variable
        CREATE USER replicator WITH REPLICATION PASSWORD '$REPLICATION_PASSWORD';
    EOSQL
fi

# Setup backup cron job
if [ "$ENABLE_BACKUPS" = "true" ]; then
    # Add cron job for daily backups at 2 AM
    echo "0 2 * * * /var/lib/postgresql/scripts/backup.sh >> /var/lib/postgresql/backups/cron.log 2>&1" > /var/spool/cron/crontabs/postgres
    chmod 600 /var/spool/cron/crontabs/postgres
fi

echo "PostgreSQL initialization completed successfully"
