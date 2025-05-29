#!/bin/bash

# OpenTelemetry Setup Script for Raspiska Tech
# This script sets up OpenTelemetry distributed tracing for the infrastructure

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

# Check if Prometheus network exists
if ! docker network ls | grep -q raspiska_prometheus_network; then
    print_warning "Prometheus network not found. Creating it..."
    docker network create raspiska_prometheus_network
fi
print_success "Prometheus network is available"

# Configure hosts file
print_header "Configuring hosts file"
if ! grep -q "jaeger.raspiska.local" /etc/hosts; then
    echo "Adding hosts entries (requires sudo)..."
    echo "127.0.0.1 jaeger.raspiska.local zipkin.raspiska.local tempo.raspiska.local otel-collector.raspiska.local" | sudo tee -a /etc/hosts > /dev/null
    print_success "Hosts entries added"
else
    print_success "Hosts entries already exist"
fi

# Configure Traefik for OpenTelemetry
print_header "Configuring Traefik for OpenTelemetry"
TRAEFIK_DIR="../traefik/config/dynamic"
if [ -d "$TRAEFIK_DIR" ]; then
    cat > "$TRAEFIK_DIR/opentelemetry.yml" << EOF
http:
  routers:
    jaeger:
      rule: "Host(\`jaeger.raspiska.local\`)"
      service: "jaeger"
      entryPoints:
        - "web"
      middlewares:
        - "secure-headers"

    zipkin:
      rule: "Host(\`zipkin.raspiska.local\`)"
      service: "zipkin"
      entryPoints:
        - "web"
      middlewares:
        - "secure-headers"

    tempo:
      rule: "Host(\`tempo.raspiska.local\`)"
      service: "tempo"
      entryPoints:
        - "web"
      middlewares:
        - "secure-headers"

    otel-collector:
      rule: "Host(\`otel-collector.raspiska.local\`)"
      service: "otel-collector"
      entryPoints:
        - "web"
      middlewares:
        - "secure-headers"

  services:
    jaeger:
      loadBalancer:
        servers:
          - url: "http://raspiska_jaeger:16686"

    zipkin:
      loadBalancer:
        servers:
          - url: "http://raspiska_zipkin:9411"

    tempo:
      loadBalancer:
        servers:
          - url: "http://raspiska_tempo:3200"

    otel-collector:
      loadBalancer:
        servers:
          - url: "http://raspiska_otel_collector:8888"
EOF
    print_success "Traefik configuration created"
else
    print_warning "Traefik config directory not found. Skipping Traefik configuration."
fi

# Configure Kong for OpenTelemetry
print_header "Configuring Kong for OpenTelemetry"
if [ -d "../kong" ]; then
    # Check if Kong is running
    if docker ps | grep -q raspiska_kong; then
        echo "Setting up Kong routes for OpenTelemetry..."
        
        # Add Jaeger service and route
        curl -s -X POST http://localhost:8001/services \
            -d name=jaeger \
            -d url=http://raspiska_jaeger:16686 > /dev/null
            
        curl -s -X POST http://localhost:8001/services/jaeger/routes \
            -d name=jaeger \
            -d "hosts[]=jaeger.raspiska.local" \
            -d paths=/jaeger > /dev/null
            
        # Add Zipkin service and route
        curl -s -X POST http://localhost:8001/services \
            -d name=zipkin \
            -d url=http://raspiska_zipkin:9411 > /dev/null
            
        curl -s -X POST http://localhost:8001/services/zipkin/routes \
            -d name=zipkin \
            -d "hosts[]=zipkin.raspiska.local" \
            -d paths=/zipkin > /dev/null
            
        # Add Tempo service and route
        curl -s -X POST http://localhost:8001/services \
            -d name=tempo \
            -d url=http://raspiska_tempo:3200 > /dev/null
            
        curl -s -X POST http://localhost:8001/services/tempo/routes \
            -d name=tempo \
            -d "hosts[]=tempo.raspiska.local" \
            -d paths=/tempo > /dev/null
            
        # Add OpenTelemetry Collector service and route
        curl -s -X POST http://localhost:8001/services \
            -d name=otel-collector \
            -d url=http://raspiska_otel_collector:8888 > /dev/null
            
        curl -s -X POST http://localhost:8001/services/otel-collector/routes \
            -d name=otel-collector \
            -d "hosts[]=otel-collector.raspiska.local" \
            -d paths=/otel-collector > /dev/null
            
        print_success "Kong routes for OpenTelemetry created"
    else
        print_warning "Kong is not running. Skipping Kong configuration."
    fi
else
    print_warning "Kong directory not found. Skipping Kong configuration."
fi

# Configure Prometheus for OpenTelemetry
print_header "Configuring Prometheus for OpenTelemetry"
PROMETHEUS_DIR="../monitoring/config"
if [ -d "$PROMETHEUS_DIR" ]; then
    # Add OpenTelemetry to Prometheus config if not already there
    if ! grep -q "otel-collector" "$PROMETHEUS_DIR/prometheus.yml"; then
        echo "Adding OpenTelemetry to Prometheus configuration..."
        cat >> "$PROMETHEUS_DIR/prometheus.yml" << EOF

  - job_name: 'otel-collector'
    scrape_interval: 10s
    static_configs:
      - targets: ['raspiska_otel_collector:8889']
EOF
        print_success "Prometheus configuration updated"
    else
        print_success "OpenTelemetry already configured in Prometheus"
    fi
else
    print_warning "Prometheus config directory not found. Skipping Prometheus configuration."
fi

# Start OpenTelemetry
print_header "Starting OpenTelemetry"
docker-compose up -d
if [ $? -eq 0 ]; then
    print_success "OpenTelemetry started successfully"
else
    print_error "Failed to start OpenTelemetry"
fi

# Wait for services to be ready
print_header "Waiting for services to be ready"
echo "This may take a few seconds..."
sleep 10
print_success "Services should be ready now"

# Display access information
print_header "OpenTelemetry Access Information"
echo "Jaeger UI is available at:"
echo "  - Direct: http://localhost:16686"
echo "  - Traefik: http://jaeger.raspiska.local"
echo "  - Kong: http://kong.raspiska.local/jaeger"
echo
echo "Zipkin UI is available at:"
echo "  - Direct: http://localhost:9412"
echo "  - Traefik: http://zipkin.raspiska.local"
echo "  - Kong: http://kong.raspiska.local/zipkin"
echo
echo "Tempo is available at:"
echo "  - Direct: http://localhost:3200"
echo "  - Traefik: http://tempo.raspiska.local"
echo "  - Kong: http://kong.raspiska.local/tempo"
echo
echo "OpenTelemetry Collector is available at:"
echo "  - Direct: http://localhost:8888"
echo "  - Traefik: http://otel-collector.raspiska.local"
echo "  - Kong: http://kong.raspiska.local/otel-collector"
echo
echo "OTLP Endpoints:"
echo "  - gRPC: localhost:4317"
echo "  - HTTP: localhost:4318"

print_header "OpenTelemetry Setup Complete"
echo "OpenTelemetry distributed tracing is now ready for use with your Raspiska Tech infrastructure."
echo "To instrument your applications, use the OpenTelemetry SDKs for your programming languages."
