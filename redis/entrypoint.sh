#!/bin/bash
set -e

# Function to substitute environment variables in configuration files
substitute_env_vars() {
    local file=$1
    echo "Configuring $file..."
    
    # Replace environment variables in the configuration file
    envsubst < "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    
    echo "Configuration of $file completed."
}

# Process Redis configuration file
substitute_env_vars /redis-conf/redis.conf

# Create a writable sentinel.conf at runtime
echo "Creating writable sentinel.conf..."
mkdir -p /tmp/sentinel
envsubst < /sentinel-conf/sentinel.conf > /tmp/sentinel/sentinel.conf
chown -R redis:redis /tmp/sentinel
chmod 777 /tmp/sentinel /tmp/sentinel/sentinel.conf

# Start supervisord
echo "Starting supervisord..."
exec supervisord -c /etc/supervisord.conf
