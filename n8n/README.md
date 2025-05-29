# n8n Workflow Automation for Raspiska Tech

This Docker setup provides a complete n8n workflow automation platform for Raspiska Tech services. n8n is a powerful workflow automation tool that allows you to connect various services and automate tasks without writing code.

## Features

- **n8n Workflow Automation**: Fair-code licensed workflow automation tool
- **PostgreSQL Database**: Persistent storage for workflows and credentials
- **Sample Workflows**: Pre-configured workflows for common tasks
- **Traefik Integration**: Automatic routing through Traefik reverse proxy
- **Kong Integration**: API Gateway integration for centralized access
- **Security**: Basic authentication and encryption for sensitive data

## Quick Start

1. Run the setup script to start n8n:

   ```bash
   ./setup.sh
   ```

2. Add the following entries to your `/etc/hosts` file:

   ```text
   127.0.0.1 n8n.raspiska.local
   ```

3. Access the n8n dashboard at:
   - Direct link: [http://localhost:5678](http://localhost:5678)
   - Via Traefik: [http://n8n.raspiska.local](http://n8n.raspiska.local)
   - Via Kong: [http://kong.raspiska.local/n8n](http://kong.raspiska.local/n8n)

4. Log in with the admin credentials specified in the `.env` file (default: admin/secure_admin_password)

## Architecture

This n8n setup includes:

- **n8n Server**: The main workflow automation server (port 5678)
- **PostgreSQL**: Database for storing workflows, credentials, and execution data
- **Integration with Traefik**: For routing and load balancing
- **Integration with Kong**: For API Gateway access
- **Sample Workflows**: Pre-configured workflows for common tasks

## Sample Workflows

### 1. AI Content Generator

This workflow uses OpenAI to generate content based on a given topic:

- **Trigger**: Webhook (`/webhook/generate-content`)
- **Input Parameters**:
  - `topic`: The subject to write about
  - `tone`: The writing tone (optional, default: informative)
  - `length`: Content length (optional, default: medium)
- **Output**: Generated content in JSON format

Example request:

```bash
curl -X POST http://n8n.raspiska.local/webhook/generate-content \
  -H "Content-Type: application/json" \
  -d '{"topic": "Artificial Intelligence", "tone": "educational", "length": "short"}'
```

### 2. Multi-Channel Notification Sender

This workflow sends notifications through multiple channels:

- **Trigger**: Webhook (`/webhook/send-notification`)
- **Channels**:
  - Email (requires SMTP configuration)
  - Slack (requires Slack integration)
  - SMS (requires Twilio integration)
- **Input Parameters**:
  - `channel`: Array of channels to use (e.g., `["email", "slack"]`)
  - `message`: The notification content
  - `subject`: Email subject (for email channel)
  - `email`: Recipient email (for email channel)
  - `slack_channel`: Slack channel (for Slack channel)
  - `phone`: Phone number (for SMS channel)

Example request:

```bash
curl -X POST http://n8n.raspiska.local/webhook/send-notification \
  -H "Content-Type: application/json" \
  -d '{"channel": ["email", "slack"], "message": "System update completed", "subject": "Update Notification", "email": "user@example.com", "slack_channel": "general"}'
```

### 3. Data Integration and Synchronization

This workflow fetches data from an external API and syncs it to a database:

- **Trigger**: Schedule (every hour)
- **Process**:
  1. Fetch data from external API
  2. Process and transform the data
  3. Store in MySQL database
  4. Send notification about the result

## Creating Custom Workflows

To create your own workflows:

1. Access the n8n dashboard
2. Click "Workflows" in the left sidebar
3. Click "Create new workflow"
4. Add nodes and connect them to build your workflow
5. Save and activate your workflow

## Integrating with Raspiska Tech Services

### Connecting to Keycloak

To integrate n8n with Keycloak for authentication:

1. Configure the n8n environment variables:

   ```properties
   N8N_AUTHENTICATION_TYPE=jwt
   N8N_JWT_AUTH_HEADER=Authorization
   N8N_JWT_AUTH_HEADER_VALUE_PREFIX=Bearer
   N8N_JWT_ISSUER=http://keycloak.raspiska.local/auth/realms/raspiska
   ```

2. Create a client in Keycloak for n8n:
   - Client ID: n8n
   - Access Type: confidential
   - Valid Redirect URIs: `http://n8n.raspiska.local/*`

### Using with Redis/Valkey

n8n can connect to Redis/Valkey for caching or message queuing:

1. Install the Redis node in n8n
2. Configure the connection using the Redis credentials:
   - Host: redis.raspiska.local or valkey.raspiska.local
   - Port: 6379 (Redis) or 6380 (Valkey)
   - Password: (from Redis/Valkey configuration)

## Security Considerations

- In production, secure n8n with HTTPS
- Use strong passwords for admin accounts
- Regularly update n8n to the latest version
- Store sensitive credentials securely
- Use environment variables for sensitive information

## Troubleshooting

### n8n Not Starting

1. Check database connectivity:

   ```bash
   docker logs raspiska_n8n
   ```

2. Verify PostgreSQL is running:

   ```bash
   docker logs raspiska_n8n_db
   ```

### Workflow Execution Issues

1. Check the execution logs in the n8n dashboard
2. Verify that all required credentials are properly configured
3. Check the n8n logs for error messages

## Advanced Configuration

### Custom Environment Variables

Edit the `.env` file to customize n8n configuration:

- `N8N_ENCRYPTION_KEY`: Key used to encrypt credentials
- `N8N_BASIC_AUTH_USER`: Username for basic authentication
- `N8N_BASIC_AUTH_PASSWORD`: Password for basic authentication
- `N8N_WEBHOOK_URL`: External URL for webhooks

### Persistent Data

n8n data is stored in Docker volumes:

- `raspiska_n8n_data`: n8n application data
- `raspiska_n8n_db_data`: PostgreSQL database data

### Adding Custom Nodes

To add custom nodes to n8n:

1. Create a custom nodes directory
2. Mount it to the n8n container at `/home/node/.n8n/custom`
3. Add the `N8N_CUSTOM_EXTENSIONS=/home/node/.n8n/custom` environment variable

## Upgrading n8n

1. Update the version in `docker-compose.yml`
2. Back up your database and workflows
3. Run `docker-compose down && docker-compose up -d`
4. Verify the upgrade was successful
