FROM valkey/valkey:latest

# Set labels for better container management
LABEL maintainer="Raspiska Tech <mali@raspiska.co>"
LABEL description="Valkey with persistence, Sentinel, and monitoring for Raspiska Tech"

# Install additional tools for monitoring and management
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    procps \
    net-tools \
    supervisor \
    gettext-base \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Create directories for Valkey data and configuration
RUN mkdir -p /valkey-data /valkey-conf /sentinel-conf

# Copy custom configuration files
COPY valkey.conf /valkey-conf/valkey.conf
COPY sentinel.conf /sentinel-conf/sentinel.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh

# Set permissions
RUN chown -R valkey:valkey /valkey-data /valkey-conf /sentinel-conf && \
    chmod 777 /valkey-conf /sentinel-conf && \
    chmod +x /entrypoint.sh

# Expose Valkey and Sentinel ports
EXPOSE 6379 26379

# Set up a health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD valkey-cli ping || exit 1

# Set the entrypoint to run our script which will handle environment variable substitution
ENTRYPOINT ["/entrypoint.sh"]
