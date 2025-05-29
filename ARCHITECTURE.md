# Raspiska Tech Infrastructure Architecture

This document provides a visual overview of the Raspiska Tech infrastructure architecture and explains how the components interact with each other.

## Architecture Diagram

```
                                   ┌─────────────────────────────────────────────────────────────┐
                                   │                     Client Applications                      │
                                   └───────────────────────────────┬─────────────────────────────┘
                                                                   │
                                                                   ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                                         │
│                                           Traefik Reverse Proxy                                         │
│                                                                                                         │
└───────┬─────────────────┬─────────────────┬─────────────────┬─────────────────┬─────────────────┬───────┘
        │                 │                 │                 │                 │                 │
        ▼                 ▼                 ▼                 ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│               │ │               │ │               │ │               │ │               │ │               │
│  Kong API     │ │  Keycloak     │ │  Jenkins      │ │  Monitoring   │ │  n8n          │ │  MinIO        │
│  Gateway      │ │  IAM          │ │  CI/CD        │ │  Stack        │ │  Workflow     │ │  Object       │
│               │ │               │ │               │ │               │ │  Automation   │ │  Storage      │
└───────┬───────┘ └───────┬───────┘ └───────┬───────┘ └───────┬───────┘ └───────┬───────┘ └───────┬───────┘
        │                 │                 │                 │                 │                 │
        │                 │                 │                 ▼                 │                 │
        │                 │                 │        ┌───────────────┐         │                 │
        │                 │                 │        │ Prometheus    │         │                 │
        │                 │                 │        │ Grafana       │         │                 │
        │                 │                 │        │ Alertmanager  │         │                 │
        │                 │                 │        └───────┬───────┘         │                 │
        │                 │                 │                │                 │                 │
        │                 │                 │                ▼                 │                 │
        │                 │                 │        ┌───────────────┐         │                 │
        │                 │                 │        │ Uptime Kuma   │         │                 │
        │                 │                 │        │ Status Page   │         │                 │
        │                 │                 │        └───────────────┘         │                 │
        │                 │                 │                                  │                 │
        ▼                 ▼                 ▼                                  ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                                         │
│                                     OpenTelemetry Distributed Tracing                                   │
│                                                                                                         │
└───────┬─────────────────┬─────────────────┬─────────────────────────────────────────────────────┬───────┘
        │                 │                 │                                                     │
        ▼                 ▼                 ▼                                                     ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐                                    ┌───────────────┐
│               │ │               │ │               │                                    │               │
│  Jaeger       │ │  Zipkin       │ │  Tempo        │                                    │  OTLP         │
│  Tracing UI   │ │  Tracing UI   │ │  Tracing      │                                    │  Collector    │
│               │ │               │ │  Backend      │                                    │               │
└───────────────┘ └───────────────┘ └───────────────┘                                    └───────────────┘
                                                                                                │
                                                                                                │
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                                         │
│                                        Data Storage Layer                                               │
│                                                                                                         │
└───────┬─────────────────┬─────────────────┬─────────────────────────────────────────────────────┬───────┘
        │                 │                 │                                                     │
        ▼                 ▼                 ▼                                                     ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐                                    ┌───────────────┐
│               │ │               │ │               │                                    │               │
│  PostgreSQL   │ │  Redis        │ │  Valkey       │                                    │  MinIO        │
│  Database     │ │  Cache        │ │  Cache        │                                    │  Buckets      │
│               │ │               │ │  (Redis Alt)  │                                    │               │
└───────┬───────┘ └───────────────┘ └───────────────┘                                    └───────────────┘
        │
        ▼
┌───────────────┐
│               │
│  PgBouncer    │
│  Connection   │
│  Pooling      │
│               │
└───────────────┘
```

## Component Interactions

### Traffic Flow

1. **Client Applications** send requests to the infrastructure
2. **Traefik Reverse Proxy** routes traffic to the appropriate service based on host/path
3. **Kong API Gateway** provides API management, authentication, and rate limiting
4. **Keycloak** handles identity and access management
5. **Backend Services** process requests and store/retrieve data

### Data Flow

1. **PostgreSQL** stores relational data for applications
2. **Redis/Valkey** provide caching and session management
3. **MinIO** stores objects, files, backups, and artifacts

### Monitoring Flow

1. **Prometheus** collects metrics from all services
2. **Grafana** visualizes metrics and provides dashboards
3. **Alertmanager** sends notifications for alerts
4. **Uptime Kuma** monitors service availability

### Tracing Flow

1. **Applications** send traces to OpenTelemetry Collector
2. **OpenTelemetry Collector** processes and routes traces
3. **Jaeger/Zipkin/Tempo** store and visualize traces

### CI/CD Flow

1. **Jenkins** builds, tests, and deploys applications
2. **n8n** automates workflows between services

## Network Architecture

The infrastructure uses several Docker networks to isolate and connect services:

```
┌─────────────────────────┐
│ raspiska_traefik_network│
└─────────────┬───────────┘
              │
              ▼
┌─────────────────────────┐     ┌─────────────────────────┐     ┌─────────────────────────┐
│ raspiska_redis_network  │     │ raspiska_valkey_network │     │ raspiska_postgres_network│
└─────────────────────────┘     └─────────────────────────┘     └─────────────────────────┘
              │                               │                               │
              └───────────────┬───────────────┘                               │
                              │                                               │
                              ▼                                               ▼
                    ┌─────────────────────────┐                   ┌─────────────────────────┐
                    │ raspiska_minio_network  │                   │ raspiska_prometheus_network│
                    └─────────────────────────┘                   └─────────────────────────┘
                                                                               │
                                                                               ▼
                                                                  ┌─────────────────────────┐
                                                                  │ raspiska_opentelemetry_network│
                                                                  └─────────────────────────┘
```

## Security Architecture

The infrastructure implements security at multiple levels:

1. **Network Isolation**: Services are only connected to the networks they need
2. **Authentication**: All services require authentication
3. **API Gateway**: Kong provides a security layer for all APIs
4. **Identity Management**: Keycloak manages users and permissions
5. **Monitoring**: Security events are monitored and alerted on

## Scalability Architecture

The infrastructure is designed to scale:

1. **Containerization**: All components run in Docker containers
2. **Service Discovery**: Traefik automatically discovers new services
3. **Connection Pooling**: PgBouncer manages database connections
4. **Caching**: Redis/Valkey provide caching for improved performance
5. **Object Storage**: MinIO scales horizontally for storage needs

## High Availability Considerations

For production environments, the infrastructure can be enhanced for high availability:

1. **Database Replication**: PostgreSQL can be configured with replication
2. **Redis Sentinel**: Already configured for Redis/Valkey failover
3. **Load Balancing**: Traefik provides load balancing capabilities
4. **Distributed Tracing**: OpenTelemetry provides visibility across services
5. **Monitoring**: Prometheus and Uptime Kuma monitor service health
