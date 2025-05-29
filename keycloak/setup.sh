#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Raspiska Tech Keycloak Setup ===${NC}"

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
echo -e "\n${YELLOW}Starting Keycloak containers...${NC}"
docker-compose up -d
check_status "Container startup"

# Wait for Keycloak to fully start
echo -e "\n${YELLOW}Waiting for Keycloak to start (30 seconds)...${NC}"
sleep 30

# Check if the containers are running
echo -e "\n${YELLOW}Checking container status...${NC}"
KEYCLOAK_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_keycloak)
DB_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_keycloak_db)

if [ "$KEYCLOAK_STATUS" = "running" ] && [ "$DB_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ All containers are running${NC}"
else
    echo -e "${RED}✗ Some containers are not running${NC}"
    echo -e "Keycloak: $KEYCLOAK_STATUS, Database: $DB_STATUS"
    exit 1
fi

# Check if Keycloak is responding
echo -e "\n${YELLOW}Checking Keycloak connectivity...${NC}"
KEYCLOAK_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8180/auth/)
if [ "$KEYCLOAK_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Keycloak is responding${NC}"
else
    echo -e "${RED}✗ Keycloak is not responding (HTTP $KEYCLOAK_RESPONSE)${NC}"
    echo -e "${YELLOW}Note: Keycloak might still be initializing. Try accessing it manually after a few minutes.${NC}"
fi

# Add hosts entries if they don't exist
echo -e "\n${YELLOW}Checking /etc/hosts entries...${NC}"
if ! grep -q "keycloak.raspiska.local" /etc/hosts; then
    echo -e "${YELLOW}To add hostnames to /etc/hosts, run:${NC}"
    echo -e "sudo sh -c 'echo \"127.0.0.1 keycloak.raspiska.local\" >> /etc/hosts'"
fi

# Configure Traefik to route to Keycloak
echo -e "\n${YELLOW}Configuring Traefik for Keycloak...${NC}"
if [ -d "/Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic" ]; then
    cat > /Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic/keycloak.yml << EOF
http:
  routers:
    # Keycloak Router
    keycloak:
      rule: "Host(\`keycloak.raspiska.local\`)"
      service: keycloak
      entryPoints:
        - web
      middlewares:
        - secure-headers

  services:
    # Keycloak Service
    keycloak:
      loadBalancer:
        servers:
          - url: "http://raspiska_keycloak:8080"
        passHostHeader: true
EOF
    echo -e "${GREEN}✓ Traefik configuration for Keycloak created${NC}"
    
    # Restart Traefik to apply changes
    docker restart raspiska_traefik
    check_status "Traefik restart"
else
    echo -e "${YELLOW}Traefik configuration directory not found. Skipping Traefik configuration.${NC}"
fi

# Configure Kong to route to Keycloak
echo -e "\n${YELLOW}Configuring Kong for Keycloak...${NC}"
if docker ps | grep -q "raspiska_kong"; then
    # Create a service in Kong for Keycloak
    curl -s -i -X POST http://localhost:8001/services \
      --data "name=keycloak" \
      --data "url=http://raspiska_keycloak:8080/auth" > /dev/null
    
    # Create a route for the Keycloak service
    curl -s -i -X POST http://localhost:8001/services/keycloak/routes \
      --data "name=keycloak-route" \
      --data "paths[]=/keycloak" > /dev/null
    
    echo -e "${GREEN}✓ Kong configuration for Keycloak created${NC}"
    echo -e "${YELLOW}Keycloak is now accessible through Kong at: http://kong.raspiska.local/keycloak${NC}"
else
    echo -e "${YELLOW}Kong is not running. Skipping Kong configuration.${NC}"
fi

echo -e "\n${GREEN}=== Keycloak setup completed successfully! ===${NC}"
echo -e "Keycloak is running at: http://localhost:8180/auth"
echo -e "Admin Console: http://localhost:8180/auth/admin"
echo -e "Admin Username: $(grep KEYCLOAK_ADMIN .env | cut -d= -f2)"
echo -e "Admin Password: $(grep KEYCLOAK_ADMIN_PASSWORD .env | cut -d= -f2)"
echo -e "\nWith Traefik:"
echo -e "Keycloak: http://keycloak.raspiska.local/auth"
echo -e "Admin Console: http://keycloak.raspiska.local/auth/admin"
echo -e "\nWith Kong:"
echo -e "Keycloak: http://kong.raspiska.local/keycloak"
echo -e "\nTo view Keycloak logs:"
echo -e "docker logs raspiska_keycloak"
