#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Raspiska Tech RabbitMQ Container Setup ===${NC}"

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        exit 1
    fi
}

# Stop and remove existing containers and volumes
echo -e "\n${YELLOW}Stopping and removing existing containers...${NC}"
docker-compose down -v
check_status "Container cleanup"

# Build the container with no cache
echo -e "\n${YELLOW}Building RabbitMQ container...${NC}"
docker-compose build --no-cache
check_status "Container build"

# Start the container
echo -e "\n${YELLOW}Starting RabbitMQ container...${NC}"
docker-compose up -d
check_status "Container startup"

# Wait for RabbitMQ to fully start
echo -e "\n${YELLOW}Waiting for RabbitMQ to start (15 seconds)...${NC}"
sleep 15

# Check if the container is running
echo -e "\n${YELLOW}Checking container status...${NC}"
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_rabbitmq)
if [ "$CONTAINER_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ Container is running${NC}"
else
    echo -e "${RED}✗ Container is not running${NC}"
    exit 1
fi

# Check if plugins are enabled
echo -e "\n${YELLOW}Checking plugins...${NC}"
PLUGINS=$(docker exec raspiska_rabbitmq rabbitmq-plugins list | grep -E 'management|consistent_hash|delayed_message|shovel')
echo "$PLUGINS"

# Check if management interface is accessible
echo -e "\n${YELLOW}Checking management interface...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:15672)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Management interface is accessible (HTTP 200)${NC}"
else
    echo -e "${RED}✗ Management interface is not accessible (HTTP $HTTP_CODE)${NC}"
    exit 1
fi

# Check if admin user can log in
echo -e "\n${YELLOW}Checking admin login...${NC}"
# Get credentials from .env file
if [ -f .env ]; then
    source .env
    USERNAME=${RABBITMQ_DEFAULT_USER:-admin}
    PASSWORD=${RABBITMQ_DEFAULT_PASS:-admin}
else
    USERNAME="admin"
    PASSWORD="admin"
fi

LOGIN_CHECK=$(curl -s -o /dev/null -w "%{http_code}" -u "$USERNAME:$PASSWORD" http://localhost:15672/api/overview)
if [ "$LOGIN_CHECK" = "200" ]; then
    echo -e "${GREEN}✓ Admin login successful${NC}"
else
    echo -e "${RED}✗ Admin login failed (HTTP $LOGIN_CHECK)${NC}"
    exit 1
fi

echo -e "\n${GREEN}=== RabbitMQ setup completed successfully! ===${NC}"
echo -e "Management UI: http://localhost:15672"
echo -e "Username: $USERNAME"
echo -e "Password: $PASSWORD"
echo -e "\nTo add hostname to /etc/hosts:"
echo -e "sudo sh -c 'echo \"127.0.0.1 rabbitmq.local\" >> /etc/hosts'"
