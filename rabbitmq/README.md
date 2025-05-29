# Custom RabbitMQ Docker Image by Raspiska Tech

This Docker image extends the official RabbitMQ Alpine image with management console and adds several useful plugins pre-configured by Raspiska Tech.

## Included Plugins

- rabbitmq_management - Management UI
- rabbitmq_consistent_hash_exchange - Consistent hash exchange type
- rabbitmq_delayed_message_exchange - Message scheduling capability
- rabbitmq_shovel - Message transfer between brokers
- rabbitmq_shovel_management - UI for shovel management

## Version Information

- RabbitMQ Version: 4.1.0 (Based on rabbitmq:management-alpine)
- Delayed Message Exchange Plugin: 4.1.0 Link: [rabbitmq_delayed_message_exchange-4.1.0.ez](https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v4.1.0/rabbitmq_delayed_message_exchange-4.1.0.ez)

## Usage

### Using Docker Compose (Recommended)

1. Configure the environment variables in the `.env` file:

   ```bash
   RABBITMQ_DEFAULT_USER=admin
   RABBITMQ_DEFAULT_PASS=password
   RABBITMQ_DEFAULT_VHOST=/
   ```

2. Add the hostname to your local hosts file:

   ```bash
   sudo echo "127.0.0.1 rabbitmq.local" >> /etc/hosts
   ```

   Or manually edit `/etc/hosts` and add:

   ```plaintext
   127.0.0.1 rabbitmq.local
   ```

3. Build and start the container:

   ```bash
   docker-compose up -d
   ```

4. Access the management interface:
   - URL: [http://rabbitmq.local:15672](http://rabbitmq.local:15672) or [http://localhost:15672](http://localhost:15672)
   - Username: admin (or the value set in .env)
   - Password: password (or the value set in .env)

### Using Docker Directly

1. Build the image:

   ```bash
   docker build -t raspiska/rabbitmq:latest .
   ```

2. Run the container:

   ```bash
   docker run -d --name raspiska_rabbitmq \
     -p 5672:5672 -p 15672:15672 \
     -e RABBITMQ_DEFAULT_USER=admin \
     -e RABBITMQ_DEFAULT_PASS=password \
     -v rabbitmq_data:/var/lib/rabbitmq \
     raspiska/rabbitmq:latest
   ```

## Ports

- 5672: AMQP protocol
- 15672: Management UI

## Volumes

- `/var/lib/rabbitmq`: Data persistence

## Health Check

The container includes a health check that verifies RabbitMQ is running properly.
