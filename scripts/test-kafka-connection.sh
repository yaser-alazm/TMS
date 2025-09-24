#!/bin/bash

# Test Kafka Connection Script
# This script tests the Kafka connection to ensure it's working

set -e

echo "🔍 Testing Kafka Connection"
echo "==========================="

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

# Check if Kafka container is running
print_status "Checking if Kafka container is running..."
if ! docker ps | grep -q "tms-kafka-dev"; then
    print_error "Kafka container is not running"
    print_status "Start Kafka with: docker-compose -f docker-compose.dev.yml up -d kafka-dev"
    exit 1
fi

print_success "Kafka container is running"

# Test Kafka connectivity
print_status "Testing Kafka connectivity..."
if docker exec tms-kafka-dev kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
    print_success "Kafka is accessible"
else
    print_error "Kafka is not accessible"
    exit 1
fi

# Test Kafka from host machine
print_status "Testing Kafka from host machine..."
if timeout 10 bash -c "</dev/tcp/localhost/9092" 2>/dev/null; then
    print_success "Kafka port 9092 is accessible from host"
else
    print_error "Kafka port 9092 is not accessible from host"
    exit 1
fi

# Test Kafka with a simple topic operation
print_status "Testing Kafka topic operations..."
if docker exec tms-kafka-dev kafka-topics --bootstrap-server localhost:9092 --create --topic test-topic --partitions 1 --replication-factor 1 --if-not-exists > /dev/null 2>&1; then
    print_success "Kafka topic creation successful"
    
    # Clean up test topic
    docker exec tms-kafka-dev kafka-topics --bootstrap-server localhost:9092 --delete --topic test-topic > /dev/null 2>&1
    print_success "Test topic cleaned up"
else
    print_error "Kafka topic operations failed"
    exit 1
fi

echo ""
print_success "🎉 Kafka Connection Test Completed Successfully!"
echo ""
echo "📋 Test Summary:"
echo "==============="
echo "✅ Kafka container is running"
echo "✅ Kafka is accessible from container"
echo "✅ Kafka port 9092 is accessible from host"
echo "✅ Kafka topic operations work"
echo ""
echo "🔧 Kafka Configuration:"
echo "======================="
echo "Host: localhost"
echo "Port: 9092"
echo "Bootstrap Server: localhost:9092"
echo ""
echo "🚀 Next Steps:"
echo "============="
echo "1. Start development environment: npm run dev"
echo "2. Check service logs for Kafka connections"
echo "3. Use Kafka UI: http://localhost:8082"
