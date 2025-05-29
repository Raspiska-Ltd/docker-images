# Custom PostgreSQL for Raspiska Tech

This Docker setup provides a high-performance PostgreSQL database with custom configuration, connection pooling, and administration tools.

## Features

- **PostgreSQL 15**: Latest stable version with optimized configuration
- **PgBouncer**: Connection pooling for improved performance
- **pgAdmin**: Web-based administration interface
- **Custom Configuration**: Optimized for performance and security
- **Automated Backups**: Daily backups with configurable retention
- **SSL Support**: Secure connections with SSL/TLS
- **Monitoring Integration**: Ready for Prometheus monitoring
- **Traefik Integration**: Automatic routing through Traefik reverse proxy
- **Kong Integration**: API Gateway integration for centralized access
- **User Management**: Separate users for applications, monitoring, and replication

## Quick Start

1. Run the setup script to start PostgreSQL:

   ```bash
   ./setup.sh
   ```

2. Add the following entries to your `/etc/hosts` file:

   ```bash
   sudo sh -c 'echo "127.0.0.1 pgadmin.raspiska.local postgres.raspiska.local" >> /etc/hosts'
   ```

3. Access the services at:
   - PostgreSQL: localhost:5432
   - PgBouncer: localhost:6432
   - pgAdmin: [http://pgadmin.raspiska.local](http://pgadmin.raspiska.local) or [http://localhost:5050](http://localhost:5050)

4. Log in to pgAdmin with the credentials specified in the `.env` file

## Architecture

This PostgreSQL setup includes:

- **PostgreSQL**: Main database server (port 5432)
- **PgBouncer**: Connection pooling service (port 6432)
- **pgAdmin**: Web-based administration interface (port 5050)

## Configuration

The PostgreSQL configuration is optimized for performance and security:

- **Memory Settings**: Optimized shared_buffers, work_mem, and effective_cache_size
- **Connection Settings**: Secure password encryption and SSL support
- **WAL Settings**: Configured for durability and performance
- **Autovacuum Settings**: Tuned for optimal background maintenance
- **Logging**: Comprehensive logging for troubleshooting
- **Security**: Secure client authentication with scram-sha-256

## User Accounts

The setup creates several user accounts:

1. **postgres**: Superuser account for administration
2. **app_user**: Regular user for application access
3. **monitoring**: User with monitoring privileges
4. **replicator**: User with replication privileges (if enabled)

## Database Structure

The setup creates the following databases:

1. **postgres**: System database
2. **app_db**: Application database with the following features:
   - Custom schema: `app`
   - Extensions: uuid-ossp, pg_stat_statements, pgcrypto, btree_gin, btree_gist
   - Proper permissions for the app_user

## Backup and Recovery

The setup includes an automated backup system:

1. **Daily Backups**: Scheduled at 2 AM
2. **Retention Policy**: Configurable retention period (default: 7 days)
3. **Backup Types**:
   - Individual database backups
   - Full system backup

To manually trigger a backup:

```bash
docker exec raspiska_postgres /var/lib/postgresql/scripts/backup.sh
```

## Connection Pooling with PgBouncer

PgBouncer provides connection pooling for improved performance:

- **Transaction Pooling**: Connections are reused after transaction completion
- **Connection Limits**: Configurable maximum connections
- **Pool Size**: Configurable default pool size

To connect through PgBouncer:

```properties
Host: localhost
Port: 6432
User: app_user
Password: [from .env file]
Database: app_db
```

## Administration with pgAdmin

pgAdmin provides a web-based interface for database administration:

1. Access pgAdmin at [http://pgadmin.raspiska.local](http://pgadmin.raspiska.local)
2. Log in with the credentials from the `.env` file
3. Add a new server connection:
   - Host: raspiska_postgres
   - Port: 5432
   - User: postgres
   - Password: [from .env file]

## Monitoring

The PostgreSQL setup is configured for monitoring with Prometheus:

1. **PostgreSQL Exporter**: Collects PostgreSQL metrics
2. **pg_stat_statements**: Tracks query performance
3. **Custom Metrics**: Available through the monitoring user

## Security Considerations

- In production, use strong passwords in the `.env` file
- Enable SSL for all connections
- Regularly update PostgreSQL to the latest version
- Implement network-level security
- Review and restrict pg_hba.conf rules

## Troubleshooting

### PostgreSQL Not Starting

1. Check the container logs:

   ```bash
   docker logs raspiska_postgres
   ```

2. Verify the configuration files:

   ```bash
   docker exec raspiska_postgres cat /var/lib/postgresql/data/pgdata/postgresql.conf
   docker exec raspiska_postgres cat /var/lib/postgresql/data/pgdata/pg_hba.conf
   ```

3. Check if the data directory has proper permissions:

   ```bash
   docker exec raspiska_postgres ls -la /var/lib/postgresql/data
   ```

### Connection Issues

1. Verify PostgreSQL is running:

   ```bash
   docker exec raspiska_postgres pg_isready -U postgres
   ```

2. Check the pg_hba.conf file for connection rules:

   ```bash
   docker exec raspiska_postgres cat /var/lib/postgresql/data/pgdata/pg_hba.conf
   ```

3. Test a connection from within the container:

   ```bash
   docker exec -it raspiska_postgres psql -U postgres
   ```

### Backup Issues

1. Check the backup logs:

   ```bash
   docker exec raspiska_postgres cat /var/lib/postgresql/backups/backup_*.log
   ```

2. Verify backup directory permissions:

   ```bash
   docker exec raspiska_postgres ls -la /var/lib/postgresql/backups
   ```

3. Manually run the backup script:

   ```bash
   docker exec raspiska_postgres /var/lib/postgresql/scripts/backup.sh
   ```

## Upgrading

1. Back up your data:

   ```bash
   docker exec raspiska_postgres /var/lib/postgresql/scripts/backup.sh
   ```

2. Update the image in `docker-compose.yml`
3. Run `docker-compose down && docker-compose up -d`
4. Verify the upgrade was successful
