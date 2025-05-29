# Custom Redis Docker Image by Raspiska Tech

This Docker image extends the official Redis Alpine image with enhanced persistence, Redis Sentinel for high availability, monitoring capabilities, and security features.

## Features

- **Persistence**: Configured with both RDB and AOF persistence for reliable data storage
- **High Availability**: Redis Sentinel for monitoring, automatic failover, and client notifications
- **Memory Management**: Configurable memory limits with LRU eviction policy
- **Security**: Password authentication enabled by default
- **Monitoring**: Includes tools for monitoring Redis performance and health
- **Networking**: Custom hostname configuration and port exposure
- **Health Checks**: Automated container health monitoring

## Version Information

- Redis Version: 7.x (Based on redis:7-alpine)
- Alpine Linux: Latest

## Usage

### Using Docker Compose (Recommended)

1. Configure the environment variables in the `.env` file:

   ```bash
   REDIS_PASSWORD=secure_redis_password
   REDIS_MAX_MEMORY=256mb
   REDIS_MAX_CLIENTS=10000
   ```

2. Add the hostname to your local hosts file:

   ```bash
   sudo sh -c 'echo "127.0.0.1 redis.local" >> /etc/hosts'
   ```

3. Build and start the container:

   ```bash
   ./setup.sh
   ```

   Or manually:

   ```bash
   docker-compose up -d
   ```

4. Connect to Redis:
   - Host: localhost or redis.local
   - Port: 6379
   - Password: The value set in .env (default: secure_redis_password)

### Using Docker Directly

1. Build the image:

   ```bash
   docker build -t raspiska/redis:latest .
   ```

2. Run the container:

   ```bash
   docker run -d --name raspiska_redis \
     -p 6379:6379 \
     -e REDIS_PASSWORD=secure_redis_password \
     -v redis_data:/redis-data \
     raspiska/redis:latest
   ```

## Persistence Configuration

This Redis instance is configured with both AOF and RDB persistence:

- **AOF (Append Only File)**: Enabled with `appendfsync everysec` for a good balance between performance and durability
- **RDB (Redis Database Backup)**: Configured to save snapshots at these intervals:
  - After 900 seconds (15 minutes) if at least 1 key changed
  - After 300 seconds (5 minutes) if at least 10 keys changed
  - After 60 seconds (1 minute) if at least 10000 keys changed

## Memory Management

- Default memory limit: 256MB (configurable via .env)
- Eviction policy: allkeys-lru (Least Recently Used)
- Memory samples: 5

## Redis Sentinel

This container runs Redis Sentinel alongside the Redis server for high availability and monitoring:

- **Port**: 26379 (exposed to host)
- **Master Name**: mymaster
- **Quorum**: 2 (configurable)
- **Down-after-milliseconds**: 5000 (5 seconds)
- **Failover Timeout**: 60000 (60 seconds)

### Using Sentinel

Connect to Sentinel CLI:

```bash
docker exec -it raspiska_redis redis-cli -p 26379
```

Common Sentinel commands:

```bash
# Check Sentinel status
info sentinel

# List monitored masters
sentinel masters

# Get master details
sentinel master ${REDIS_SENTINEL_NAME}

# Get slaves of a master
sentinel slaves ${REDIS_SENTINEL_NAME}

# Get Sentinel instances
sentinel sentinels ${REDIS_SENTINEL_NAME}
```

### Connecting to Redis using Sentinel

In your application, you can use Sentinel for service discovery and automatic failover:

```python
from redis.sentinel import Sentinel

sentinel = Sentinel([('redis.local', 26379)], socket_timeout=0.1)
master = sentinel.master_for('${REDIS_SENTINEL_NAME}', socket_timeout=0.1, password='your_password')
master.set('foo', 'bar')
```

## Monitoring

To monitor your Redis instance:

```bash
# Connect to Redis CLI
docker exec -it raspiska_redis redis-cli -a your_password

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

Redis data is persisted in a Docker volume named `raspiska_redis_data` which survives container restarts and removals.

## Health Check

The container includes a health check that verifies Redis is running properly every 30 seconds.
