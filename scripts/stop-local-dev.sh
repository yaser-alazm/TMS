#!/bin/bash

# Stop Local Development Environment
# This script stops all development services and cleans up

set -e

echo "🛑 Stopping Local Development Environment"
echo "========================================="

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

# Step 1: Stop development servers
print_status "Step 1: Stopping development servers..."
pkill -f "nest start" || true
pkill -f "next dev" || true
pkill -f "concurrently" || true

print_success "Development servers stopped"

# Step 2: Stop infrastructure services
print_status "Step 2: Stopping infrastructure services..."
docker-compose -f docker-compose.dev.yml down

print_success "Infrastructure services stopped"

# Step 3: Clean up temporary files
print_status "Step 3: Cleaning up temporary files..."
rm -f start-dev-services.sh

print_success "Temporary files cleaned up"

print_success "🎉 Local Development Environment Stopped Successfully!"
echo ""
echo "📋 Cleanup Summary:"
echo "=================="
echo "✅ Development servers stopped"
echo "✅ Infrastructure services stopped"
echo "✅ Temporary files cleaned up"
echo ""
echo "🔄 To restart development environment:"
echo "====================================="
echo "Run: ./scripts/start-local-dev.sh"
