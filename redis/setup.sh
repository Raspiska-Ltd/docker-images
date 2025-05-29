#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Raspiska Tech Redis Container Setup ===${NC}"

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
echo -e "\n${YELLOW}Building Redis container...${NC}"
docker-compose build --no-cache
check_status "Container build"

# Start the container
echo -e "\n${YELLOW}Starting Redis container...${NC}"
docker-compose up -d
check_status "Container startup"

# Wait for Redis to fully start
echo -e "\n${YELLOW}Waiting for Redis to start (5 seconds)...${NC}"
sleep 5

# Check if the container is running
echo -e "\n${YELLOW}Checking container status...${NC}"
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_redis)
if [ "$CONTAINER_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ Container is running${NC}"
else
    echo -e "${RED}✗ Container is not running${NC}"
    exit 1
fi

# Get password from .env file
if [ -f .env ]; then
    source .env
    PASSWORD=${REDIS_PASSWORD}
else
    PASSWORD="secure_redis_password"
fi

# Check if Redis is responding to ping
echo -e "\n${YELLOW}Checking Redis connectivity...${NC}"
PING_RESULT=$(docker exec raspiska_redis redis-cli -a "$PASSWORD" ping)
if [ "$PING_RESULT" = "PONG" ]; then
    echo -e "${GREEN}✓ Redis is responding to ping${NC}"
else
    echo -e "${RED}✗ Redis is not responding to ping${NC}"
    exit 1
fi

# Check if persistence is configured correctly
echo -e "\n${YELLOW}Checking Redis persistence configuration...${NC}"
PERSISTENCE_CONFIG=$(docker exec raspiska_redis redis-cli -a "$PASSWORD" config get appendonly | grep yes)
if [ -n "$PERSISTENCE_CONFIG" ]; then
    echo -e "${GREEN}✓ Redis persistence (AOF) is configured correctly${NC}"
else
    echo -e "${RED}✗ Redis persistence (AOF) is not configured correctly${NC}"
    exit 1
fi

# Check RDB persistence
RDB_CONFIG=$(docker exec raspiska_redis redis-cli -a "$PASSWORD" config get save | grep -v "^save$")
echo -e "${GREEN}✓ Redis persistence (RDB) configuration: $RDB_CONFIG${NC}"

# Test setting and getting a key
echo -e "\n${YELLOW}Testing Redis operations...${NC}"
SET_RESULT=$(docker exec raspiska_redis redis-cli -a "$PASSWORD" set test_key "Hello Raspiska!")
if [ "$SET_RESULT" = "OK" ]; then
    echo -e "${GREEN}✓ Successfully set test key${NC}"
    
    GET_RESULT=$(docker exec raspiska_redis redis-cli -a "$PASSWORD" get test_key)
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
echo -e "\n${YELLOW}Checking Redis memory configuration...${NC}"
MEMORY_LIMIT=$(docker exec raspiska_redis redis-cli -a "$PASSWORD" config get maxmemory | grep -v "^maxmemory$")
echo -e "${GREEN}✓ Redis memory limit: $MEMORY_LIMIT${NC}"

MEMORY_POLICY=$(docker exec raspiska_redis redis-cli -a "$PASSWORD" config get maxmemory-policy | grep -v "^maxmemory-policy$")
echo -e "${GREEN}✓ Redis memory policy: $MEMORY_POLICY${NC}"

# Display Redis info
echo -e "\n${YELLOW}Redis server information:${NC}"
docker exec raspiska_redis redis-cli -a "$PASSWORD" info server | grep redis_version
docker exec raspiska_redis redis-cli -a "$PASSWORD" info server | grep os

# Get Sentinel name from .env file
if [ -f .env ]; then
    source .env
    SENTINEL_NAME=${REDIS_SENTINEL_NAME:-mymaster}
else
    SENTINEL_NAME="mymaster"
fi

# Check if Sentinel is running
echo -e "\n${YELLOW}Checking Redis Sentinel...${NC}"
SENTINEL_PING=$(docker exec raspiska_redis redis-cli -p 26379 ping)
if [ "$SENTINEL_PING" = "PONG" ]; then
    echo -e "${GREEN}✓ Redis Sentinel is running${NC}"
    
    # Check Sentinel monitoring status
    SENTINEL_MASTERS=$(docker exec raspiska_redis redis-cli -p 26379 sentinel masters)
    echo -e "${GREEN}✓ Sentinel is monitoring: $SENTINEL_MASTERS${NC}"
    
    # Get Sentinel info
    echo -e "${YELLOW}Sentinel information:${NC}"
    docker exec raspiska_redis redis-cli -p 26379 info | grep sentinel_
    
    # Check Sentinel master status
    MASTER_STATUS=$(docker exec raspiska_redis redis-cli -p 26379 sentinel master "$SENTINEL_NAME")
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Sentinel master configuration is correct${NC}"
    else
        echo -e "${RED}✗ Sentinel master configuration issue${NC}"
    fi
else
    echo -e "${RED}✗ Redis Sentinel is not running${NC}"
    exit 1
fi

echo -e "\n${GREEN}=== Redis setup completed successfully! ===${NC}"
echo -e "Redis is running at: redis://localhost:6379"
echo -e "Redis Sentinel is running at: redis://localhost:26379"
echo -e "Password: $PASSWORD"
echo -e "\nTo add hostname to /etc/hosts:"
echo -e "sudo sh -c 'echo \"127.0.0.1 redis.local\" >> /etc/hosts'"
echo -e "\nTo connect to Redis CLI:"
echo -e "docker exec -it raspiska_redis redis-cli -a $PASSWORD"
echo -e "\nTo connect to Redis Sentinel CLI:"
echo -e "docker exec -it raspiska_redis redis-cli -p 26379"
