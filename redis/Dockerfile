FROM redis:7-alpine

# Install additional tools for monitoring and management
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    procps \
    tcpdump \
    net-tools \
    supervisor \
    gettext

# Create directories for Redis data and configuration
RUN mkdir -p /redis-data /redis-conf /sentinel-conf

# Copy custom configuration files
COPY redis.conf /redis-conf/redis.conf
COPY sentinel.conf /sentinel-conf/sentinel.conf
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /entrypoint.sh

# Set permissions
RUN chown -R redis:redis /redis-data /redis-conf /sentinel-conf && \
    chmod 777 /redis-conf /sentinel-conf

# Expose Redis and Sentinel ports
EXPOSE 6379 26379

# Set up a health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD redis-cli ping || exit 1

# Set the entrypoint to run our script which will handle environment variable substitution
ENTRYPOINT ["/entrypoint.sh"]
