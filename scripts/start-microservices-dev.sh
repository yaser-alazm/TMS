#!/bin/bash

# Microservices Development Environment Startup Script
# This script starts all services as separate microservices with their own environment configurations

set -e

echo "🚀 Starting TMS Microservices Development Environment"
echo "====================================================="

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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    print_error "Node.js version 18+ is required. Current version: $(node -v)"
    exit 1
fi

print_success "Node.js $(node -v) detected"

# Step 1: Clean up any existing processes
print_status "Step 1: Cleaning up existing processes..."
lsof -ti:4000,4001,4002,4003,4004,3000 | xargs kill -9 2>/dev/null || true
pkill -f "nest start" || true
pkill -f "next dev" || true
pkill -f "concurrently" || true
sleep 2

# Step 2: Install dependencies
print_status "Step 2: Installing dependencies..."
npm install

# Install dependencies for each service
print_status "Installing dependencies for all services..."
cd apps/gateway && npm install && cd ../..
cd apps/user-service && npm install && cd ../..
cd apps/vehicle-service && npm install && cd ../..
cd apps/gps-service && npm install && cd ../..
cd apps/traffic-service && npm install && cd ../..
cd apps/client && npm install && cd ../..

# Step 3: Start infrastructure services
print_status "Step 3: Starting infrastructure services (PostgreSQL, Redis, Kafka)..."

# Check if Kafka cluster ID mismatch exists and fix it
print_status "Checking for Kafka cluster ID issues..."
if docker-compose -f docker-compose.dev.yml ps | grep -q "kafka-dev.*Restarting"; then
    print_warning "Kafka cluster ID mismatch detected. Resetting Kafka and Zookeeper volumes..."
    docker-compose -f docker-compose.dev.yml down -v
    print_status "Volumes reset. Restarting infrastructure services..."
fi

docker-compose -f docker-compose.dev.yml up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 15

# Check if databases are ready
print_status "Checking database connectivity..."
for i in {1..30}; do
    if docker exec tms-postgres-user-dev pg_isready -U postgres -d tms_user > /dev/null 2>&1; then
        print_success "User database is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "User database failed to start after 30 attempts"
        exit 1
    fi
    print_status "Waiting for user database... (attempt $i/30)"
    sleep 2
done

for i in {1..30}; do
    if docker exec tms-postgres-vehicle-dev pg_isready -U postgres -d tms_vehicle > /dev/null 2>&1; then
        print_success "Vehicle database is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "Vehicle database failed to start after 30 attempts"
        exit 1
    fi
    print_status "Waiting for vehicle database... (attempt $i/30)"
    sleep 2
done

for i in {1..30}; do
    if docker exec tms-postgres-gps-dev pg_isready -U postgres -d tms_gps > /dev/null 2>&1; then
        print_success "GPS database is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "GPS database failed to start after 30 attempts"
        exit 1
    fi
    print_status "Waiting for GPS database... (attempt $i/30)"
    sleep 2
done

# Check if Kafka is ready (optional - services can start without it)
print_status "Checking Kafka connectivity (optional)..."
for i in {1..15}; do
    # Check if Kafka container is running and not restarting
    if docker-compose -f docker-compose.dev.yml ps | grep -q "kafka-dev.*Restarting"; then
        print_warning "Kafka is restarting due to cluster ID mismatch. Attempting to fix..."
        docker-compose -f docker-compose.dev.yml down -v
        docker-compose -f docker-compose.dev.yml up -d
        sleep 10
        continue
    fi
    
    # Test Kafka connectivity
    if docker exec tms-kafka-dev kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
        print_success "Kafka is ready"
        break
    fi
    
    if [ $i -eq 15 ]; then
        print_warning "Kafka is not ready after 15 attempts, but services will start anyway"
        print_status "Kafka may take a few minutes to fully initialize"
    fi
    print_status "Waiting for Kafka... (attempt $i/15)"
    sleep 3
done

# Step 4: Run database migrations
print_status "Step 4: Running database migrations..."

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

# User Service migrations and seeding
print_status "Running User Service migrations and seeding..."
cd apps/user-service
# Copy environment file to service directory for Prisma
cp ../../env/user-service.env .env
npx prisma migrate deploy
npx prisma generate
npm run db:seed
cd ../..

# Vehicle Service migrations and seeding
print_status "Running Vehicle Service migrations and seeding..."
cd apps/vehicle-service
# Copy environment file to service directory for Prisma
cp ../../env/vehicle-service.env .env
npx prisma migrate deploy
npx prisma generate
npm run db:seed
cd ../..

print_success "Database migrations completed!"

# Step 5: Start microservices with their own environment files
print_status "Step 5: Starting microservices..."

# Copy the microservices startup script
cp start-microservices.sh ./
chmod +x start-microservices.sh

print_success "🎉 TMS Microservices Development Environment Ready!"
echo ""
echo "📋 Microservices Environment Summary:"
echo "====================================="
echo "✅ Infrastructure services running in Docker"
echo "✅ Database migrations completed"
echo "✅ Individual environment files for each service"
echo "✅ Hot reloading configured for all services"
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
echo "🛠️  Development Tools:"
echo "====================="
echo "Adminer (DB):     http://localhost:8080"
echo "Redis Commander:  http://localhost:8081"
echo "Kafka UI:         http://localhost:8082"
echo ""
echo "🔐 JWT Configuration:"
echo "===================="
echo "JWKS Endpoint:    http://localhost:4001/.well-known/jwks.json"
echo "Key ID:           05a109194c13c0fc"
echo "Issuer:           yatms-user-service-dev"
echo ""
echo "🚀 Start Microservices:"
echo "======================"
echo "Run: ./start-microservices.sh"
echo ""
echo "🛑 Stop Development Environment:"
echo "================================="
echo "Run: ./scripts/stop-local-dev.sh"
echo ""
echo "📊 Check Service Status:"
echo "======================="
echo "Run: docker-compose -f docker-compose.dev.yml ps"
