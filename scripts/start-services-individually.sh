#!/bin/bash

# Simple Microservices Startup Script
# This script starts each service individually for better debugging

set -e

echo "🚀 Starting TMS Microservices Individually"
echo "=========================================="

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to load environment variables from file
load_env() {
    local env_file=$1
    if [ -f "$env_file" ]; then
        # Export variables, skipping comments and empty lines
        while IFS= read -r line; do
            # Skip comments and empty lines
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
                # Export the variable
                export "$line"
            fi
        done < "$env_file"
        return 0
    else
        print_error "Environment file $env_file not found"
        return 1
    fi
}

# Kill any existing processes
print_status "Cleaning up existing processes..."
lsof -ti:4000,4001,4002,4003,4004,3000 | xargs kill -9 2>/dev/null || true
pkill -f "nest start" || true
pkill -f "next dev" || true
sleep 2

# Start services in background
print_status "Starting User Service..."
cd apps/user-service
load_env ../../env/user-service.env
npm run start:dev &
USER_PID=$!
cd ../..

print_status "Starting Vehicle Service..."
cd apps/vehicle-service
load_env ../../env/vehicle-service.env
npm run start:dev &
VEHICLE_PID=$!
cd ../..

print_status "Starting GPS Service..."
cd apps/gps-service
load_env ../../env/gps-service.env
npm run start:dev &
GPS_PID=$!
cd ../..

print_status "Starting Traffic Service..."
cd apps/traffic-service
load_env ../../env/traffic-service.env
npm run start:dev &
TRAFFIC_PID=$!
cd ../..

print_status "Starting Gateway Service..."
cd apps/gateway
load_env ../../env/gateway.env
npm run start:dev &
GATEWAY_PID=$!
cd ../..

print_status "Starting Client App..."
cd apps/client
npm run dev &
CLIENT_PID=$!
cd ../..

print_success "All services started!"
echo ""
echo "🔗 Service URLs:"
echo "==============="
echo "Gateway API:      http://localhost:4000"
echo "User Service:     http://localhost:4001"
echo "Vehicle Service:  http://localhost:4002"
echo "GPS Service:      http://localhost:4003"
echo "Traffic Service:  http://localhost:4004"
echo "Client App:       http://localhost:3000"
echo ""
echo "🔐 JWKS Endpoint:"
echo "================"
echo "http://localhost:4001/.well-known/jwks.json"
echo ""
echo "🛑 To stop all services:"
echo "======================"
echo "kill $USER_PID $VEHICLE_PID $GPS_PID $TRAFFIC_PID $GATEWAY_PID $CLIENT_PID"
echo ""
echo "⏳ Waiting for services to start..."
sleep 15

# Test services
print_status "Testing services..."
echo ""
echo "🔍 JWKS Endpoint Test:"
curl -s http://localhost:4001/.well-known/jwks.json | jq . || echo "JWKS endpoint not ready"
echo ""
echo "🔍 Health Check Tests:"
curl -s http://localhost:4001/health || echo "User Service not ready"
curl -s http://localhost:4002/health || echo "Vehicle Service not ready"
curl -s http://localhost:4000/health || echo "Gateway Service not ready"
echo ""
echo "✅ Services are running! Check the URLs above."
