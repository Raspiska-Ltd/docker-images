#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Raspiska Tech Uptime Kuma Setup ===${NC}"

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
echo -e "\n${YELLOW}Starting Uptime Kuma container...${NC}"
docker-compose up -d
check_status "Container startup"

# Wait for Uptime Kuma to fully start
echo -e "\n${YELLOW}Waiting for Uptime Kuma to start (30 seconds)...${NC}"
sleep 30

# Check if the container is running
echo -e "\n${YELLOW}Checking container status...${NC}"
UPTIME_KUMA_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_uptime_kuma)

if [ "$UPTIME_KUMA_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ Uptime Kuma container is running${NC}"
else
    echo -e "${RED}✗ Uptime Kuma container is not running${NC}"
    echo -e "Status: $UPTIME_KUMA_STATUS"
    exit 1
fi

# Check if Uptime Kuma is responding
echo -e "\n${YELLOW}Checking Uptime Kuma connectivity...${NC}"
UPTIME_KUMA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/)
if [ "$UPTIME_KUMA_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Uptime Kuma is responding${NC}"
else
    echo -e "${RED}✗ Uptime Kuma is not responding (HTTP $UPTIME_KUMA_RESPONSE)${NC}"
    echo -e "${YELLOW}Note: Uptime Kuma might still be initializing. Try accessing it manually after a few minutes.${NC}"
fi

# Add hosts entries if they don't exist
echo -e "\n${YELLOW}Checking /etc/hosts entries...${NC}"
if ! grep -q "status.raspiska.local" /etc/hosts; then
    echo -e "${YELLOW}To add hostnames to /etc/hosts, run:${NC}"
    echo -e "sudo sh -c 'echo \"127.0.0.1 status.raspiska.local\" >> /etc/hosts'"
fi

# Configure Traefik to route to Uptime Kuma
echo -e "\n${YELLOW}Configuring Traefik for Uptime Kuma...${NC}"
if [ -d "/Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic" ]; then
    cat > /Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic/uptime-kuma.yml << EOF
http:
  routers:
    # Uptime Kuma Router
    uptime-kuma:
      rule: "Host(\`status.raspiska.local\`)"
      service: uptime-kuma
      entryPoints:
        - web
      middlewares:
        - secure-headers

  services:
    # Uptime Kuma Service
    uptime-kuma:
      loadBalancer:
        servers:
          - url: "http://raspiska_uptime_kuma:3001"
        passHostHeader: true
EOF
    echo -e "${GREEN}✓ Traefik configuration for Uptime Kuma created${NC}"
    
    # Restart Traefik to apply changes
    docker restart raspiska_traefik
    check_status "Traefik restart"
else
    echo -e "${YELLOW}Traefik configuration directory not found. Skipping Traefik configuration.${NC}"
fi

# Configure Kong to route to Uptime Kuma
echo -e "\n${YELLOW}Configuring Kong for Uptime Kuma...${NC}"
if docker ps | grep -q "raspiska_kong"; then
    # Create a service in Kong for Uptime Kuma
    curl -s -i -X POST http://localhost:8001/services \
      --data "name=uptime-kuma" \
      --data "url=http://raspiska_uptime_kuma:3001" > /dev/null
    
    # Create a route for the Uptime Kuma service
    curl -s -i -X POST http://localhost:8001/services/uptime-kuma/routes \
      --data "name=uptime-kuma-route" \
      --data "paths[]=/status" > /dev/null
    
    echo -e "${GREEN}✓ Kong configuration for Uptime Kuma created${NC}"
    echo -e "${YELLOW}Uptime Kuma is now accessible through Kong at: http://kong.raspiska.local/status${NC}"
else
    echo -e "${YELLOW}Kong is not running. Skipping Kong configuration.${NC}"
fi

echo -e "\n${GREEN}=== Uptime Kuma setup completed successfully! ===${NC}"
echo -e "Uptime Kuma is running at: http://localhost:3001"
echo -e "\nWith Traefik:"
echo -e "Uptime Kuma: http://status.raspiska.local"
echo -e "\nWith Kong:"
echo -e "Uptime Kuma: http://kong.raspiska.local/status"
echo -e "\nTo view Uptime Kuma logs:"
echo -e "docker logs raspiska_uptime_kuma"
