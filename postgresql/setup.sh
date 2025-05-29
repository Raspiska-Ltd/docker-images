#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Raspiska Tech PostgreSQL Setup ===${NC}"

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        exit 1
    fi
}

# Check if Traefik network exists
echo -e "\n${YELLOW}Checking if Traefik network exists...${NC}"
if ! docker network ls | grep -q raspiska_traefik_network; then
    echo -e "${YELLOW}Creating Traefik network...${NC}"
    docker network create raspiska_traefik_network
    check_status "Traefik network creation"
else
    echo -e "${GREEN}✓ Traefik network exists${NC}"
fi

# Configure Traefik for PostgreSQL
echo -e "\n${YELLOW}Configuring Traefik for PostgreSQL...${NC}"
if [ -d "/Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic" ]; then
    # Create TCP entrypoint for PostgreSQL if it doesn't exist
    if ! grep -q "postgres:" "/Users/mali/Projects/raspiska/docker-images/traefik/config/traefik.yml"; then
        echo -e "${YELLOW}Adding PostgreSQL entrypoint to Traefik configuration...${NC}"
        cat >> "/Users/mali/Projects/raspiska/docker-images/traefik/config/traefik.yml" << EOF

  # PostgreSQL entrypoint
  postgres:
    address: ":5432"
EOF
        check_status "PostgreSQL entrypoint configuration"
    else
        echo -e "${GREEN}✓ PostgreSQL entrypoint already configured${NC}"
    fi

    # Create dynamic configuration for PostgreSQL
    cat > "/Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic/postgresql.yml" << EOF
tcp:
  routers:
    # PostgreSQL Router
    postgres:
      entryPoints:
        - "postgres"
      rule: "HostSNI(\`*\`)"
      service: "postgres"
      tls:
        passthrough: true

  services:
    # PostgreSQL Service
    postgres:
      loadBalancer:
        servers:
          - address: "raspiska_postgres:5432"
EOF
    check_status "Traefik dynamic configuration for PostgreSQL"
    
    # Create HTTP configuration for pgAdmin
    cat > "/Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic/pgadmin.yml" << EOF
http:
  routers:
    # pgAdmin Router
    pgadmin:
      rule: "Host(\`pgadmin.raspiska.local\`)"
      service: "pgadmin"
      entryPoints:
        - "web"
      middlewares:
        - "secure-headers"

  services:
    # pgAdmin Service
    pgadmin:
      loadBalancer:
        servers:
          - url: "http://raspiska_pgadmin:80"
        passHostHeader: true
EOF
    check_status "Traefik dynamic configuration for pgAdmin"
    
    # Restart Traefik to apply changes
    echo -e "${YELLOW}Restarting Traefik to apply changes...${NC}"
    docker restart raspiska_traefik
    check_status "Traefik restart"
else
    echo -e "${YELLOW}Traefik configuration directory not found. Skipping Traefik configuration.${NC}"
fi

# Stop and remove existing containers
echo -e "\n${YELLOW}Stopping and removing existing containers...${NC}"
docker-compose down
check_status "Container cleanup"

# Start the containers
echo -e "\n${YELLOW}Starting PostgreSQL containers...${NC}"
docker-compose up -d
check_status "Container startup"

# Wait for PostgreSQL to fully start
echo -e "\n${YELLOW}Waiting for PostgreSQL to start (30 seconds)...${NC}"
sleep 30

# Check if the containers are running
echo -e "\n${YELLOW}Checking container status...${NC}"
POSTGRES_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_postgres)
PGBOUNCER_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_pgbouncer)
PGADMIN_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_pgadmin)

if [ "$POSTGRES_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ PostgreSQL container is running${NC}"
else
    echo -e "${RED}✗ PostgreSQL container is not running${NC}"
    echo -e "Status: $POSTGRES_STATUS"
    exit 1
fi

if [ "$PGBOUNCER_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ PgBouncer container is running${NC}"
else
    echo -e "${RED}✗ PgBouncer container is not running${NC}"
    echo -e "Status: $PGBOUNCER_STATUS"
    exit 1
fi

if [ "$PGADMIN_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ pgAdmin container is running${NC}"
else
    echo -e "${RED}✗ pgAdmin container is not running${NC}"
    echo -e "Status: $PGADMIN_STATUS"
    exit 1
fi

# Check if PostgreSQL is responding
echo -e "\n${YELLOW}Checking PostgreSQL connectivity...${NC}"
if docker exec raspiska_postgres pg_isready -U postgres; then
    echo -e "${GREEN}✓ PostgreSQL is responding${NC}"
else
    echo -e "${RED}✗ PostgreSQL is not responding${NC}"
    exit 1
fi

# Add hosts entries if they don't exist
echo -e "\n${YELLOW}Checking /etc/hosts entries...${NC}"
if ! grep -q "pgadmin.raspiska.local" /etc/hosts; then
    echo -e "${YELLOW}To add hostnames to /etc/hosts, run:${NC}"
    echo -e "sudo sh -c 'echo \"127.0.0.1 pgadmin.raspiska.local postgres.raspiska.local\" >> /etc/hosts'"
fi

# Configure Kong to route to pgAdmin
echo -e "\n${YELLOW}Configuring Kong for pgAdmin...${NC}"
if docker ps | grep -q "raspiska_kong"; then
    # Create a service in Kong for pgAdmin
    curl -s -i -X POST http://localhost:8001/services \
      --data "name=pgadmin" \
      --data "url=http://raspiska_pgadmin:80" > /dev/null
    
    # Create a route for the pgAdmin service
    curl -s -i -X POST http://localhost:8001/services/pgadmin/routes \
      --data "name=pgadmin-route" \
      --data "paths[]=/pgadmin" > /dev/null
    
    echo -e "${GREEN}✓ Kong configuration for pgAdmin created${NC}"
    echo -e "${YELLOW}pgAdmin is now accessible through Kong at: http://kong.raspiska.local/pgadmin${NC}"
else
    echo -e "${YELLOW}Kong is not running. Skipping Kong configuration.${NC}"
fi

echo -e "\n${GREEN}=== PostgreSQL setup completed successfully! ===${NC}"
echo -e "PostgreSQL is running at: localhost:5432"
echo -e "PgBouncer is running at: localhost:6432"
echo -e "pgAdmin is running at: http://localhost:5050"
echo -e "\nWith Traefik:"
echo -e "pgAdmin: http://pgadmin.raspiska.local"
echo -e "\nWith Kong:"
echo -e "pgAdmin: http://kong.raspiska.local/pgadmin"
echo -e "\nLogin to pgAdmin with:"
echo -e "Email: $(grep PGADMIN_EMAIL .env | cut -d '=' -f2)"
echo -e "Password: $(grep PGADMIN_PASSWORD .env | cut -d '=' -f2)"
echo -e "\nTo view PostgreSQL logs:"
echo -e "docker logs raspiska_postgres"
