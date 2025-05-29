# Kong API Gateway for Raspiska Tech

This Docker setup provides a complete Kong API Gateway environment for Raspiska Tech services. Kong is a powerful, open-source API gateway and microservice management layer that sits in front of your APIs and microservices.

Configured to work with Traefik, Redis, and Valkey services in the Raspiska Tech infrastructure.

## Features

- **Kong API Gateway**: High-performance API gateway with plugins for authentication, rate limiting, and more
- **Kong Admin API**: RESTful interface for configuring Kong
- **PostgreSQL Database**: Persistent storage for Kong configurations
- **Traefik Integration**: Automatic routing through Traefik reverse proxy
- **Connectivity**: Pre-configured to connect with Redis and Valkey services

## Quick Start

1. Run the setup script to start Kong:

   ```bash
   ./setup.sh
   ```

2. Add the following entries to your `/etc/hosts` file:

   ```text
   127.0.0.1 kong.raspiska.local kong-admin.raspiska.local
   ```

3. Access the Kong Admin API at [http://localhost:8001](http://localhost:8001) or [http://kong-admin.raspiska.local](http://kong-admin.raspiska.local)

## Architecture

This Kong setup includes:

- **Kong Gateway**: The main API gateway (port 8000)
- **Kong Admin API**: For configuration (port 8001)
- **PostgreSQL**: Database for storing Kong configurations

## Managing APIs with Kong

### Adding a New Service

1. **Using the Kong Admin API**:

   ```bash
   # Add a service
   curl -i -X POST http://localhost:8001/services \
     --data "name=example-service" \
     --data "url=http://example-service:8080"
   
   # Add a route for the service
   curl -i -X POST http://localhost:8001/services/example-service/routes \
     --data "name=example-route" \
     --data "paths[]=/example"
   ```

### Configuring Plugins

Kong provides many plugins for authentication, rate limiting, logging, etc.

**Example: Adding Rate Limiting**:

```bash
curl -i -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=rate-limiting" \
  --data "config.minute=5" \
  --data "config.hour=100"
```

## Integrating with Raspiska Tech Services

### Connecting to Redis

Kong can use Redis for rate limiting, caching, and more:

```bash
curl -i -X POST http://localhost:8001/plugins \
  --data "name=rate-limiting" \
  --data "config.minute=5" \
  --data "config.policy=redis" \
  --data "config.redis_host=raspiska_redis" \
  --data "config.redis_port=6379" \
  --data "config.redis_password=secure_redis_password"
```

### Using with Traefik

Kong is already configured to work with Traefik. Access your Kong services through:

- Kong Gateway: [http://kong.raspiska.local](http://kong.raspiska.local)

## Common Use Cases

### API Authentication

Kong supports various authentication methods:

- **Key Authentication**:

  ```bash
  curl -i -X POST http://localhost:8001/services/example-service/plugins \
    --data "name=key-auth"
  ```

- **JWT Authentication**:

  ```bash
  curl -i -X POST http://localhost:8001/services/example-service/plugins \
    --data "name=jwt"
  ```

### Microservice Routing

Configure Kong to route traffic to different microservices:

```bash
# Service 1
curl -i -X POST http://localhost:8001/services \
  --data "name=service1" \
  --data "url=http://service1:8080"

curl -i -X POST http://localhost:8001/services/service1/routes \
  --data "paths[]=/service1"

# Service 2
curl -i -X POST http://localhost:8001/services \
  --data "name=service2" \
  --data "url=http://service2:8080"

curl -i -X POST http://localhost:8001/services/service2/routes \
  --data "paths[]=/service2"
```

## Monitoring and Logs

- **Kong Logs**: `docker logs raspiska_kong`
- **Status API**: [http://localhost:8100](http://localhost:8100)

## Security Considerations

- In production, secure the Kong Admin API (not exposed publicly)
- Use HTTPS for all endpoints
- Implement proper authentication for all services
- Regularly update Kong to the latest version

## Troubleshooting

### Kong Not Starting

1. Check database connectivity:

   ```bash
   docker logs raspiska_kong
   ```

2. Verify PostgreSQL is running:

   ```bash
   docker logs raspiska_kong_db
   ```

### API Routing Issues

1. Check if the service and route are properly configured:

   ```bash
   curl http://localhost:8001/services
   curl http://localhost:8001/routes
   ```

2. Verify the service is healthy:

   ```bash
   curl http://localhost:8001/status
   ```

## Advanced Configuration

### Custom Plugins

Kong supports custom plugins. Place your plugins in a volume mounted to `/usr/local/share/lua/5.1/kong/plugins/`.

### Clustering

For production, set up Kong in a clustered mode with multiple nodes sharing the same database.

## Upgrading Kong

1. Update the version in `docker-compose.yml`
2. Run migrations:

   ```bash
   docker-compose run --rm kong kong migrations up
   ```

3. Restart Kong:

   ```bash
   docker-compose restart kong
   ```
