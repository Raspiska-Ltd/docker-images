#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Raspiska Tech Jenkins CI/CD Setup ===${NC}"

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

# Configure Traefik for Jenkins
echo -e "\n${YELLOW}Configuring Traefik for Jenkins...${NC}"
if [ -d "/Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic" ]; then
    cat > "/Users/mali/Projects/raspiska/docker-images/traefik/config/dynamic/jenkins.yml" << EOF
http:
  routers:
    # Jenkins Router
    jenkins:
      rule: "Host(\`jenkins.raspiska.local\`)"
      service: "jenkins"
      entryPoints:
        - "web"
      middlewares:
        - "jenkins-stripprefix"
        - "secure-headers"

  services:
    # Jenkins Service
    jenkins:
      loadBalancer:
        servers:
          - url: "http://raspiska_jenkins:8080"
        passHostHeader: true

  middlewares:
    # Jenkins Strip Prefix Middleware
    jenkins-stripprefix:
      stripPrefix:
        prefixes:
          - "/jenkins"
EOF
    check_status "Traefik configuration for Jenkins"
    
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
echo -e "\n${YELLOW}Starting Jenkins containers...${NC}"
docker-compose up -d
check_status "Container startup"

# Wait for Jenkins to fully start
echo -e "\n${YELLOW}Waiting for Jenkins to start (60 seconds)...${NC}"
sleep 60

# Check if the containers are running
echo -e "\n${YELLOW}Checking container status...${NC}"
JENKINS_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_jenkins)
AGENT_STATUS=$(docker inspect --format='{{.State.Status}}' raspiska_jenkins_agent)

if [ "$JENKINS_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ Jenkins container is running${NC}"
else
    echo -e "${RED}✗ Jenkins container is not running${NC}"
    echo -e "Status: $JENKINS_STATUS"
    exit 1
fi

if [ "$AGENT_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ Jenkins Agent container is running${NC}"
else
    echo -e "${RED}✗ Jenkins Agent container is not running${NC}"
    echo -e "Status: $AGENT_STATUS"
    exit 1
fi

# Check if Jenkins is responding
echo -e "\n${YELLOW}Checking Jenkins connectivity...${NC}"
if curl -s -f http://localhost:8080/jenkins > /dev/null; then
    echo -e "${GREEN}✓ Jenkins is responding${NC}"
else
    echo -e "${RED}✗ Jenkins is not responding${NC}"
    echo -e "${YELLOW}Note: Jenkins might still be initializing. Try accessing it manually after a few minutes.${NC}"
fi

# Add hosts entries if they don't exist
echo -e "\n${YELLOW}Checking /etc/hosts entries...${NC}"
if ! grep -q "jenkins.raspiska.local" /etc/hosts; then
    echo -e "${YELLOW}To add hostnames to /etc/hosts, run:${NC}"
    echo -e "sudo sh -c 'echo \"127.0.0.1 jenkins.raspiska.local\" >> /etc/hosts'"
fi

# Configure Kong to route to Jenkins
echo -e "\n${YELLOW}Configuring Kong for Jenkins...${NC}"
if docker ps | grep -q "raspiska_kong"; then
    # Create a service in Kong for Jenkins
    curl -s -i -X POST http://localhost:8001/services \
      --data "name=jenkins" \
      --data "url=http://raspiska_jenkins:8080/jenkins" > /dev/null
    
    # Create a route for the Jenkins service
    curl -s -i -X POST http://localhost:8001/services/jenkins/routes \
      --data "name=jenkins-route" \
      --data "paths[]=/jenkins" > /dev/null
    
    echo -e "${GREEN}✓ Kong configuration for Jenkins created${NC}"
    echo -e "${YELLOW}Jenkins is now accessible through Kong at: http://kong.raspiska.local/jenkins${NC}"
else
    echo -e "${YELLOW}Kong is not running. Skipping Kong configuration.${NC}"
fi

# Get the initial admin password
JENKINS_ADMIN_PASSWORD=$(grep JENKINS_ADMIN_PASSWORD .env | cut -d '=' -f2)
if [ -z "$JENKINS_ADMIN_PASSWORD" ]; then
    JENKINS_ADMIN_PASSWORD="secure_jenkins_password"
fi

echo -e "\n${GREEN}=== Jenkins CI/CD setup completed successfully! ===${NC}"
echo -e "Jenkins is running at: http://localhost:8181/jenkins"
echo -e "\nWith Traefik:"
echo -e "Jenkins: http://jenkins.raspiska.local/jenkins"
echo -e "\nWith Kong:"
echo -e "Jenkins: http://kong.raspiska.local/jenkins"
echo -e "\nLogin credentials:"
echo -e "Username: admin"
echo -e "Password: $JENKINS_ADMIN_PASSWORD"
echo -e "\nTo view Jenkins logs:"
echo -e "docker logs raspiska_jenkins"
