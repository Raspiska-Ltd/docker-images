# Monitoring Stack for Raspiska Tech

This Docker setup provides a complete monitoring solution for Raspiska Tech services. It includes Prometheus for metrics collection, Grafana for visualization, and Alertmanager for alert handling.

## Features

- **Prometheus**: Time-series database for metrics collection and storage
- **Grafana**: Visualization and dashboarding platform
- **Alertmanager**: Alert handling and notification system
- **Node Exporter**: Host system metrics collection
- **Service Exporters**: Specialized exporters for Redis, Valkey, PostgreSQL, and Kong
- **Traefik Integration**: Automatic routing through Traefik reverse proxy
- **Kong Integration**: API Gateway integration for centralized access
- **Pre-configured Dashboards**: Ready-to-use dashboards for system and service monitoring
- **Alert Rules**: Pre-configured alert rules for common failure scenarios

## Quick Start

1. Run the setup script to start the monitoring stack:

   ```bash
   ./setup.sh
   ```

2. Add the following entries to your `/etc/hosts` file:

   ```text
   127.0.0.1 prometheus.raspiska.local grafana.raspiska.local alertmanager.raspiska.local
   ```

3. Access the monitoring services at:
   - Prometheus: [http://prometheus.raspiska.local](http://prometheus.raspiska.local) or [http://localhost:9090](http://localhost:9090)
   - Grafana: [http://grafana.raspiska.local](http://grafana.raspiska.local) or [http://localhost:3000](http://localhost:3000)
   - Alertmanager: [http://alertmanager.raspiska.local](http://alertmanager.raspiska.local) or [http://localhost:9093](http://localhost:9093)

4. Log in to Grafana with the admin credentials specified in the `.env` file (default: admin/secure_grafana_password)

## Architecture

This monitoring stack includes:

- **Prometheus**: Central metrics collection and storage (port 9090)
- **Grafana**: Visualization and dashboarding (port 3000)
- **Alertmanager**: Alert handling and notifications (port 9093)
- **Node Exporter**: Host system metrics (port 9100)
- **Redis Exporter**: Redis metrics (port 9121)
- **Valkey Exporter**: Valkey metrics (port 9122)
- **PostgreSQL Exporter**: PostgreSQL metrics (port 9187)
- **Kong Exporter**: Kong API Gateway metrics (port 9542)

## Monitored Services

The monitoring stack is configured to collect metrics from all Raspiska Tech services:

- **Traefik**: Reverse proxy and load balancer
- **Redis**: In-memory data store with Sentinel
- **Valkey**: Redis-compatible alternative with Sentinel
- **PostgreSQL**: Relational database for Kong, Keycloak, and n8n
- **Kong**: API Gateway
- **Keycloak**: Identity and access management
- **n8n**: Workflow automation

## Dashboards

The monitoring stack comes with pre-configured dashboards:

1. **System Overview**: Host system metrics (CPU, memory, disk)
2. **Service Status**: Health status of all services
3. **Redis/Valkey Metrics**: Memory usage, operations, clients
4. **PostgreSQL Metrics**: Connections, transactions, query performance
5. **Traefik Metrics**: Request rates, latencies, error rates
6. **Kong Metrics**: API traffic, response times, error rates
7. **Keycloak Metrics**: User sessions, authentication rates
8. **n8n Metrics**: Workflow executions, success/failure rates

## Alerts

The monitoring stack includes pre-configured alerts for:

- **Instance Down**: Service availability
- **High CPU/Memory/Disk Usage**: Resource utilization
- **Redis/PostgreSQL Issues**: Database performance and availability
- **HTTP Error Rates**: API and service errors
- **n8n Workflow Failures**: Automation failures

## Notification Channels

Alerts can be sent through multiple channels:

- **Email**: Configure SMTP settings in the `.env` file
- **Slack**: Configure Slack webhook URL in the `.env` file
- **Custom Webhooks**: Can be configured in Alertmanager for integration with other services

## Adding Custom Metrics

### Adding a New Service to Monitor

1. Add the service to Prometheus configuration:

   ```yaml
   # In config/prometheus.yml
   scrape_configs:
     - job_name: 'my-service'
       static_configs:
         - targets: ['my-service:8080']
       metrics_path: /metrics
   ```

2. Restart Prometheus:

   ```bash
   docker restart raspiska_prometheus
   ```

### Creating a Custom Dashboard

1. Log in to Grafana
2. Click "Create" > "Dashboard"
3. Add panels using PromQL queries
4. Save the dashboard
5. Export the dashboard JSON and add it to the `dashboards` directory for persistence

## Security Considerations

- In production, secure all services with HTTPS
- Use strong passwords for admin accounts
- Implement proper authentication for all monitoring services
- Restrict access to sensitive metrics
- Regularly update all components to the latest versions

## Troubleshooting

### Prometheus Not Collecting Metrics

1. Check if the exporter is running:

   ```bash
   docker ps | grep exporter
   ```

2. Verify the target is up in Prometheus UI:
   - Go to Status > Targets in the Prometheus UI
   - Check for any targets showing as "Down"

3. Check exporter logs:

   ```bash
   docker logs raspiska_redis_exporter
   ```

### Grafana Not Showing Data

1. Verify Prometheus data source is working:
   - Go to Configuration > Data Sources in Grafana
   - Click on the Prometheus data source
   - Click "Test" to verify the connection

2. Check Prometheus query in the panel:
   - Edit the panel
   - Verify the PromQL query is correct
   - Use the query explorer to test the query

### Alerts Not Firing

1. Check alert rules in Prometheus UI:
   - Go to Alerts in the Prometheus UI
   - Verify the alert condition is being evaluated

2. Check Alertmanager configuration:
   - Verify the alertmanager.yml file is correctly formatted
   - Check Alertmanager logs for any errors

## Advanced Configuration

### Custom Alert Rules

Create a new file in the `config/rules` directory:

```yaml
groups:
  - name: my-custom-alerts
    rules:
      - alert: MyCustomAlert
        expr: my_metric > threshold
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Custom alert triggered"
          description: "Description of the alert"
```

### Integration with External Systems

The monitoring stack can be integrated with external systems:

- **PagerDuty**: Configure in Alertmanager for incident management
- **OpsGenie**: Configure in Alertmanager for on-call scheduling
- **Microsoft Teams**: Use a webhook receiver in Alertmanager
- **Custom Webhooks**: For integration with other notification systems

## Upgrading

1. Update the images in `docker-compose.yml`
2. Back up your configuration and data
3. Run `docker-compose down && docker-compose up -d`
4. Verify the upgrade was successful
