#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Raspiska Tech Valkey Container Setup ===${NC}"

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
echo -e "\n${YELLOW}Building Valkey container...${NC}"
docker-compose build --no-cache
check_status "Container build"

# Start the container
echo -e "\n${YELLOW}Starting Valkey container...${NC}"
docker-compose up -d
check_status "Container startup"

# Wait for Valkey to fully start
echo -e "\n${YELLOW}Waiting for Valkey to start (5 seconds)...${NC}"
sleep 5

# Check if the container is running
echo -e "\n${YELLOW}Checking container status...${NC}"
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_valkey)
if [ "$CONTAINER_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ Container is running${NC}"
else
    echo -e "${RED}✗ Container is not running${NC}"
    exit 1
fi

# Get password from .env file
if [ -f .env ]; then
    source .env
    PASSWORD=${VALKEY_PASSWORD}
else
    PASSWORD="secure_valkey_password"
fi

# Check if Valkey is responding to ping
echo -e "\n${YELLOW}Checking Valkey connectivity...${NC}"
PING_RESULT=$(docker exec raspiska_valkey valkey-cli -a "$PASSWORD" ping)
if [ "$PING_RESULT" = "PONG" ]; then
    echo -e "${GREEN}✓ Valkey is responding to ping${NC}"
else
    echo -e "${RED}✗ Valkey is not responding to ping${NC}"
    exit 1
fi

# Check if persistence is configured correctly
echo -e "\n${YELLOW}Checking Valkey persistence configuration...${NC}"
PERSISTENCE_CONFIG=$(docker exec raspiska_valkey valkey-cli -a "$PASSWORD" config get appendonly | grep yes)
if [ -n "$PERSISTENCE_CONFIG" ]; then
    echo -e "${GREEN}✓ Valkey persistence (AOF) is configured correctly${NC}"
else
    echo -e "${RED}✗ Valkey persistence (AOF) is not configured correctly${NC}"
    exit 1
fi

# Check RDB persistence
RDB_CONFIG=$(docker exec raspiska_valkey valkey-cli -a "$PASSWORD" config get save | grep -v "^save$")
echo -e "${GREEN}✓ Valkey persistence (RDB) configuration: $RDB_CONFIG${NC}"

# Test setting and getting a key
echo -e "\n${YELLOW}Testing Valkey operations...${NC}"
SET_RESULT=$(docker exec raspiska_valkey valkey-cli -a "$PASSWORD" set test_key "Hello Raspiska!")
if [ "$SET_RESULT" = "OK" ]; then
    echo -e "${GREEN}✓ Successfully set test key${NC}"
    
    GET_RESULT=$(docker exec raspiska_valkey valkey-cli -a "$PASSWORD" get test_key)
    if [ "$GET_RESULT" = "Hello Raspiska!" ]; then
        echo -e "${GREEN}✓ Successfully retrieved test key${NC}"
    else
        echo -e "${RED}✗ Failed to retrieve test key${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Failed to set test key${NC}"
    exit 1
fi

# Check memory limits
echo -e "\n${YELLOW}Checking Valkey memory configuration...${NC}"
MEMORY_LIMIT=$(docker exec raspiska_valkey valkey-cli -a "$PASSWORD" config get maxmemory | grep -v "^maxmemory$")
echo -e "${GREEN}✓ Valkey memory limit: $MEMORY_LIMIT${NC}"

MEMORY_POLICY=$(docker exec raspiska_valkey valkey-cli -a "$PASSWORD" config get maxmemory-policy | grep -v "^maxmemory-policy$")
echo -e "${GREEN}✓ Valkey memory policy: $MEMORY_POLICY${NC}"

# Get Sentinel name from .env file
if [ -f .env ]; then
    source .env
    SENTINEL_NAME=${VALKEY_SENTINEL_NAME:-mymaster}
else
    SENTINEL_NAME="mymaster"
fi

# Check if Sentinel is running
echo -e "\n${YELLOW}Checking Valkey Sentinel...${NC}"
SENTINEL_PING=$(docker exec raspiska_valkey valkey-cli -p 26379 ping)
if [ "$SENTINEL_PING" = "PONG" ]; then
    echo -e "${GREEN}✓ Valkey Sentinel is running${NC}"
    
    # Check Sentinel monitoring status
    SENTINEL_MASTERS=$(docker exec raspiska_valkey valkey-cli -p 26379 sentinel masters)
    echo -e "${GREEN}✓ Sentinel is monitoring: $SENTINEL_MASTERS${NC}"
    
    # Get Sentinel info
    echo -e "${YELLOW}Sentinel information:${NC}"
    docker exec raspiska_valkey valkey-cli -p 26379 info | grep sentinel_
    
    # Check Sentinel master status
    MASTER_STATUS=$(docker exec raspiska_valkey valkey-cli -p 26379 sentinel master "$SENTINEL_NAME")
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Sentinel master configuration is correct${NC}"
    else
        echo -e "${RED}✗ Sentinel master configuration issue${NC}"
    fi
else
    echo -e "${RED}✗ Valkey Sentinel is not running${NC}"
    exit 1
fi

# Display Valkey info
echo -e "\n${YELLOW}Valkey server information:${NC}"
docker exec raspiska_valkey valkey-cli -a "$PASSWORD" info server | grep valkey_version
docker exec raspiska_valkey valkey-cli -a "$PASSWORD" info server | grep os

echo -e "\n${GREEN}=== Valkey setup completed successfully! ===${NC}"
echo -e "Valkey is running at: valkey://localhost:6380"
echo -e "Valkey Sentinel is running at: valkey://localhost:26380"
echo -e "Password: $PASSWORD"
echo -e "\nTo add hostname to /etc/hosts:"
echo -e "sudo sh -c 'echo \"127.0.0.1 valkey.local\" >> /etc/hosts'"
echo -e "\nTo connect to Valkey CLI:"
echo -e "docker exec -it raspiska_valkey valkey-cli -a $PASSWORD"
echo -e "\nTo connect to Valkey Sentinel CLI:"
echo -e "docker exec -it raspiska_valkey valkey-cli -p 26379"
