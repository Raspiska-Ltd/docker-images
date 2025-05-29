#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Raspiska Tech Traefik Container Setup ===${NC}"

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

# Create necessary directories if they don't exist
echo -e "\n${YELLOW}Creating necessary directories...${NC}"
mkdir -p config/dynamic certs logs
check_status "Directory creation"

# Set proper permissions
echo -e "\n${YELLOW}Setting proper permissions...${NC}"
chmod -R 755 config
chmod -R 755 certs
chmod -R 755 logs
check_status "Permission setup"

# Start the container
echo -e "\n${YELLOW}Starting Traefik container...${NC}"
docker-compose up -d
check_status "Container startup"

# Wait for Traefik to fully start
echo -e "\n${YELLOW}Waiting for Traefik to start (5 seconds)...${NC}"
sleep 5

# Check if the container is running
echo -e "\n${YELLOW}Checking container status...${NC}"
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_traefik)
if [ "$CONTAINER_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ Container is running${NC}"
else
    echo -e "${RED}✗ Container is not running${NC}"
    exit 1
fi

# Check if Traefik dashboard is accessible
echo -e "\n${YELLOW}Checking Traefik dashboard...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/dashboard/ | grep -q "200"; then
    echo -e "${GREEN}✓ Traefik dashboard is accessible${NC}"
else
    echo -e "${RED}✗ Traefik dashboard is not accessible${NC}"
    # This is not a critical error, so we don't exit
    echo -e "${YELLOW}Note: You may need to add 'traefik.raspiska.local' to your /etc/hosts file${NC}"
fi

# Add hosts entries if they don't exist
echo -e "\n${YELLOW}Checking /etc/hosts entries...${NC}"
if ! grep -q "traefik.raspiska.local" /etc/hosts; then
    echo -e "${YELLOW}To add hostnames to /etc/hosts, run:${NC}"
    echo -e "sudo sh -c 'echo \"127.0.0.1 traefik.raspiska.local redis.raspiska.local valkey.raspiska.local\" >> /etc/hosts'"
fi

echo -e "\n${GREEN}=== Traefik setup completed successfully! ===${NC}"
echo -e "Traefik dashboard is available at: http://traefik.raspiska.local:8080 or http://localhost:8080"
echo -e "Services are available at:"
echo -e "- Redis: http://redis.raspiska.local"
echo -e "- Valkey: http://valkey.raspiska.local"
echo -e "\nTo view Traefik logs:"
echo -e "docker logs raspiska_traefik"
echo -e "\nTo add a new service to Traefik, see the README.md for instructions."
