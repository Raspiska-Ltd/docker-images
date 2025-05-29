#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Raspiska Tech Monitoring Setup ===${NC}"

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
echo -e "\n${YELLOW}Starting monitoring containers...${NC}"
docker-compose up -d
check_status "Container startup"

# Wait for services to fully start
echo -e "\n${YELLOW}Waiting for monitoring services to start (30 seconds)...${NC}"
sleep 30

# Check if the containers are running
echo -e "\n${YELLOW}Checking container status...${NC}"
PROMETHEUS_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_prometheus)
GRAFANA_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_grafana)
ALERTMANAGER_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_alertmanager)
NODE_EXPORTER_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_node_exporter)

if [ "$PROMETHEUS_STATUS" = "running" ] && [ "$GRAFANA_STATUS" = "running" ] && [ "$ALERTMANAGER_STATUS" = "running" ] && [ "$NODE_EXPORTER_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ All core containers are running${NC}"
else
    echo -e "${RED}✗ Some containers are not running${NC}"
    echo -e "Prometheus: $PROMETHEUS_STATUS, Grafana: $GRAFANA_STATUS, Alertmanager: $ALERTMANAGER_STATUS, Node Exporter: $NODE_EXPORTER_STATUS"
    exit 1
fi

# Check if the exporters are running
echo -e "\n${YELLOW}Checking exporter status...${NC}"
REDIS_EXPORTER_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_redis_exporter 2>/dev/null || echo "not created")
VALKEY_EXPORTER_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_valkey_exporter 2>/dev/null || echo "not created")
POSTGRES_EXPORTER_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_postgres_exporter 2>/dev/null || echo "not created")
KONG_EXPORTER_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_kong_exporter 2>/dev/null || echo "not created")

echo -e "Redis Exporter: $REDIS_EXPORTER_STATUS"
echo -e "Valkey Exporter: $VALKEY_EXPORTER_STATUS"
echo -e "Postgres Exporter: $POSTGRES_EXPORTER_STATUS"
echo -e "Kong Exporter: $KONG_EXPORTER_STATUS"

# Check if Prometheus is responding
echo -e "\n${YELLOW}Checking Prometheus connectivity...${NC}"
PROMETHEUS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/healthy)
if [ "$PROMETHEUS_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Prometheus is responding${NC}"
else
    echo -e "${RED}✗ Prometheus is not responding (HTTP $PROMETHEUS_RESPONSE)${NC}"
fi

# Check if Grafana is responding
echo -e "\n${YELLOW}Checking Grafana connectivity...${NC}"
GRAFANA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health)
if [ "$GRAFANA_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Grafana is responding${NC}"
else
    echo -e "${RED}✗ Grafana is not responding (HTTP $GRAFANA_RESPONSE)${NC}"
fi

# Add hosts entries if they don't exist
echo -e "\n${YELLOW}Checking /etc/hosts entries...${NC}"
if ! grep -q "prometheus.raspiska.local\|grafana.raspiska.local\|alertmanager.raspiska.local" /etc/hosts; then
    echo -e "${YELLOW}To add hostnames to /etc/hosts, run:${NC}"
    echo -e "sudo sh -c 'echo \"127.0.0.1 prometheus.raspiska.local grafana.raspiska.local alertmanager.raspiska.local\" >> /etc/hosts'"
fi

# Configure Traefik to route to monitoring services
echo -e "\n${YELLOW}Configuring Traefik for monitoring services...${NC}"
if [ -d "/Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic" ]; then
    cat > /Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic/monitoring.yml << EOF
http:
  routers:
    # Prometheus Router
    prometheus:
      rule: "Host(\`prometheus.raspiska.local\`)"
      service: prometheus
      entryPoints:
        - web
      middlewares:
        - secure-headers

    # Grafana Router
    grafana:
      rule: "Host(\`grafana.raspiska.local\`)"
      service: grafana
      entryPoints:
        - web
      middlewares:
        - secure-headers

    # Alertmanager Router
    alertmanager:
      rule: "Host(\`alertmanager.raspiska.local\`)"
      service: alertmanager
      entryPoints:
        - web
      middlewares:
        - secure-headers

  services:
    # Prometheus Service
    prometheus:
      loadBalancer:
        servers:
          - url: "http://raspiska_prometheus:9090"
        passHostHeader: true

    # Grafana Service
    grafana:
      loadBalancer:
        servers:
          - url: "http://raspiska_grafana:3000"
        passHostHeader: true

    # Alertmanager Service
    alertmanager:
      loadBalancer:
        servers:
          - url: "http://raspiska_alertmanager:9093"
        passHostHeader: true
EOF
    echo -e "${GREEN}✓ Traefik configuration for monitoring services created${NC}"
    
    # Restart Traefik to apply changes
    docker restart raspiska_traefik
    check_status "Traefik restart"
else
    echo -e "${YELLOW}Traefik configuration directory not found. Skipping Traefik configuration.${NC}"
fi

# Configure Kong to route to monitoring services
echo -e "\n${YELLOW}Configuring Kong for monitoring services...${NC}"
if docker ps | grep -q "raspiska_kong"; then
    # Create a service in Kong for Prometheus
    curl -s -i -X POST http://localhost:8001/services \
      --data "name=prometheus" \
      --data "url=http://raspiska_prometheus:9090" > /dev/null
    
    # Create a route for the Prometheus service
    curl -s -i -X POST http://localhost:8001/services/prometheus/routes \
      --data "name=prometheus-route" \
      --data "paths[]=/prometheus" > /dev/null
    
    # Create a service in Kong for Grafana
    curl -s -i -X POST http://localhost:8001/services \
      --data "name=grafana" \
      --data "url=http://raspiska_grafana:3000" > /dev/null
    
    # Create a route for the Grafana service
    curl -s -i -X POST http://localhost:8001/services/grafana/routes \
      --data "name=grafana-route" \
      --data "paths[]=/grafana" > /dev/null
    
    echo -e "${GREEN}✓ Kong configuration for monitoring services created${NC}"
    echo -e "${YELLOW}Monitoring services are now accessible through Kong at:${NC}"
    echo -e "Prometheus: http://kong.raspiska.local/prometheus"
    echo -e "Grafana: http://kong.raspiska.local/grafana"
else
    echo -e "${YELLOW}Kong is not running. Skipping Kong configuration.${NC}"
fi

echo -e "\n${GREEN}=== Monitoring setup completed successfully! ===${NC}"
echo -e "Prometheus is running at: http://localhost:9090"
echo -e "Grafana is running at: http://localhost:3000"
echo -e "Alertmanager is running at: http://localhost:9093"
echo -e "\nGrafana login:"
echo -e "Username: $(grep GRAFANA_ADMIN_USER .env | cut -d= -f2)"
echo -e "Password: $(grep GRAFANA_ADMIN_PASSWORD .env | cut -d= -f2)"
echo -e "\nWith Traefik:"
echo -e "Prometheus: http://prometheus.raspiska.local"
echo -e "Grafana: http://grafana.raspiska.local"
echo -e "Alertmanager: http://alertmanager.raspiska.local"
echo -e "\nWith Kong:"
echo -e "Prometheus: http://kong.raspiska.local/prometheus"
echo -e "Grafana: http://kong.raspiska.local/grafana"
echo -e "\nTo view logs:"
echo -e "docker logs raspiska_prometheus"
echo -e "docker logs raspiska_grafana"
echo -e "docker logs raspiska_alertmanager"
