#!/bin/bash

# MinIO Setup Script for Raspiska Tech
# This script sets up MinIO object storage service

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section header
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to print success message
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error message
print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Function to print warning message
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if Docker is running
print_header "Checking prerequisites"
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
fi
print_success "Docker is running"

# Check if Traefik network exists
if ! docker network ls | grep -q raspiska_traefik_network; then
    print_warning "Traefik network not found. Creating it..."
    docker network create raspiska_traefik_network
fi
print_success "Traefik network is available"

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found. Please create it before running this script."
fi
print_success "Environment file found"

# Create necessary directories
print_header "Setting up directories"
mkdir -p data config
print_success "Directories created"

# Configure hosts file
print_header "Configuring hosts file"
if ! grep -q "minio.raspiska.local" /etc/hosts; then
    echo "Adding hosts entries (requires sudo)..."
    echo "127.0.0.1 minio.raspiska.local minio-console.raspiska.local" | sudo tee -a /etc/hosts > /dev/null
    print_success "Hosts entries added"
else
    print_success "Hosts entries already exist"
fi

# Configure Traefik for MinIO
print_header "Configuring Traefik for MinIO"
TRAEFIK_DIR="../traefik/config/dynamic"
if [ -d "$TRAEFIK_DIR" ]; then
    cat > "$TRAEFIK_DIR/minio.yml" << EOF
http:
  routers:
    minio-api:
      rule: "Host(\`minio.raspiska.local\`)"
      service: "minio-api"
      entryPoints:
        - "web"
      middlewares:
        - "secure-headers"

    minio-console:
      rule: "Host(\`minio-console.raspiska.local\`)"
      service: "minio-console"
      entryPoints:
        - "web"
      middlewares:
        - "secure-headers"

  services:
    minio-api:
      loadBalancer:
        servers:
          - url: "http://raspiska_minio:9000"

    minio-console:
      loadBalancer:
        servers:
          - url: "http://raspiska_minio:9001"
EOF
    print_success "Traefik configuration created"
else
    print_warning "Traefik config directory not found. Skipping Traefik configuration."
fi

# Configure Kong for MinIO
print_header "Configuring Kong for MinIO"
if [ -d "../kong" ]; then
    # Check if Kong is running
    if docker ps | grep -q raspiska_kong; then
        echo "Setting up Kong routes for MinIO..."
        
        # Add MinIO API service and route
        curl -s -X POST http://localhost:8001/services \
            -d name=minio-api \
            -d url=http://raspiska_minio:9000 > /dev/null
            
        curl -s -X POST http://localhost:8001/services/minio-api/routes \
            -d name=minio-api \
            -d "hosts[]=minio.raspiska.local" \
            -d paths=/minio > /dev/null
            
        # Add MinIO Console service and route
        curl -s -X POST http://localhost:8001/services \
            -d name=minio-console \
            -d url=http://raspiska_minio:9001 > /dev/null
            
        curl -s -X POST http://localhost:8001/services/minio-console/routes \
            -d name=minio-console \
            -d "hosts[]=minio-console.raspiska.local" \
            -d paths=/minio-console > /dev/null
            
        print_success "Kong routes for MinIO created"
    else
        print_warning "Kong is not running. Skipping Kong configuration."
    fi
else
    print_warning "Kong directory not found. Skipping Kong configuration."
fi

# Start MinIO
print_header "Starting MinIO"
docker-compose up -d
if [ $? -eq 0 ]; then
    print_success "MinIO started successfully"
else
    print_error "Failed to start MinIO"
fi

# Wait for MinIO to be ready
print_header "Waiting for MinIO to be ready"
echo "This may take a few seconds..."
for i in {1..30}; do
    if curl -s -f http://localhost:9000/minio/health/live > /dev/null; then
        print_success "MinIO is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        print_warning "Timed out waiting for MinIO to be ready. It might still be starting up."
    fi
    sleep 1
done

# Display access information
print_header "MinIO Access Information"
echo "MinIO API is available at:"
echo "  - Direct: http://localhost:9000"
echo "  - Traefik: http://minio.raspiska.local"
echo "  - Kong: http://kong.raspiska.local/minio"
echo
echo "MinIO Console is available at:"
echo "  - Direct: http://localhost:9001"
echo "  - Traefik: http://minio-console.raspiska.local"
echo "  - Kong: http://kong.raspiska.local/minio-console"
echo
echo "Login credentials:"
echo "  - Root User: $(grep MINIO_ROOT_USER .env | cut -d= -f2)"
echo "  - Root Password: $(grep MINIO_ROOT_PASSWORD .env | cut -d= -f2)"
echo
echo "Application credentials:"
echo "  - App User: $(grep MINIO_APP_USER .env | cut -d= -f2)"
echo "  - App Password: $(grep MINIO_APP_PASSWORD .env | cut -d= -f2)"
echo
echo "Default buckets:"
echo "  - backups: For database and system backups"
echo "  - logs: For application and system logs"
echo "  - artifacts: For build artifacts and releases"
echo "  - public: For publicly accessible files (download policy enabled)"

print_header "MinIO Setup Complete"
echo "MinIO object storage is now ready for use with your Raspiska Tech infrastructure."
