# Raspiska Tech Local Infrastructure Guide

This guide provides comprehensive documentation for the Raspiska Tech local development infrastructure. It covers all components, their configurations, and how to use them effectively.

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Infrastructure Components](#infrastructure-components)
4. [Network Architecture](#network-architecture)
5. [Security Considerations](#security-considerations)
6. [Common Operations](#common-operations)
7. [Troubleshooting](#troubleshooting)
8. [Development Workflow](#development-workflow)
9. [Reference](#reference)

## Overview

The Raspiska Tech local infrastructure provides a complete development environment that mirrors the production setup. It includes all necessary services for development, testing, and deployment of applications.

### Key Features

- **Containerized Services**: All components run in Docker containers for consistency and isolation
- **Service Discovery**: Automatic service discovery and routing with Traefik
- **API Management**: Centralized API gateway with Kong
- **Authentication**: Identity and access management with Keycloak
- **Monitoring**: Comprehensive monitoring with Prometheus, Grafana, and Uptime Kuma
- **Storage**: PostgreSQL database and MinIO object storage
- **Automation**: CI/CD pipelines with Jenkins and workflow automation with n8n
- **Observability**: Distributed tracing with OpenTelemetry

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Git
- Bash shell
- 8GB+ RAM recommended
- 20GB+ free disk space

### Quick Setup

The fastest way to get started is to use the development environment setup script:

```bash
cd /Users/mali/Projects/raspiska/docker-images/scripts
./setup_dev_environment.sh
```

This script will:
1. Check prerequisites
2. Set up required host entries
3. Create necessary networks
4. Deploy all infrastructure components
5. Verify services are running correctly
6. Display access information for all services

### Manual Setup

If you prefer to set up components individually:

1. Start with the core infrastructure:
   ```bash
   cd /Users/mali/Projects/raspiska/docker-images/traefik
   ./setup.sh
   ```

2. Add data storage:
   ```bash
   cd /Users/mali/Projects/raspiska/docker-images/postgresql
   ./setup.sh
   
   cd /Users/mali/Projects/raspiska/docker-images/redis
   ./setup.sh
   
   cd /Users/mali/Projects/raspiska/docker-images/valkey
   ./setup.sh
   
   cd /Users/mali/Projects/raspiska/docker-images/minio
   ./setup.sh
   ```

3. Add API gateway and authentication:
   ```bash
   cd /Users/mali/Projects/raspiska/docker-images/kong
   ./setup.sh
   
   cd /Users/mali/Projects/raspiska/docker-images/keycloak
   ./setup.sh
   ```

4. Add monitoring and observability:
   ```bash
   cd /Users/mali/Projects/raspiska/docker-images/monitoring
   ./setup.sh
   
   cd /Users/mali/Projects/raspiska/docker-images/uptime-kuma
   ./setup.sh
   
   cd /Users/mali/Projects/raspiska/docker-images/opentelemetry
   ./setup.sh
   ```

5. Add automation:
   ```bash
   cd /Users/mali/Projects/raspiska/docker-images/n8n
   ./setup.sh
   
   cd /Users/mali/Projects/raspiska/docker-images/jenkins
   ./setup.sh
   ```

### Verifying Installation

To verify all components are working correctly:

```bash
cd /Users/mali/Projects/raspiska/docker-images/scripts
./test_infrastructure.sh
```

## Infrastructure Components

### Traefik Reverse Proxy

**Purpose**: Routes traffic to appropriate services and provides a unified entry point

**Access Points**:
- Dashboard: http://localhost:8280
- API: http://localhost:80

**Key Files**:
- Configuration: `/traefik/config/traefik.yml`
- Dynamic Config: `/traefik/config/dynamic/`

**Common Operations**:
- Add a new service: Create a file in `/traefik/config/dynamic/` with the service configuration
- View logs: `docker logs raspiska_traefik`

### Redis & Valkey

**Purpose**: In-memory data stores for caching, session management, and message queues

**Access Points**:
- Redis: localhost:6379
- Valkey: localhost:6380

**Key Files**:
- Redis Config: `/redis/config/redis.conf`
- Valkey Config: `/valkey/config/valkey.conf`

**Common Operations**:
- Connect to Redis: `docker exec -it raspiska_redis redis-cli -a <password>`
- Connect to Valkey: `docker exec -it raspiska_valkey valkey-cli -a <password>`

### Kong API Gateway

**Purpose**: Manages APIs, authentication, rate limiting, and more

**Access Points**:
- Admin API: http://localhost:8001
- Proxy: http://localhost:8000
- Manager: http://kong-admin.raspiska.local

**Key Files**:
- Configuration: `/kong/config/kong.yml`

**Common Operations**:
- Add a service: `curl -X POST http://localhost:8001/services --data "name=example" --data "url=http://example-service:8080"`
- Add a route: `curl -X POST http://localhost:8001/services/example/routes --data "paths[]=/example"`

### PostgreSQL Database

**Purpose**: Relational database for application data

**Access Points**:
- Direct: localhost:5432
- PgBouncer: localhost:6432
- pgAdmin: http://pgadmin.raspiska.local

**Key Files**:
- Configuration: `/postgresql/config/postgresql.conf`
- Access Control: `/postgresql/config/pg_hba.conf`

**Common Operations**:
- Connect to database: `docker exec -it raspiska_postgres psql -U postgres`
- Create a database: `CREATE DATABASE myapp;`
- Create a user: `CREATE USER app_user WITH PASSWORD 'password';`

### MinIO Object Storage

**Purpose**: S3-compatible storage for files, backups, and artifacts

**Access Points**:
- API: http://localhost:9000
- Console: http://localhost:9001
- Via Traefik: http://minio.raspiska.local, http://minio-console.raspiska.local

**Key Files**:
- Configuration: `/minio/.env`

**Common Operations**:
- Create a bucket: `mc mb myminio/mybucket`
- Upload a file: `mc cp myfile.txt myminio/mybucket/`
- Generate a presigned URL: `mc share download myminio/mybucket/myfile.txt`

### Monitoring Stack

**Purpose**: Collects metrics, visualizes data, and sends alerts

**Access Points**:
- Prometheus: http://prometheus.raspiska.local
- Grafana: http://grafana.raspiska.local
- Alertmanager: http://alertmanager.raspiska.local

**Key Files**:
- Prometheus Config: `/monitoring/config/prometheus.yml`
- Grafana Dashboards: `/monitoring/config/grafana/dashboards/`

**Common Operations**:
- Add a scrape target: Edit `/monitoring/config/prometheus.yml`
- Import a dashboard: Use Grafana UI or add JSON to `/monitoring/config/grafana/dashboards/`

### OpenTelemetry Distributed Tracing

**Purpose**: Provides end-to-end visibility across services

**Access Points**:
- Jaeger UI: http://localhost:16686
- Zipkin UI: http://localhost:9412
- Tempo: http://localhost:3200
- Collector: http://localhost:8888

**Key Files**:
- Collector Config: `/opentelemetry/config/otel-collector-config.yaml`
- Tempo Config: `/opentelemetry/config/tempo.yaml`

**Common Operations**:
- View traces: Access Jaeger UI at http://localhost:16686
- Add a new instrumented service: Configure to send traces to `localhost:4317` (gRPC) or `localhost:4318` (HTTP)

### Jenkins CI/CD

**Purpose**: Automates building, testing, and deploying applications

**Access Points**:
- Web UI: http://localhost:8181/jenkins
- Via Traefik: http://jenkins.raspiska.local/jenkins

**Key Files**:
- Configuration: `/jenkins/casc/jenkins.yaml`
- Pipeline Example: `/jenkins/Jenkinsfile`

**Common Operations**:
- Create a new job: Use the Jenkins UI or add a Jenkinsfile to your repository
- Run a build: Trigger manually or via webhook

### n8n Workflow Automation

**Purpose**: Creates automated workflows between services

**Access Points**:
- Web UI: http://localhost:5678
- Via Traefik: http://n8n.raspiska.local

**Key Files**:
- Workflows: Stored in the n8n database

**Common Operations**:
- Create a workflow: Use the n8n UI
- Trigger a workflow: Via webhook or schedule

## Network Architecture

The infrastructure uses several Docker networks to isolate and connect services:

- `raspiska_traefik_network`: Main network for Traefik routing
- `raspiska_redis_network`: For Redis and services that need Redis
- `raspiska_valkey_network`: For Valkey and services that need Valkey
- `raspiska_postgres_network`: For PostgreSQL and dependent services
- `raspiska_prometheus_network`: For monitoring components
- `raspiska_minio_network`: For MinIO object storage
- `raspiska_opentelemetry_network`: For distributed tracing

Services are connected to the networks they need to communicate with, providing isolation and security.

## Security Considerations

### Local Development Security

For local development, security is simplified:
- Most services use HTTP instead of HTTPS
- Default passwords are used (see `.env` files)
- Host entries are added to `/etc/hosts`

### Production Differences

In production, you would need to:
- Enable HTTPS with proper certificates
- Use strong, unique passwords
- Implement proper network segmentation
- Set up proper DNS instead of host entries
- Enable additional security features in each service

## Common Operations

### Starting and Stopping Services

To start all services:
```bash
cd /Users/mali/Projects/raspiska/docker-images/scripts
./setup_dev_environment.sh
```

To stop all services:
```bash
cd /Users/mali/Projects/raspiska/docker-images
docker-compose -f */docker-compose.yml down
```

To restart a specific service:
```bash
cd /Users/mali/Projects/raspiska/docker-images/<service>
docker-compose down
docker-compose up -d
```

### Viewing Logs

To view logs for a specific service:
```bash
docker logs raspiska_<service_name>
```

For continuous log viewing:
```bash
docker logs -f raspiska_<service_name>
```

### Backing Up Data

#### PostgreSQL Backup
```bash
docker exec raspiska_postgres pg_dump -U postgres <database> > backup.sql
```

#### Redis Backup
Redis uses AOF and RDB persistence, which are automatically backed up to the volume.

#### MinIO Backup
```bash
mc cp --recursive myminio/bucket /path/to/backup/
```

### Updating Services

To update a service:
```bash
cd /Users/mali/Projects/raspiska/docker-images/<service>
docker-compose pull
docker-compose down
docker-compose up -d
```

## Troubleshooting

### Common Issues

#### Service Won't Start
1. Check for port conflicts: `lsof -i :<port>`
2. Check logs: `docker logs raspiska_<service_name>`
3. Check if required networks exist: `docker network ls`
4. Verify host entries in `/etc/hosts`

#### Service Is Unreachable
1. Check if container is running: `docker ps | grep <service_name>`
2. Check Traefik logs: `docker logs raspiska_traefik`
3. Verify network connectivity: `docker exec -it raspiska_<service_name> ping <target_service>`

#### Database Connection Issues
1. Check if PostgreSQL is running: `docker ps | grep postgres`
2. Verify connection details: `docker exec -it raspiska_postgres psql -U postgres -c "SELECT 1;"`
3. Check pgBouncer if using connection pooling: `docker logs raspiska_pgbouncer`

### Diagnostic Tools

#### Infrastructure Test Script
```bash
cd /Users/mali/Projects/raspiska/docker-images/scripts
./test_infrastructure.sh
```

#### Container Health Checks
```bash
docker inspect --format "{{.State.Health.Status}}" raspiska_<service_name>
```

#### Network Diagnostics
```bash
docker network inspect raspiska_<network_name>
```

## Development Workflow

### Local Development

1. **Setup**: Ensure all infrastructure components are running
2. **Development**: Write code and connect to local services
3. **Testing**: Run tests against local infrastructure
4. **CI/CD**: Use Jenkins for automated testing and deployment

### Using CI/CD Pipeline

1. Push code to repository
2. Jenkins automatically builds and tests the code
3. If tests pass, Jenkins deploys to the appropriate environment
4. Monitor deployment with Uptime Kuma and Grafana

### Monitoring Your Application

1. Add Prometheus metrics to your application
2. Instrument with OpenTelemetry for distributed tracing
3. Create Grafana dashboards for visualization
4. Set up alerts in Alertmanager

## Reference

### Environment Variables

Each service has its own `.env` file with configuration options. Key variables include:

- Database credentials
- API keys and secrets
- Service-specific configuration
- Network settings

### Port Assignments

| Service | Port | Purpose |
|---------|------|---------|
| Traefik | 80 | HTTP routing |
| Traefik | 443 | HTTPS routing |
| Traefik | 8280 | Dashboard |
| Redis | 6379 | Redis server |
| Valkey | 6380 | Valkey server |
| PostgreSQL | 5432 | PostgreSQL server |
| PgBouncer | 6432 | Connection pooling |
| pgAdmin | 5050 | Database administration |
| Kong | 8000 | Proxy |
| Kong | 8001 | Admin API |
| Keycloak | 8080 | Authentication |
| Jenkins | 8181 | CI/CD server |
| n8n | 5678 | Workflow automation |
| Prometheus | 9090 | Metrics collection |
| Grafana | 3000 | Visualization |
| Alertmanager | 9093 | Alert management |
| Uptime Kuma | 3001 | Status page |
| MinIO | 9000 | S3 API |
| MinIO | 9001 | Console |
| Jaeger | 16686 | Tracing UI |
| Zipkin | 9412 | Tracing UI |
| Tempo | 3200 | Tracing backend |
| OTLP | 4317 | gRPC endpoint |
| OTLP | 4318 | HTTP endpoint |

### Useful Commands

#### Docker Commands
```bash
# List all containers
docker ps

# View container logs
docker logs <container_name>

# Enter container shell
docker exec -it <container_name> sh

# View networks
docker network ls

# Inspect a container
docker inspect <container_name>
```

#### Service-Specific Commands
```bash
# PostgreSQL
docker exec -it raspiska_postgres psql -U postgres

# Redis
docker exec -it raspiska_redis redis-cli -a <password>

# MinIO
mc config host add myminio http://localhost:9000 <access_key> <secret_key>
mc ls myminio

# Kong
curl -X GET http://localhost:8001/services

# Prometheus
curl -X GET http://localhost:9090/api/v1/targets
```

### Documentation Links

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Kong Documentation](https://docs.konghq.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [MinIO Documentation](https://docs.min.io/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/)
