# Raspiska Tech Development Environment Scripts

This directory contains scripts for setting up and managing the Raspiska Tech development environment.

## Setup Development Environment

The `setup_dev_environment.sh` script automates the process of setting up the entire Raspiska Tech infrastructure. It provides a streamlined way for new developers to get started with the project.

### Features

- **Automated Setup**: One-click setup of all Raspiska Tech components
- **Component Selection**: Choose which components to set up
- **Prerequisite Checking**: Verifies Docker and Docker Compose installation
- **Hosts File Management**: Automatically adds required entries to /etc/hosts
- **Service Verification**: Checks if all services are running and accessible
- **Credential Display**: Shows login credentials for all services

### Usage

1. Make the script executable:

   ```bash
   chmod +x setup_dev_environment.sh
   ```

2. Run the script:

   ```bash
   ./setup_dev_environment.sh
   ```

3. Follow the on-screen prompts to select which components to set up

### Components

The script can set up the following components:

1. **Traefik**: Reverse proxy and load balancer
2. **Redis**: In-memory data store with Sentinel
3. **Valkey**: Redis-compatible alternative with Sentinel
4. **Kong**: API Gateway
5. **Keycloak**: Identity and access management
6. **n8n**: Workflow automation
7. **Monitoring Stack**: Prometheus, Grafana, and Alertmanager
8. **Uptime Kuma**: Status page and monitoring tool
9. **PostgreSQL**: Database with custom configuration

### Requirements

- Docker and Docker Compose installed
- Sufficient disk space for all containers
- Administrative privileges (for updating /etc/hosts)

### Troubleshooting

If you encounter issues during setup:

1. Check the Docker logs for the specific component:

   ```bash
   docker logs raspiska_[component_name]
   ```

2. Verify that all required ports are available:

   ```bash
   netstat -tuln
   ```

3. Ensure Docker has sufficient resources allocated

4. Check the component-specific README files in the `/docker-images` directory for more detailed troubleshooting

## Additional Scripts

More utility scripts will be added to this directory in the future, including:

- Backup and restore scripts
- Performance tuning scripts
- Cleanup scripts
- Update scripts
