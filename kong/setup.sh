#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Raspiska Tech Kong API Gateway Setup ===${NC}"

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        exit 1
    fi
}

# Stop and remove existing containers
echo -e "\n${YELLOW}Stopping and removing existing containers...${NC}"
docker-compose down
check_status "Container cleanup"

# Start the containers
echo -e "\n${YELLOW}Starting Kong containers...${NC}"
docker-compose up -d
check_status "Container startup"

# Wait for Kong to fully start
echo -e "\n${YELLOW}Waiting for Kong to start (30 seconds)...${NC}"
sleep 30

# Check if the containers are running
echo -e "\n${YELLOW}Checking container status...${NC}"
KONG_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_kong)
DB_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_kong_db)

if [ "$KONG_STATUS" = "running" ] && [ "$DB_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ All containers are running${NC}"
else
    echo -e "${RED}✗ Some containers are not running${NC}"
    echo -e "Kong: $KONG_STATUS, Database: $DB_STATUS"
    exit 1
fi

# Check if Kong is responding
echo -e "\n${YELLOW}Checking Kong connectivity...${NC}"
KONG_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001)
if [ "$KONG_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Kong Admin API is responding${NC}"
else
    echo -e "${RED}✗ Kong Admin API is not responding (HTTP $KONG_RESPONSE)${NC}"
    exit 1
fi

# Konga check removed as we're not using Konga

# Add hosts entries if they don't exist
echo -e "\n${YELLOW}Checking /etc/hosts entries...${NC}"
if ! grep -q "kong.raspiska.local" /etc/hosts; then
    echo -e "${YELLOW}To add hostnames to /etc/hosts, run:${NC}"
    echo -e "sudo sh -c 'echo \"127.0.0.1 kong.raspiska.local\" >> /etc/hosts'"
fi

# Configure Traefik to route to Kong
echo -e "\n${YELLOW}Configuring Traefik for Kong...${NC}"
if [ -d "/Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic" ]; then
    cat > /Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic/kong.yml << EOF
http:
  routers:
    # Kong API Gateway Router
    kong:
      rule: "Host(\`kong.raspiska.local\`)"
      service: kong
      entryPoints:
        - web
      middlewares:
        - secure-headers

    # Kong Admin API Router
    kong-admin:
      rule: "Host(\`kong-admin.raspiska.local\`)"
      service: kong-admin
      entryPoints:
        - web
      middlewares:
        - secure-headers

  services:
    # Kong API Gateway Service
    kong:
      loadBalancer:
        servers:
          - url: "http://raspiska_kong:8000"
        passHostHeader: true

    # Kong Admin API Service
    kong-admin:
      loadBalancer:
        servers:
          - url: "http://raspiska_kong:8001"
        passHostHeader: true
EOF
    echo -e "${GREEN}✓ Traefik configuration for Kong created${NC}"
    
    # Restart Traefik to apply changes
    docker restart raspiska_traefik
    check_status "Traefik restart"
else
    echo -e "${YELLOW}Traefik configuration directory not found. Skipping Traefik configuration.${NC}"
fi

echo -e "\n${GREEN}=== Kong setup completed successfully! ===${NC}"
echo -e "Kong Proxy is running at: http://localhost:8000"
echo -e "Kong Admin API is running at: http://localhost:8001"
echo -e "\nWith Traefik:"
echo -e "Kong Proxy: http://kong.raspiska.local"
echo -e "Kong Admin API: http://kong-admin.raspiska.local"
echo -e "\nTo view Kong logs:"
echo -e "docker logs raspiska_kong"
