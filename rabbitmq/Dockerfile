FROM rabbitmq:management-alpine

# Set environment variables
ENV RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER:-admin}
ENV RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS:-admin}
ENV RABBITMQ_DEFAULT_VHOST=${RABBITMQ_DEFAULT_VHOST:-/}

# Install necessary tools
USER root
RUN apk add --no-cache curl

# Download and install the delayed message exchange plugin
RUN set -eux; \
    curl -fsSL -o /opt/rabbitmq/plugins/rabbitmq_delayed_message_exchange-4.1.0.ez https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v4.1.0/rabbitmq_delayed_message_exchange-4.1.0.ez; \
    chown rabbitmq:rabbitmq /opt/rabbitmq/plugins/rabbitmq_delayed_message_exchange-4.1.0.ez; \
    chmod 644 /opt/rabbitmq/plugins/rabbitmq_delayed_message_exchange-4.1.0.ez

# Switch back to rabbitmq user
USER rabbitmq

# Enable plugins
RUN rabbitmq-plugins enable --offline \
    rabbitmq_management \
    rabbitmq_consistent_hash_exchange \
    rabbitmq_delayed_message_exchange \
    rabbitmq_shovel \
    rabbitmq_shovel_management

# Expose ports
EXPOSE 5672 15672

# Set the entrypoint
CMD ["rabbitmq-server"]
