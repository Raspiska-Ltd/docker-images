#!/bin/bash

# Raspiska Tech Development Environment Setup Script
# This script automates the setup of the entire Raspiska Tech infrastructure

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_IMAGES_DIR="${BASE_DIR}/docker-images"

# Function to display section headers
section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to display subsection headers
subsection() {
    echo -e "\n${CYAN}--- $1 ---${NC}"
}

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        if [ "$2" = "exit" ]; then
            exit 1
        fi
    fi
}

# Function to check if Docker is installed and running
check_docker() {
    section "Checking Docker Installation"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker is not installed${NC}"
        echo -e "${YELLOW}Please install Docker from https://docs.docker.com/get-docker/${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Docker is installed${NC}"
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}✗ Docker is not running${NC}"
        echo -e "${YELLOW}Please start Docker and try again${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Docker is running${NC}"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}✗ Docker Compose is not installed${NC}"
        echo -e "${YELLOW}Please install Docker Compose from https://docs.docker.com/compose/install/${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Docker Compose is installed${NC}"
    fi
}

# Function to update /etc/hosts file
update_hosts() {
    section "Updating /etc/hosts File"
    
    HOSTS_ENTRIES=(
        "traefik.raspiska.local"
        "redis.raspiska.local"
        "valkey.raspiska.local"
        "kong.raspiska.local"
        "kong-admin.raspiska.local"
        "keycloak.raspiska.local"
        "n8n.raspiska.local"
        "prometheus.raspiska.local"
        "grafana.raspiska.local"
        "alertmanager.raspiska.local"
        "status.raspiska.local"
        "pgadmin.raspiska.local"
        "postgres.raspiska.local"
    )
    
    MISSING_ENTRIES=()
    for entry in "${HOSTS_ENTRIES[@]}"; do
        if ! grep -q "$entry" /etc/hosts; then
            MISSING_ENTRIES+=("$entry")
        fi
    done
    
    if [ ${#MISSING_ENTRIES[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ All required hosts entries are present${NC}"
    else
        echo -e "${YELLOW}The following entries are missing from /etc/hosts:${NC}"
        printf "  %s\n" "${MISSING_ENTRIES[@]}"
        
        echo -e "\n${YELLOW}To add these entries, run:${NC}"
        echo -e "sudo sh -c 'echo \"127.0.0.1 ${MISSING_ENTRIES[*]}\" >> /etc/hosts'"
        
        read -p "Would you like to add these entries now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo sh -c "echo \"127.0.0.1 ${MISSING_ENTRIES[*]}\" >> /etc/hosts"
            check_status "Adding hosts entries" "exit"
        fi
    fi
}

# Function to set up Traefik
setup_traefik() {
    section "Setting Up Traefik"
    
    if [ -d "${DOCKER_IMAGES_DIR}/traefik" ]; then
        cd "${DOCKER_IMAGES_DIR}/traefik"
        ./setup.sh
        check_status "Traefik setup" "exit"
    else
        echo -e "${RED}✗ Traefik directory not found${NC}"
        exit 1
    fi
}

# Function to set up Redis
setup_redis() {
    section "Setting Up Redis"
    
    if [ -d "${DOCKER_IMAGES_DIR}/redis" ]; then
        cd "${DOCKER_IMAGES_DIR}/redis"
        ./setup.sh
        check_status "Redis setup" "exit"
    else
        echo -e "${RED}✗ Redis directory not found${NC}"
        exit 1
    fi
}

# Function to set up Valkey
setup_valkey() {
    section "Setting Up Valkey"
    
    if [ -d "${DOCKER_IMAGES_DIR}/valkey" ]; then
        cd "${DOCKER_IMAGES_DIR}/valkey"
        ./setup.sh
        check_status "Valkey setup" "exit"
    else
        echo -e "${RED}✗ Valkey directory not found${NC}"
        exit 1
    fi
}

# Function to set up Kong
setup_kong() {
    section "Setting Up Kong"
    
    if [ -d "${DOCKER_IMAGES_DIR}/kong" ]; then
        cd "${DOCKER_IMAGES_DIR}/kong"
        ./setup.sh
        check_status "Kong setup" "exit"
    else
        echo -e "${RED}✗ Kong directory not found${NC}"
        exit 1
    fi
}

# Function to set up Keycloak
setup_keycloak() {
    section "Setting Up Keycloak"
    
    if [ -d "${DOCKER_IMAGES_DIR}/keycloak" ]; then
        cd "${DOCKER_IMAGES_DIR}/keycloak"
        ./setup.sh
        check_status "Keycloak setup" "exit"
    else
        echo -e "${RED}✗ Keycloak directory not found${NC}"
        exit 1
    fi
}

# Function to set up n8n
setup_n8n() {
    section "Setting Up n8n"
    
    if [ -d "${DOCKER_IMAGES_DIR}/n8n" ]; then
        cd "${DOCKER_IMAGES_DIR}/n8n"
        ./setup.sh
        check_status "n8n setup" "exit"
    else
        echo -e "${RED}✗ n8n directory not found${NC}"
        exit 1
    fi
}

# Function to set up Monitoring Stack
setup_monitoring() {
    section "Setting Up Monitoring Stack"
    
    if [ -d "${DOCKER_IMAGES_DIR}/monitoring" ]; then
        cd "${DOCKER_IMAGES_DIR}/monitoring"
        ./setup.sh
        check_status "Monitoring setup" "exit"
    else
        echo -e "${RED}✗ Monitoring directory not found${NC}"
        exit 1
    fi
}

# Function to set up Uptime Kuma
setup_uptime_kuma() {
    section "Setting Up Uptime Kuma"
    
    if [ -d "${DOCKER_IMAGES_DIR}/uptime-kuma" ]; then
        cd "${DOCKER_IMAGES_DIR}/uptime-kuma"
        ./setup.sh
        check_status "Uptime Kuma setup" "exit"
    else
        echo -e "${RED}✗ Uptime Kuma directory not found${NC}"
        exit 1
    fi
}

# Function to set up PostgreSQL
setup_postgresql() {
    section "Setting Up PostgreSQL"
    
    if [ -d "${DOCKER_IMAGES_DIR}/postgresql" ]; then
        cd "${DOCKER_IMAGES_DIR}/postgresql"
        ./setup.sh
        check_status "PostgreSQL setup" "exit"
    else
        echo -e "${RED}✗ PostgreSQL directory not found${NC}"
        exit 1
    fi
}

# Function to verify all services are running
verify_services() {
    section "Verifying Services"
    
    subsection "Checking Docker Containers"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep raspiska
    
    subsection "Checking Service URLs"
    SERVICES=(
        "Traefik:http://traefik.raspiska.local"
        "Kong:http://kong.raspiska.local"
        "Kong Admin:http://kong-admin.raspiska.local"
        "Keycloak:http://keycloak.raspiska.local"
        "n8n:http://n8n.raspiska.local"
        "Prometheus:http://prometheus.raspiska.local"
        "Grafana:http://grafana.raspiska.local"
        "Alertmanager:http://alertmanager.raspiska.local"
        "Uptime Kuma:http://status.raspiska.local"
        "pgAdmin:http://pgadmin.raspiska.local"
    )
    
    for service in "${SERVICES[@]}"; do
        name="${service%%:*}"
        url="${service#*:}"
        
        echo -e "${YELLOW}Checking $name at $url${NC}"
        if curl -s --head "$url" > /dev/null; then
            echo -e "${GREEN}✓ $name is accessible${NC}"
        else
            echo -e "${RED}✗ $name is not accessible${NC}"
        fi
    done
}

# Function to display service credentials
display_credentials() {
    section "Service Credentials"
    
    echo -e "${YELLOW}Traefik Dashboard:${NC}"
    echo -e "  URL: http://localhost:8080"
    echo
    
    echo -e "${YELLOW}Keycloak:${NC}"
    echo -e "  URL: http://keycloak.raspiska.local"
    echo -e "  Username: $(grep KEYCLOAK_ADMIN "${DOCKER_IMAGES_DIR}/keycloak/.env" | cut -d '=' -f2)"
    echo -e "  Password: $(grep KEYCLOAK_ADMIN_PASSWORD "${DOCKER_IMAGES_DIR}/keycloak/.env" | cut -d '=' -f2)"
    echo
    
    echo -e "${YELLOW}Kong Admin:${NC}"
    echo -e "  URL: http://kong-admin.raspiska.local"
    echo
    
    echo -e "${YELLOW}n8n:${NC}"
    echo -e "  URL: http://n8n.raspiska.local"
    echo -e "  Username: $(grep N8N_BASIC_AUTH_USER "${DOCKER_IMAGES_DIR}/n8n/.env" | cut -d '=' -f2)"
    echo -e "  Password: $(grep N8N_BASIC_AUTH_PASSWORD "${DOCKER_IMAGES_DIR}/n8n/.env" | cut -d '=' -f2)"
    echo
    
    echo -e "${YELLOW}Grafana:${NC}"
    echo -e "  URL: http://grafana.raspiska.local"
    echo -e "  Username: admin"
    echo -e "  Password: $(grep GF_SECURITY_ADMIN_PASSWORD "${DOCKER_IMAGES_DIR}/monitoring/.env" | cut -d '=' -f2)"
    echo
    
    echo -e "${YELLOW}Uptime Kuma:${NC}"
    echo -e "  URL: http://status.raspiska.local"
    echo -e "  Note: Create an admin account on first login"
    echo
    
    echo -e "${YELLOW}pgAdmin:${NC}"
    echo -e "  URL: http://pgadmin.raspiska.local"
    echo -e "  Email: $(grep PGADMIN_EMAIL "${DOCKER_IMAGES_DIR}/postgresql/.env" | cut -d '=' -f2)"
    echo -e "  Password: $(grep PGADMIN_PASSWORD "${DOCKER_IMAGES_DIR}/postgresql/.env" | cut -d '=' -f2)"
    echo
    
    echo -e "${YELLOW}PostgreSQL:${NC}"
    echo -e "  Host: localhost"
    echo -e "  Port: 5432"
    echo -e "  Username: postgres"
    echo -e "  Password: $(grep POSTGRES_PASSWORD "${DOCKER_IMAGES_DIR}/postgresql/.env" | cut -d '=' -f2)"
    echo
    
    echo -e "${YELLOW}Redis:${NC}"
    echo -e "  Host: localhost"
    echo -e "  Port: 6379"
    echo -e "  Password: $(grep REDIS_PASSWORD "${DOCKER_IMAGES_DIR}/redis/.env" | cut -d '=' -f2)"
    echo
    
    echo -e "${YELLOW}Valkey:${NC}"
    echo -e "  Host: localhost"
    echo -e "  Port: 6380"
    echo -e "  Password: $(grep VALKEY_PASSWORD "${DOCKER_IMAGES_DIR}/valkey/.env" | cut -d '=' -f2)"
}

# Main function
main() {
    section "Raspiska Tech Development Environment Setup"
    
    # Check prerequisites
    check_docker
    
    # Update hosts file
    update_hosts
    
    # Ask which components to set up
    echo -e "\n${YELLOW}Which components would you like to set up?${NC}"
    
    components=(
        "Traefik (Reverse Proxy)"
        "Redis (In-memory Data Store)"
        "Valkey (Redis Alternative)"
        "Kong (API Gateway)"
        "Keycloak (Identity and Access Management)"
        "n8n (Workflow Automation)"
        "Monitoring Stack (Prometheus, Grafana, Alertmanager)"
        "Uptime Kuma (Status Page)"
        "PostgreSQL (Database)"
        "All Components"
    )
    
    select_options() {
        for i in "${!components[@]}"; do
            echo "$((i+1)). ${components[$i]}"
        done
        
        read -p "Enter your choice (1-${#components[@]}): " choice
        
        case $choice in
            1) setup_traefik ;;
            2) setup_redis ;;
            3) setup_valkey ;;
            4) setup_kong ;;
            5) setup_keycloak ;;
            6) setup_n8n ;;
            7) setup_monitoring ;;
            8) setup_uptime_kuma ;;
            9) setup_postgresql ;;
            10)
                setup_traefik
                setup_redis
                setup_valkey
                setup_kong
                setup_keycloak
                setup_n8n
                setup_monitoring
                setup_uptime_kuma
                setup_postgresql
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                select_options
                ;;
        esac
    }
    
    select_options
    
    # Verify services
    verify_services
    
    # Display credentials
    display_credentials
    
    section "Setup Complete"
    echo -e "${GREEN}The Raspiska Tech development environment has been set up successfully!${NC}"
    echo -e "${YELLOW}You can access all services using the URLs and credentials provided above.${NC}"
}

# Run the main function
main
