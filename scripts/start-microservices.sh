#!/bin/bash

# Start Microservices with Proper Environment Loading
# This script starts all services with their individual environment configurations

set -e

echo "🔥 Starting TMS Microservices with Individual Environment Configurations..."

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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Kill any existing processes on development ports
print_status "Cleaning up any existing processes on development ports..."
lsof -ti:4000,4001,4002,4003,4004,3000 | xargs kill -9 2>/dev/null || true
pkill -f "nest start" || true
pkill -f "next dev" || true
pkill -f "concurrently" || true

# Wait for processes to fully terminate
sleep 2

# Start infrastructure services first
print_status "Starting infrastructure services..."
docker-compose -f docker-compose.dev.yml up -d

# Wait for services to be ready
print_status "Waiting for infrastructure services to be ready..."
sleep 10

# Fix Kafka topics to prevent leadership issues
print_status "Fixing Kafka topics to prevent leadership issues..."
if [ -f "./scripts/fix-kafka-topics.sh" ]; then
    ./scripts/fix-kafka-topics.sh
else
    print_warning "Kafka topics fix script not found, skipping..."
fi

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

# Start all services concurrently with their individual environment files
print_status "Starting microservices with individual environment configurations..."

npx concurrently \
  --names "GATEWAY,USER,VEHICLE,GPS,TRAFFIC,CLIENT" \
  --prefix-colors "cyan,magenta,yellow,green,blue,red" \
  --kill-others-on-fail \
  "cd apps/gateway && cp ../../env/gateway.env .env && npm run start:dev" \
  "cd apps/user-service && cp ../../env/user-service.env .env && npm run start:dev" \
  "cd apps/vehicle-service && cp ../../env/vehicle-service.env .env && npm run start:dev" \
  "cd apps/gps-service && cp ../../env/gps-service.env .env && npm run start:dev" \
  "cd apps/traffic-service && cp ../../env/traffic-service.env .env && npm run start:dev" \
  "cd apps/client && npm run dev"
