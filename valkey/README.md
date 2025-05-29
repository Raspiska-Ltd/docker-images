# Custom Valkey Docker Image by Raspiska Tech

This Docker image extends the official Valkey image with enhanced persistence, Redis Sentinel for high availability, monitoring capabilities, and security features.

## Features

- **Persistence**: Configured with both RDB and AOF persistence for reliable data storage
- **High Availability**: Redis Sentinel for monitoring, automatic failover, and client notifications
- **Memory Management**: Configurable memory limits with LRU eviction policy
- **Security**: Password authentication enabled by default
- **Monitoring**: Includes tools for monitoring Valkey performance and health
- **Networking**: Custom hostname configuration and port exposure
- **Health Checks**: Automated container health monitoring

## What is Valkey?

Valkey is a Redis-compatible database that offers enhanced performance and features. It's fully compatible with Redis clients and tools while providing additional improvements. This container allows you to use Valkey as a drop-in replacement for Redis in your infrastructure.

## Version Information

- Valkey: Latest version from official image
- Based on: valkey/valkey:latest

## Usage

### Using Docker Compose (Recommended)

1. Configure the environment variables in the `.env` file:

   ```bash
   VALKEY_PASSWORD=secure_valkey_password
   VALKEY_MAX_MEMORY=256mb
   VALKEY_MAX_CLIENTS=10000

   VALKEY_SENTINEL_NAME=mymaster
   VALKEY_SENTINEL_QUORUM=2
   VALKEY_SENTINEL_DOWN_AFTER=5000
   VALKEY_SENTINEL_FAILOVER_TIMEOUT=60000
   ```

2. Add the hostname to your local hosts file:

   ```bash
   sudo sh -c 'echo "127.0.0.1 valkey.local" >> /etc/hosts'
   ```

3. Build and start the container:

   ```bash
   ./setup.sh
   ```

   Or manually:

   ```bash
   docker-compose up -d
   ```

4. Connect to Valkey:
   - Host: localhost or valkey.local
   - Port: 6380 (to avoid conflicts with Redis)
   - Password: The value set in .env (default: secure_valkey_password)

### Using Docker Directly

1. Build the image:

   ```bash
   docker build -t raspiska/valkey:latest .
   ```

2. Run the container:

   ```bash
   docker run -d --name raspiska_valkey \
     -p 6380:6379 -p 26380:26379 \
     -e VALKEY_PASSWORD=secure_valkey_password \
     -v valkey_data:/valkey-data \
     raspiska/valkey:latest
   ```

## Redis Sentinel

This container runs Redis Sentinel alongside the Valkey server for high availability and monitoring:

- **Port**: 26379 (exposed as 26380 to host)
- **Master Name**: mymaster (configurable)
- **Quorum**: 2 (configurable)
- **Down-after-milliseconds**: 5000 (5 seconds)
- **Failover Timeout**: 60000 (60 seconds)

### Using Sentinel

Connect to Sentinel CLI:

```bash
docker exec -it raspiska_valkey valkey-cli -p 26379
```

Common Sentinel commands:

```bash
# Check Sentinel status
info sentinel

# List monitored masters
sentinel masters

# Get master details
sentinel master mymaster

# Get slaves of a master
sentinel slaves mymaster

# Get Sentinel instances
sentinel sentinels mymaster
```

### Connecting to Valkey using Sentinel

In your application, you can use Sentinel for service discovery and automatic failover:

```python
from redis.sentinel import Sentinel

sentinel = Sentinel([('valkey.local', 26380)], socket_timeout=0.1)
master = sentinel.master_for('${VALKEY_SENTINEL_NAME}', socket_timeout=0.1, password='your_password')
master.set('foo', 'bar')
```

## Persistence Configuration

This Valkey instance is configured with both AOF and RDB persistence:

- **AOF (Append Only File)**: Enabled with `appendfsync everysec` for a good balance between performance and durability
- **RDB (Redis Database Backup)**: Configured to save snapshots at these intervals:
  - After 900 seconds (15 minutes) if at least 1 key changed
  - After 300 seconds (5 minutes) if at least 10 keys changed
  - After 60 seconds (1 minute) if at least 10000 keys changed

## Memory Management

- Default memory limit: 256MB (configurable via .env)
- Eviction policy: allkeys-lru (Least Recently Used)
- Memory samples: 5

## Monitoring

To monitor your Valkey instance:

```bash
# Connect to Valkey CLI
docker exec -it raspiska_valkey valkey-cli -a your_password

# Check server information
INFO server

# Check memory usage
INFO memory

# Monitor commands in real-time
MONITOR

# Check slow log
SLOWLOG GET 10
```

## Security

- Protected mode is enabled
- Password authentication is required
- Network binding is limited to necessary interfaces

## Data Volume

Valkey data is persisted in a Docker volume named `raspiska_valkey_data` which survives container restarts and removals.

## Health Check

The container includes a health check that verifies Valkey is running properly every 30 seconds.

## Differences from Redis

Valkey is a Redis-compatible database with some enhancements:

- Performance improvements
- Additional features
- Fully compatible with Redis clients and tools

This container is configured to work as a drop-in replacement for Redis in your infrastructure, with the ports changed to avoid conflicts (6380 instead of 6379, and 26380 instead of 26379).
