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

A Kong API Gateway for managing APIs and microservices.

**Features:**

- High-performance API gateway with plugin architecture
- PostgreSQL database for configuration storage
- Authentication, rate limiting, and request transformation
- Microservice routing and load balancing
- Integration with Redis for caching and rate limiting
- Comprehensive documentation for API management

**Directory:** [/kong](/kong)

### Keycloak Identity and Access Management

A Keycloak identity and access management solution for authentication and authorization.

**Features:**

- Single Sign-On (SSO) across all applications
- User management and authentication
- Social login and identity brokering
- Multi-factor authentication
- Role-based access control
- Integration with Kong API Gateway
- PostgreSQL database for configuration storage

**Directory:** [/keycloak](/keycloak)

### n8n Workflow Automation

An n8n workflow automation platform for connecting services and automating tasks.

**Features:**

- Visual workflow editor for automation without coding
- AI content generation with OpenAI integration
- Multi-channel notification system (email, Slack, SMS)
- Data integration and synchronization capabilities
- Webhook endpoints for external triggers
- PostgreSQL database for workflow storage
- Sample workflows for common automation tasks

**Directory:** [/n8n](/n8n)

### Monitoring Stack

A comprehensive monitoring solution for all Raspiska Tech services.

**Features:**

- Prometheus for metrics collection and storage
- Grafana for visualization and dashboarding
- Alertmanager for alert handling and notifications
- Node Exporter for host system metrics
- Service-specific exporters for Redis, Valkey, PostgreSQL, and Kong
- Pre-configured dashboards for all services
- Alert rules for common failure scenarios
- Multiple notification channels (email, Slack)

**Directory:** [/monitoring](/monitoring)

### Uptime Kuma Status Page

A modern status page and monitoring tool for all Raspiska Tech services.

**Features:**

- Clean and simple status dashboard
- Multiple monitor types (HTTP, TCP, DNS, PING)
- Real-time status updates
- Multiple notification channels (Email, Telegram, Discord, Slack)
- Response time graphs and status history
- Multi-language support
- Low resource usage

**Directory:** [/uptime-kuma](/uptime-kuma)

### Custom PostgreSQL Database

A high-performance PostgreSQL database with custom configuration and tools.

**Features:**

- PostgreSQL 15 with optimized configuration
- PgBouncer for connection pooling
- pgAdmin for web-based administration
- Automated daily backups with configurable retention
- Custom user accounts and security settings
- SSL support for secure connections
- Integration with Prometheus for monitoring

**Directory:** [/postgresql](/postgresql)

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
