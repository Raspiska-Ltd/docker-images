# Uptime Kuma for Raspiska Tech

This Docker setup provides a self-hosted monitoring tool that offers a modern status page for all Raspiska Tech services.

## Features

- **Modern Status Page**: Clean and simple dashboard for monitoring service status
- **Multiple Monitor Types**: HTTP(s), TCP, DNS, PING, and more
- **Real-time Updates**: Status changes are pushed to the UI in real-time
- **Notification Channels**: Email, Telegram, Discord, Slack, and more
- **Response Time Graphs**: Visual representation of performance over time
- **Status History**: Historical record of uptime and incidents
- **Multi-language Support**: Interface available in multiple languages
- **Low Resource Usage**: Minimal CPU and memory footprint
- **Traefik Integration**: Automatic routing through Traefik reverse proxy
- **Kong Integration**: API Gateway integration for centralized access

## Quick Start

1. Run the setup script to start Uptime Kuma:

   ```bash
   ./setup.sh
   ```

2. Add the following entry to your `/etc/hosts` file:

   ```text
   127.0.0.1 status.raspiska.local
   ```

3. Access Uptime Kuma at:
   - Direct: [http://localhost:3001](http://localhost:3001)
   - Traefik: [http://status.raspiska.local](http://status.raspiska.local)
   - Kong: [http://kong.raspiska.local/status](http://kong.raspiska.local/status)

4. Complete the initial setup by creating an admin account when prompted

## Architecture

This Uptime Kuma setup includes:

- **Uptime Kuma**: Modern status page and monitoring tool (port 3001)
- **Traefik Integration**: Routing through the existing Traefik reverse proxy
- **Kong Integration**: Access through the Kong API Gateway

## Monitoring Raspiska Tech Services

You can configure Uptime Kuma to monitor all Raspiska Tech services:

1. **Traefik**: http://traefik.raspiska.local
2. **Redis**: TCP check on port 6379
3. **Valkey**: TCP check on port 6380
4. **Kong**: http://kong.raspiska.local
5. **Keycloak**: http://keycloak.raspiska.local
6. **n8n**: http://n8n.raspiska.local
7. **Prometheus**: http://prometheus.raspiska.local
8. **Grafana**: http://grafana.raspiska.local
9. **Alertmanager**: http://alertmanager.raspiska.local

## Status Page

Uptime Kuma provides a public status page that can be shared with users:

1. Go to Settings > Status Page
2. Create a new status page
3. Add the monitors you want to display
4. Customize the appearance and settings
5. Publish the status page
6. Share the public URL with your users

## Notification Channels

Uptime Kuma supports multiple notification channels:

1. **Email**: For basic email notifications
2. **Slack**: For team communication
3. **Discord**: For community notifications
4. **Telegram**: For mobile notifications
5. **Webhook**: For integration with custom systems
6. **And many more**: PagerDuty, OpsGenie, Pushover, etc.

## Security Considerations

- In production, secure Uptime Kuma with HTTPS
- Use a strong password for the admin account
- Consider implementing IP restrictions for admin access
- Regularly update Uptime Kuma to the latest version

## Troubleshooting

### Uptime Kuma Not Starting

1. Check the container logs:

   ```bash
   docker logs raspiska_uptime_kuma
   ```

2. Verify the container is running:

   ```bash
   docker ps | grep uptime_kuma
   ```

3. Check if port 3001 is already in use:

   ```bash
   lsof -i :3001
   ```

### Cannot Access Status Page

1. Verify Traefik configuration:

   ```bash
   cat /Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic/uptime-kuma.yml
   ```

2. Check Traefik logs:

   ```bash
   docker logs raspiska_traefik
   ```

3. Verify the hosts file entry:

   ```bash
   cat /etc/hosts | grep status.raspiska.local
   ```

## Upgrading

1. Update the image in `docker-compose.yml`
2. Run `docker-compose down && docker-compose up -d`
3. Verify the upgrade was successful
