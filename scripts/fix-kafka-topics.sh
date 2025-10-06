#!/bin/bash

# Fix Kafka Topics After Restart
# This script recreates Kafka topics to fix leadership issues after restart

set -e

echo "🔧 Fixing Kafka Topics After Restart"
echo "===================================="

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

# Check if Kafka is running
print_status "Checking if Kafka is running..."
if ! docker ps | grep -q "tms-kafka-dev"; then
    print_error "Kafka container is not running. Please start it first with: docker-compose -f docker-compose.dev.yml up -d kafka-dev"
    exit 1
fi

print_success "Kafka container is running"

# Wait for Kafka to be ready
print_status "Waiting for Kafka to be ready..."
sleep 5

# Function to recreate topic
recreate_topic() {
    local topic_name=$1
    print_status "Recreating topic: $topic_name"
    
    # Delete topic if it exists
    docker exec tms-kafka-dev kafka-topics --bootstrap-server localhost:9092 --delete --topic "$topic_name" 2>/dev/null || true
    
    # Create topic
    docker exec tms-kafka-dev kafka-topics --bootstrap-server localhost:9092 --create --topic "$topic_name" --partitions 3 --replication-factor 1
    
    print_success "Topic $topic_name recreated successfully"
}

# Recreate all required topics
recreate_topic "route-optimization-events"
recreate_topic "route-update-events"
recreate_topic "user-events"
recreate_topic "user-responses"
recreate_topic "vehicle-requests"
recreate_topic "vehicle-responses"
recreate_topic "gps-events"
recreate_topic "gps-responses"

# List all topics to verify
print_status "Listing all topics to verify recreation..."
docker exec tms-kafka-dev kafka-topics --bootstrap-server localhost:9092 --list

print_success "🎉 Kafka topics fixed successfully!"
echo ""
echo "📋 Topics recreated:"
echo "==================="
echo "✅ route-optimization-events"
echo "✅ route-update-events"
echo "✅ user-events"
echo "✅ user-responses"
echo "✅ vehicle-requests"
echo "✅ vehicle-responses"
echo "✅ gps-events"
echo "✅ gps-responses"
echo ""
echo "🔄 You can now test Kafka publishing in your services."
