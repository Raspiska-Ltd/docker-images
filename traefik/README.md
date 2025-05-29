# Traefik Reverse Proxy

This Docker image provides a Traefik reverse proxy and load balancer for services. Traefik automatically discovers and routes traffic to your containerized applications, making it easy to manage multiple services.

## Features

- **Automatic Service Discovery**: Detects new containers and configures routes automatically
- **Dynamic Configuration**: Updates routes without restarting the proxy
- **Dashboard**: Visual management interface for monitoring and configuration
- **Load Balancing**: Distributes traffic across multiple instances of your services
- **Middleware Support**: Rate limiting, authentication, headers management, etc.
- **SSL/TLS Support**: Automatic HTTPS with Let's Encrypt (configurable)
- **Health Checks**: Monitors service health and routes traffic accordingly

## Quick Start

1. Run the setup script to start Traefik:

   ```bash
   ./setup.sh
   ```

2. Add the following entries to your `/etc/hosts` file:

   ```text
   127.0.0.1 traefik.raspiska.local redis.raspiska.local valkey.raspiska.local
   ```

3. Access the Traefik dashboard at [http://traefik.raspiska.local:8080](http://traefik.raspiska.local:8080) or [http://localhost:8080](http://localhost:8080)

## Middleware Configuration

Traefik uses middleware to modify requests or responses before they reach your services. The default middleware configuration is located in `config/dynamic/middleware.yml` and includes:

- **secure-headers**: Adds security-related HTTP headers to all responses
  - Prevents clickjacking with frame deny
  - Enables browser XSS protection
  - Prevents MIME-type sniffing
  - Configures HSTS for secure connections

To use middleware in your service configuration, add it to the `middlewares` section of your router:

```yaml
routers:
  my-service:
    rule: "Host(`my-service.raspiska.local`)"
    service: my-service
    middlewares:
      - secure-headers
```

## Adding New Services

There are two ways to add new services to Traefik:

### Method 1: Docker Labels (Recommended)

When creating a new service, add Traefik labels to your Docker Compose file:

```yaml
services:
  my-service:
    image: my-service-image
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-service.rule=Host(`my-service.raspiska.local`)"
      - "traefik.http.routers.my-service.entrypoints=web"
      - "traefik.http.services.my-service.loadbalancer.server.port=8000"
    networks:
      - traefik_network
      # Add other networks as needed

networks:
  traefik_network:
    external: true
    name: raspiska_traefik_network
```

### Method 2: Dynamic Configuration Files

Add a new YAML file to the `config/dynamic` directory:

```yaml
# config/dynamic/my-service.yml
http:
  routers:
    my-service:
      rule: "Host(`my-service.raspiska.local`)"
      service: my-service
      entryPoints:
        - web
      middlewares:
        - secure-headers

  services:
    my-service:
      loadBalancer:
        servers:
          - url: "http://my-service-container:8000"
        passHostHeader: true
```

## Service Management Guide

### Adding a New Project

1. **Create your service container**:
   - Develop your application and containerize it
   - Make sure it exposes the necessary ports

2. **Connect to Traefik network**:
   - Add your service to the `raspiska_traefik_network` network
   - Example:

      ```yaml
      networks:
        traefik_network:
          external: true
          name: raspiska_traefik_network
      ```

3. **Configure routing**:
   - Add Traefik labels to your service (Method 1)
   - Or create a dynamic configuration file (Method 2)

4. **Update hosts file**:
   - Add your service domain to `/etc/hosts`
   - Example: `127.0.0.1 my-service.raspiska.local`

5. **Start your service**:
   - Run `docker-compose up -d` in your service directory
   - Traefik will automatically detect and route traffic to it

### Removing a Project

1. **Stop the service**:
   - Run `docker-compose down` in your service directory

2. **Remove configuration** (if using Method 2):
   - Delete the corresponding file from `config/dynamic`

3. **Clean up hosts file** (optional):
   - Remove the service domain from `/etc/hosts`

### Updating a Project

1. **Update your service**:
   - Make changes to your application and rebuild the container

2. **Update routing configuration** (if needed):
   - Modify Traefik labels or dynamic configuration files

3. **Restart your service**:
   - Run `docker-compose down && docker-compose up -d` in your service directory
   - Traefik will automatically detect the changes

## Advanced Configuration

### Enabling HTTPS

For production environments, enable HTTPS by:

1. Uncommenting the Let's Encrypt configuration in `traefik.yml`
2. Updating your email address
3. Uncommenting the HTTPS redirection
4. Adding `websecure` to your service entrypoints

### Adding Authentication

To protect a service with basic authentication:

```yaml
labels:
  - "traefik.http.routers.my-service.middlewares=basic-auth@file"
```

### Rate Limiting

To add rate limiting to a service:

```yaml
labels:
  - "traefik.http.routers.my-service.middlewares=rate-limit@file"
```

### IP Whitelisting

To restrict access to specific IP ranges:

```yaml
labels:
  - "traefik.http.routers.my-service.middlewares=ip-whitelist@file"
```

## Monitoring and Logs

- **Dashboard**: Access at [http://traefik.raspiska.local:8080](http://traefik.raspiska.local:8080)
- **Logs**: View with `docker logs raspiska_traefik`
- **Log Files**: Available in the `logs` directory

## Troubleshooting

### Service Not Appearing

1. Check if your service is running: `docker ps`
2. Verify network configuration: `docker network inspect raspiska_traefik_network`
3. Check Traefik labels or configuration files
4. Restart Traefik: `docker restart raspiska_traefik`

### Cannot Access Service

1. Verify hosts file entries
2. Check if the service is healthy
3. Examine Traefik logs for routing issues
4. Verify port configuration in your service

## Example Projects

### Web Application

```yaml
# docker-compose.yml
services:
  webapp:
    image: nginx
    volumes:
      - ./html:/usr/share/nginx/html
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.webapp.rule=Host(`webapp.raspiska.local`)"
      - "traefik.http.services.webapp.loadbalancer.server.port=80"
    networks:
      - traefik_network

networks:
  traefik_network:
    external: true
    name: raspiska_traefik_network
```

### API Service

```yaml
# docker-compose.yml
services:
  api:
    image: my-api-image
    environment:
      - NODE_ENV=production
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.raspiska.local`) && PathPrefix(`/api`)"
      - "traefik.http.services.api.loadbalancer.server.port=3000"
      - "traefik.http.middlewares.api-strip.stripprefix.prefixes=/api"
      - "traefik.http.routers.api.middlewares=api-strip,rate-limit@file"
    networks:
      - traefik_network
      - redis_network  # If your API needs Redis

networks:
  traefik_network:
    external: true
    name: raspiska_traefik_network
  redis_network:
    external: true
    name: redis_default
```

## Security Considerations

- In production, disable the insecure dashboard
- Use HTTPS with Let's Encrypt
- Implement proper authentication for sensitive services
- Regularly update Traefik to the latest version
- Use specific middlewares for security headers
