# Raspiska Tech Infrastructure - Quick Start Guide

This guide provides a quick overview of the Raspiska Tech local development infrastructure and how to get started with it.

## Overview

The Raspiska Tech infrastructure consists of the following components:

1. **Core Infrastructure**
   - Traefik (Reverse Proxy)
   - Redis & Valkey (In-memory Data Stores)
   - Kong (API Gateway)

2. **Data Storage**
   - PostgreSQL (Relational Database)
   - MinIO (Object Storage)

3. **Authentication & Security**
   - Keycloak (Identity and Access Management)

4. **Monitoring & Observability**
   - Prometheus, Grafana, Alertmanager (Monitoring)
   - Uptime Kuma (Status Page)
   - OpenTelemetry (Distributed Tracing)

5. **Automation**
   - Jenkins (CI/CD)
   - n8n (Workflow Automation)

## Quick Setup

### One-Command Setup

The fastest way to get started is to use the development environment setup script:

```bash
cd /Users/mali/Projects/raspiska/docker-images/scripts
./setup_dev_environment.sh
```

This script will set up all components and verify they're working correctly.

### Testing the Infrastructure

To verify all components are working correctly:

```bash
cd /Users/mali/Projects/raspiska/docker-images/scripts
./test_infrastructure.sh
```

## Access Points

| Service | Local URL | Traefik URL |
|---------|-----------|-------------|
| Traefik Dashboard | http://localhost:8280 | N/A |
| Kong Admin | http://localhost:8001 | http://kong-admin.raspiska.local |
| Kong Proxy | http://localhost:8000 | http://kong.raspiska.local |
| PostgreSQL | localhost:5432 | N/A |
| pgAdmin | http://localhost:5050 | http://pgadmin.raspiska.local |
| Redis | localhost:6379 | N/A |
| Valkey | localhost:6380 | N/A |
| Keycloak | http://localhost:8080 | http://keycloak.raspiska.local |
| Prometheus | http://localhost:9090 | http://prometheus.raspiska.local |
| Grafana | http://localhost:3000 | http://grafana.raspiska.local |
| Alertmanager | http://localhost:9093 | http://alertmanager.raspiska.local |
| Uptime Kuma | http://localhost:3001 | http://status.raspiska.local |
| Jenkins | http://localhost:8181/jenkins | http://jenkins.raspiska.local/jenkins |
| n8n | http://localhost:5678 | http://n8n.raspiska.local |
| MinIO API | http://localhost:9000 | http://minio.raspiska.local |
| MinIO Console | http://localhost:9001 | http://minio-console.raspiska.local |
| Jaeger UI | http://localhost:16686 | http://jaeger.raspiska.local |
| Zipkin UI | http://localhost:9412 | http://zipkin.raspiska.local |
| Tempo | http://localhost:3200 | http://tempo.raspiska.local |

## Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| PostgreSQL | postgres | secure_postgres_password |
| pgAdmin | admin@raspiska.co | secure_pgadmin_password |
| Redis | - | secure_redis_password |
| Valkey | - | secure_valkey_password |
| Keycloak | admin | secure_keycloak_password |
| Grafana | admin | secure_grafana_password |
| Jenkins | admin | secure_jenkins_password |
| n8n | admin@raspiska.co | secure_n8n_password |
| MinIO (Root) | admin | secure_minio_password |
| MinIO (App) | app_user | secure_app_password |

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

### Viewing Logs

```bash
docker logs raspiska_<service_name>
```

### Restarting a Service

```bash
cd /Users/mali/Projects/raspiska/docker-images/<service>
docker-compose down
docker-compose up -d
```

## Connecting Your Application

### Database Connection

```
Host: localhost
Port: 5432
Database: postgres
Username: postgres
Password: secure_postgres_password
```

### Redis/Valkey Connection

```
Redis Host: localhost
Redis Port: 6379
Redis Password: secure_redis_password

Valkey Host: localhost
Valkey Port: 6380
Valkey Password: secure_valkey_password
```

### MinIO (S3) Connection

```
Endpoint: http://localhost:9000
Access Key: app_user
Secret Key: secure_app_password
Region: us-east-1
```

### OpenTelemetry Connection

```
OTLP gRPC: localhost:4317
OTLP HTTP: localhost:4318
```

## Next Steps

1. For more detailed documentation, see the [Infrastructure Guide](INFRASTRUCTURE_GUIDE.md)
2. Explore each component's README file in its directory
3. Check out the example applications in the `/examples` directory

## Troubleshooting

If you encounter issues:

1. Run the test script: `./test_infrastructure.sh`
2. Check container logs: `docker logs raspiska_<service_name>`
3. Verify all required networks exist: `docker network ls`
4. Ensure host entries are in `/etc/hosts`

For more help, refer to the [Infrastructure Guide](INFRASTRUCTURE_GUIDE.md) or contact the Raspiska Tech team.
