# Raspiska Tech Docker Images

This repository contains custom Docker images used by Raspiska Tech & Consultancy for various services and applications. Each subdirectory contains a specific Docker image configuration with its own documentation, Dockerfile, and setup scripts.

## Repository Structure

Each service has its own directory with the following components:

- `Dockerfile` - Configuration for building the Docker image
- `docker-compose.yml` - Compose file for easy deployment
- `.env` - Environment variables for configuration
- `setup.sh` - Automated setup and testing script
- `README.md` - Documentation specific to the service

## Available Images

### RabbitMQ

A custom RabbitMQ image with enhanced plugins for message scheduling, load balancing, and broker federation.

**Features:**

- RabbitMQ 4.1.0 with Management UI
- Delayed Message Exchange plugin for message scheduling
- Consistent Hash Exchange plugin for load balancing
- Shovel plugin for message transfer between brokers
- Configurable admin credentials via environment variables
- Custom hostname configuration

**Directory:** [/rabbitmq](/rabbitmq)

### Redis with Sentinel

A custom Redis image with persistence, high availability via Sentinel, and monitoring capabilities.

**Features:**

- Redis 7.x with AOF and RDB persistence
- Redis Sentinel for high availability and automatic failover
- Memory management with configurable limits and eviction policies
- Password authentication and security features
- Monitoring tools and health checks
- Custom hostname configuration

**Directory:** [/redis](/redis)

### Valkey with Sentinel

A custom Valkey image (Redis-compatible database) with persistence, high availability via Sentinel, and monitoring capabilities.

**Features:**

- Valkey (latest) with AOF and RDB persistence
- Redis Sentinel for high availability and automatic failover
- Memory management with configurable limits and eviction policies
- Password authentication and security features
- Monitoring tools and health checks
- Custom hostname configuration
- Runs on alternate ports (6380, 26380) to avoid conflicts with Redis

**Directory:** [/valkey](/valkey)

### Traefik Reverse Proxy

A Traefik reverse proxy and load balancer for managing access to all Raspiska Tech services.

**Features:**

- Automatic service discovery and configuration
- Dynamic routing without restarts
- Visual dashboard for monitoring and management
- Middleware support (rate limiting, authentication, etc.)
- SSL/TLS support with Let's Encrypt integration
- Health checks and load balancing
- Comprehensive documentation for adding new services

**Directory:** [/traefik](/traefik)

### Kong API Gateway

A Kong API Gateway with Konga admin UI for managing APIs and microservices.

**Features:**

- High-performance API gateway with plugin architecture
- Konga web-based admin interface for easy management
- PostgreSQL database for configuration storage
- Authentication, rate limiting, and request transformation
- Microservice routing and load balancing
- Integration with Redis for caching and rate limiting
- Comprehensive documentation for API management

**Directory:** [/kong](/kong)

## Usage

Each image directory contains a `setup.sh` script that automates the process of building, running, and testing the Docker container. To use any of these images:

1. Navigate to the specific service directory
2. Run the setup script:

   ```bash
   ./setup.sh
   ```

3. The script will build the container, start it, and verify that it's working correctly

## Development

To add a new custom Docker image to this repository:

1. Create a new directory for the service
2. Add the necessary Dockerfile, docker-compose.yml, and configuration files
3. Include a README.md with documentation specific to the service
4. Create a setup.sh script to automate the build and test process
5. Test the image thoroughly before committing

## License

Copyright © 2025 Raspiska Tech & Consultancy. All rights reserved.

## Contact

For questions or support regarding these Docker images, contact:

- Website: [https://raspiska.co](https://raspiska.co)
