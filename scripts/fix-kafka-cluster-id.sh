#!/bin/bash

# Kafka Cluster ID Mismatch Fix Script
# This script automatically detects and fixes Kafka cluster ID mismatches

set -e

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

echo "🔧 Kafka Cluster ID Mismatch Fix"
echo "================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Kafka container exists
if ! docker-compose -f docker-compose.dev.yml ps | grep -q "kafka-dev"; then
    print_error "Kafka container not found. Please run 'npm run dev' first."
    exit 1
fi

# Check if Kafka is restarting due to cluster ID mismatch
if docker-compose -f docker-compose.dev.yml ps | grep -q "kafka-dev.*Restarting"; then
    print_warning "Kafka cluster ID mismatch detected!"
    print_status "Stopping all services and removing volumes..."
    
    # Stop all services and remove volumes
    docker-compose -f docker-compose.dev.yml down -v
    
    print_status "Volumes removed. Restarting infrastructure services..."
    
    # Restart services
    docker-compose -f docker-compose.dev.yml up -d
    
    print_status "Waiting for services to initialize..."
    sleep 20
    
    # Check if Kafka is now running properly
    for i in {1..10}; do
        if docker exec tms-kafka-dev kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
            print_success "Kafka cluster ID mismatch fixed! Kafka is now running properly."
            break
        fi
        if [ $i -eq 10 ]; then
            print_warning "Kafka is still not ready after 10 attempts. It may take a few more minutes to fully initialize."
        fi
        print_status "Waiting for Kafka to be ready... (attempt $i/10)"
        sleep 3
    done
    
else
    print_success "No Kafka cluster ID mismatch detected. Kafka is running normally."
fi

echo ""
echo "📊 Current Status:"
echo "=================="
docker-compose -f docker-compose.dev.yml ps
