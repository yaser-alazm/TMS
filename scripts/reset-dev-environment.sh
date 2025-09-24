#!/bin/bash

# Reset Development Environment
# This script completely resets the development environment to fix any issues

set -e

echo "🔄 Resetting Development Environment"
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Stop all services
print_status "Step 1: Stopping all services..."
pkill -f "nest start" || true
pkill -f "next dev" || true
pkill -f "concurrently" || true

# Step 2: Stop and remove Docker containers
print_status "Step 2: Stopping and removing Docker containers..."
docker-compose -f docker-compose.dev.yml down -v

# Step 3: Remove Docker volumes (this will delete all data)
print_status "Step 3: Removing Docker volumes..."
docker volume prune -f

# Step 4: Clean up temporary files
print_status "Step 4: Cleaning up temporary files..."
rm -f start-dev-services.sh

# Step 5: Reinstall dependencies
print_status "Step 5: Reinstalling dependencies..."
rm -rf node_modules
rm -rf apps/*/node_modules
npm install

print_success "🎉 Development Environment Reset Complete!"
echo ""
echo "📋 Reset Summary:"
echo "================"
echo "✅ All services stopped"
echo "✅ Docker containers removed"
echo "✅ Docker volumes cleared"
echo "✅ Dependencies reinstalled"
echo ""
echo "🚀 Start Fresh Development Environment:"
echo "======================================"
echo "Run: npm run dev"
echo ""
echo "⚠️  Note: All database data has been cleared!"
