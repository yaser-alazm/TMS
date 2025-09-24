#!/bin/bash

# Development Environment Status Checker
# This script checks the status of all development services

set -e

echo "📊 Development Environment Status"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a service is running
check_service() {
    local service_name=$1
    local port=$2
    local url=$3
    
    if curl -s -f "http://localhost:$port/health" > /dev/null 2>&1; then
        echo -e "✅ $service_name: ${GREEN}Running${NC} (http://localhost:$port)"
    else
        echo -e "❌ $service_name: ${RED}Not Running${NC} (http://localhost:$port)"
    fi
}

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -i :$port > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

echo ""
print_status "Checking Infrastructure Services..."
echo "========================================"

# Check Docker services
if docker-compose -f docker-compose.dev.yml ps | grep -q "Up"; then
    print_success "Docker infrastructure services are running"
    echo ""
    docker-compose -f docker-compose.dev.yml ps
else
    print_warning "Docker infrastructure services are not running"
fi

echo ""
print_status "Checking Application Services..."
echo "====================================="

# Check each service
check_service "Gateway API" "4000" "http://localhost:4000"
check_service "User Service" "4001" "http://localhost:4001"
check_service "Vehicle Service" "4002" "http://localhost:4002"
check_service "GPS Service" "4003" "http://localhost:4003"
check_service "Traffic Service" "4004" "http://localhost:4004"

# Check client app
if check_port 3000; then
    echo -e "✅ Client App: ${GREEN}Running${NC} (http://localhost:3000)"
else
    echo -e "❌ Client App: ${RED}Not Running${NC} (http://localhost:3000)"
fi

echo ""
print_status "Checking Development Tools..."
echo "================================="

# Check development tools
if check_port 8080; then
    echo -e "✅ Adminer: ${GREEN}Running${NC} (http://localhost:8080)"
else
    echo -e "❌ Adminer: ${RED}Not Running${NC} (http://localhost:8080)"
fi

if check_port 8081; then
    echo -e "✅ Redis Commander: ${GREEN}Running${NC} (http://localhost:8081)"
else
    echo -e "❌ Redis Commander: ${RED}Not Running${NC} (http://localhost:8081)"
fi

if check_port 8082; then
    echo -e "✅ Kafka UI: ${GREEN}Running${NC} (http://localhost:8082)"
else
    echo -e "❌ Kafka UI: ${RED}Not Running${NC} (http://localhost:8082)"
fi

echo ""
print_status "Quick Commands:"
echo "================"
echo "Start dev environment: ./scripts/start-local-dev.sh"
echo "Stop dev environment:  ./scripts/stop-local-dev.sh"
echo "View logs:             docker-compose -f docker-compose.dev.yml logs -f"
echo "Restart services:      docker-compose -f docker-compose.dev.yml restart"
