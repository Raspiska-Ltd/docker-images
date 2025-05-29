#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Raspiska Tech n8n Workflow Automation Setup ===${NC}"

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        exit 1
    fi
}

# Create workflows directory if it doesn't exist
echo -e "\n${YELLOW}Creating workflows directory...${NC}"
mkdir -p workflows
check_status "Workflows directory creation"

# Stop and remove existing containers
echo -e "\n${YELLOW}Stopping and removing existing containers...${NC}"
docker-compose down
check_status "Container cleanup"

# Start the containers
echo -e "\n${YELLOW}Starting n8n containers...${NC}"
docker-compose up -d
check_status "Container startup"

# Wait for n8n to fully start
echo -e "\n${YELLOW}Waiting for n8n to start (30 seconds)...${NC}"
sleep 30

# Check if the containers are running
echo -e "\n${YELLOW}Checking container status...${NC}"
N8N_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_n8n)
DB_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_n8n_db)

if [ "$N8N_STATUS" = "running" ] && [ "$DB_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ All containers are running${NC}"
else
    echo -e "${RED}✗ Some containers are not running${NC}"
    echo -e "n8n: $N8N_STATUS, Database: $DB_STATUS"
    exit 1
fi

# Check if n8n is responding
echo -e "\n${YELLOW}Checking n8n connectivity...${NC}"
N8N_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5678)
if [ "$N8N_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ n8n is responding${NC}"
else
    echo -e "${RED}✗ n8n is not responding (HTTP $N8N_RESPONSE)${NC}"
    echo -e "${YELLOW}Note: n8n might still be initializing. Try accessing it manually after a few minutes.${NC}"
fi

# Add hosts entries if they don't exist
echo -e "\n${YELLOW}Checking /etc/hosts entries...${NC}"
if ! grep -q "n8n.raspiska.local" /etc/hosts; then
    echo -e "${YELLOW}To add hostnames to /etc/hosts, run:${NC}"
    echo -e "sudo sh -c 'echo \"127.0.0.1 n8n.raspiska.local\" >> /etc/hosts'"
fi

# Configure Traefik to route to n8n
echo -e "\n${YELLOW}Configuring Traefik for n8n...${NC}"
if [ -d "/Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic" ]; then
    cat > /Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic/n8n.yml << EOF
http:
  routers:
    # n8n Router
    n8n:
      rule: "Host(\`n8n.raspiska.local\`)"
      service: n8n
      entryPoints:
        - web
      middlewares:
        - secure-headers

  services:
    # n8n Service
    n8n:
      loadBalancer:
        servers:
          - url: "http://raspiska_n8n:5678"
        passHostHeader: true
EOF
    echo -e "${GREEN}✓ Traefik configuration for n8n created${NC}"
    
    # Restart Traefik to apply changes
    docker restart raspiska_traefik
    check_status "Traefik restart"
else
    echo -e "${YELLOW}Traefik configuration directory not found. Skipping Traefik configuration.${NC}"
fi

# Configure Kong to route to n8n
echo -e "\n${YELLOW}Configuring Kong for n8n...${NC}"
if docker ps | grep -q "raspiska_kong"; then
    # Create a service in Kong for n8n
    curl -s -i -X POST http://localhost:8001/services \
      --data "name=n8n" \
      --data "url=http://raspiska_n8n:5678" > /dev/null
    
    # Create a route for the n8n service
    curl -s -i -X POST http://localhost:8001/services/n8n/routes \
      --data "name=n8n-route" \
      --data "paths[]=/n8n" > /dev/null
    
    echo -e "${GREEN}✓ Kong configuration for n8n created${NC}"
    echo -e "${YELLOW}n8n is now accessible through Kong at: http://kong.raspiska.local/n8n${NC}"
else
    echo -e "${YELLOW}Kong is not running. Skipping Kong configuration.${NC}"
fi

# Import sample workflows
echo -e "\n${YELLOW}Importing sample workflows...${NC}"
if [ -d "workflows" ]; then
    # Copy sample workflows to the workflows directory
    cp -r sample-workflows/* workflows/ 2>/dev/null || true
    echo -e "${GREEN}✓ Sample workflows imported${NC}"
else
    echo -e "${RED}✗ Workflows directory not found${NC}"
fi

echo -e "\n${GREEN}=== n8n setup completed successfully! ===${NC}"
echo -e "n8n is running at: http://localhost:5678"
echo -e "Username: $(grep N8N_BASIC_AUTH_USER .env | cut -d= -f2)"
echo -e "Password: $(grep N8N_BASIC_AUTH_PASSWORD .env | cut -d= -f2)"
echo -e "\nWith Traefik:"
echo -e "n8n: http://n8n.raspiska.local"
echo -e "\nWith Kong:"
echo -e "n8n: http://kong.raspiska.local/n8n"
echo -e "\nTo view n8n logs:"
echo -e "docker logs raspiska_n8n"
