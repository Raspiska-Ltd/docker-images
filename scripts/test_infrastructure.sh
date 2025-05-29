#!/bin/bash

# Raspiska Tech Infrastructure Test Script
# This script tests all components of the Raspiska Tech infrastructure

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section header
print_header() {
    echo -e "\n${BLUE}=== Testing $1 ===${NC}"
}

# Function to print success message
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error message
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print warning message
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to test HTTP endpoint
test_http_endpoint() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    local allow_redirects=${4:-false}
    
    echo -n "Testing $name ($url)... "
    
    # Try up to 3 times with a 2-second delay between attempts
    for i in {1..3}; do
        if [ "$allow_redirects" = "true" ]; then
            # Allow redirects and check final status
            status_code=$(curl -L -s -o /dev/null -w "%{http_code}" "$url")
        else
            # Don't follow redirects
            status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
        fi
        
        # Consider redirects (301, 302, 303, 307, 308) as success if allow_redirects is false
        if [ "$status_code" = "$expected_status" ] || \
           ([ "$allow_redirects" = "false" ] && \
            ([ "$status_code" = "301" ] || [ "$status_code" = "302" ] || \
             [ "$status_code" = "303" ] || [ "$status_code" = "307" ] || \
             [ "$status_code" = "308" ])); then
            print_success "Status code: $status_code"
            return 0
        fi
        sleep 2
    done
    
    print_error "Failed! Expected status $expected_status, got $status_code"
    return 1
}

# Function to test Docker container status
test_container_status() {
    local container_name=$1
    
    echo -n "Testing container $container_name... "
    
    if [ "$(docker ps -q -f name=$container_name)" ]; then
        status=$(docker inspect -f '{{.State.Status}}' $container_name)
        if [ "$status" = "running" ]; then
            print_success "Container is running"
            return 0
        else
            print_error "Container is $status"
            return 1
        fi
    else
        print_error "Container does not exist"
        return 1
    fi
}

# Function to test Redis/Valkey connectivity
test_redis_connection() {
    local container_name=$1
    local password_var=$2
    local cli_command=${3:-redis-cli}
    
    echo -n "Testing $container_name connectivity... "
    
    if [ "$(docker ps -q -f name=$container_name)" ]; then
        # Use default test password if environment file not found
        local password="secure_redis_password"
        
        # Try to get password from environment files
        if [ -f "../redis/.env" ] && [ "$password_var" = "REDIS_PASSWORD" ]; then
            password=$(grep REDIS_PASSWORD ../redis/.env | cut -d '=' -f2 | tr -d '"' || echo "secure_redis_password")
        elif [ -f "../valkey/.env" ] && [ "$password_var" = "VALKEY_PASSWORD" ]; then
            password=$(grep VALKEY_PASSWORD ../valkey/.env | cut -d '=' -f2 | tr -d '"' || echo "secure_valkey_password")
        fi
        
        # Test connection
        result=$(docker exec -i $container_name $cli_command -a "$password" PING 2>/dev/null || echo "FAILED")
        
        if [ "$result" = "PONG" ]; then
            print_success "Connection successful"
            return 0
        else
            print_error "Connection failed"
            return 1
        fi
    else
        print_error "Container does not exist"
        return 1
    fi
}

# Function to test PostgreSQL connectivity
test_postgres_connection() {
    local container_name=$1
    local user=${2:-postgres}
    
    echo -n "Testing $container_name connectivity ($user)... "
    
    if [ "$(docker ps -q -f name=$container_name)" ]; then
        if docker exec -i $container_name pg_isready -U $user > /dev/null 2>&1; then
            print_success "Connection successful"
            return 0
        else
            print_error "Connection failed"
            return 1
        fi
    else
        print_error "Container does not exist"
        return 1
    fi
}

# Main testing sequence
echo "Starting Raspiska Tech infrastructure tests..."
echo "Current time: $(date)"

# Test Traefik
print_header "Traefik"
test_container_status "raspiska_traefik"
test_http_endpoint "Traefik Dashboard" "http://localhost:8280" "200" "true"

# Test Redis
if [ -d "../redis" ]; then
    print_header "Redis"
    test_container_status "raspiska_redis"
    test_redis_connection "raspiska_redis" "REDIS_PASSWORD"
fi

# Test Valkey
if [ -d "../valkey" ]; then
    print_header "Valkey"
    test_container_status "raspiska_valkey"
    test_redis_connection "raspiska_valkey" "VALKEY_PASSWORD" "valkey-cli"
fi

# Test Kong
if [ -d "../kong" ]; then
    print_header "Kong API Gateway"
    test_container_status "raspiska_kong"
    test_container_status "raspiska_kong_db" # Correct container name
    test_http_endpoint "Kong Admin API" "http://localhost:8001" "200" "true"
    test_http_endpoint "Kong Proxy" "http://localhost:8000" "404" "false" # 404 is expected for empty gateway
fi

# Test PostgreSQL
if [ -d "../postgresql" ]; then
    print_header "PostgreSQL"
    test_container_status "raspiska_postgres"
    test_postgres_connection "raspiska_postgres" "postgres"
    test_container_status "raspiska_pgbouncer"
    test_http_endpoint "pgAdmin" "http://localhost:5050" "200" "true"
fi

# Test Monitoring Stack
if [ -d "../monitoring" ]; then
    print_header "Monitoring Stack"
    test_container_status "raspiska_prometheus"
    test_container_status "raspiska_grafana"
    test_container_status "raspiska_alertmanager"
    test_http_endpoint "Prometheus" "http://localhost:9090" "200" "true"
    test_http_endpoint "Grafana" "http://localhost:3000" "200" "true"
    test_http_endpoint "Alertmanager" "http://localhost:9093" "200" "true"
fi

# Test Uptime Kuma
if [ -d "../uptime-kuma" ]; then
    print_header "Uptime Kuma"
    test_container_status "raspiska_uptime_kuma"
    test_http_endpoint "Uptime Kuma" "http://localhost:3001" "200" "true"
fi

# Test Jenkins
if [ -d "../jenkins" ]; then
    print_header "Jenkins"
    test_container_status "raspiska_jenkins"
    test_container_status "raspiska_jenkins_agent"
    test_http_endpoint "Jenkins" "http://localhost:8181/jenkins" "200" "true"
fi

# Test n8n
if [ -d "../n8n" ]; then
    print_header "n8n"
    test_container_status "raspiska_n8n"
    test_http_endpoint "n8n" "http://localhost:5678" "200" "true"
fi

# Test Keycloak
if [ -d "../keycloak" ]; then
    print_header "Keycloak"
    test_container_status "raspiska_keycloak"
    test_http_endpoint "Keycloak" "http://localhost:8080/auth" "200" "true"
fi

# Test MinIO
if [ -d "../minio" ]; then
    print_header "MinIO Object Storage"
    test_container_status "raspiska_minio"
    test_http_endpoint "MinIO API" "http://localhost:9000" "200" "true"
    test_http_endpoint "MinIO Console" "http://localhost:9001" "200" "true"
    
    # Test bucket access if mc is available
    if command -v mc &> /dev/null; then
        echo -n "Testing MinIO bucket access... "
        # Configure mc client
        mc config host add myminio http://localhost:9000 admin secure_minio_password > /dev/null 2>&1
        # Test bucket listing
        if mc ls myminio > /dev/null 2>&1; then
            print_success "Bucket access successful"
        else
            print_error "Bucket access failed"
        fi
    fi
fi

# Test OpenTelemetry
if [ -d "../opentelemetry" ]; then
    print_header "OpenTelemetry Distributed Tracing"
    test_container_status "raspiska_otel_collector"
    test_container_status "raspiska_jaeger"
    test_container_status "raspiska_zipkin"
    test_container_status "raspiska_tempo"
    test_http_endpoint "Jaeger UI" "http://localhost:16686" "200" "true"
    test_http_endpoint "Zipkin UI" "http://localhost:9412" "200" "true"
    test_http_endpoint "Tempo" "http://localhost:3200" "200" "true"
    test_http_endpoint "OpenTelemetry Collector" "http://localhost:8888" "200" "true"
    
    # Test OTLP endpoints
    echo -n "Testing OTLP gRPC endpoint... "
    if nc -z localhost 4317; then
        print_success "OTLP gRPC endpoint is accessible"
    else
        print_error "OTLP gRPC endpoint is not accessible"
    fi
    
    echo -n "Testing OTLP HTTP endpoint... "
    if nc -z localhost 4318; then
        print_success "OTLP HTTP endpoint is accessible"
    else
        print_error "OTLP HTTP endpoint is not accessible"
    fi
fi

echo -e "\n${GREEN}=== Infrastructure tests completed ===${NC}"
