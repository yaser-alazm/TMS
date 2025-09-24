#!/bin/bash

# Clean Development Ports Script
# This script kills any processes using development ports

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

echo "🧹 Cleaning Development Ports"
echo "=============================="

# Development ports
PORTS="4000,4001,4002,4003,4004,3000"

print_status "Checking for processes using development ports: $PORTS"

# Kill processes using development ports
PIDS=$(lsof -ti:$PORTS 2>/dev/null || true)
if [ -n "$PIDS" ]; then
    print_warning "Found processes using development ports: $PIDS"
    print_status "Killing processes..."
    echo "$PIDS" | xargs kill -9 2>/dev/null || true
    print_success "Processes killed"
else
    print_success "No processes found using development ports"
fi

# Kill any remaining NestJS/Next.js processes
print_status "Killing any remaining development processes..."
pkill -f "nest start" || true
pkill -f "next dev" || true
pkill -f "concurrently" || true

# Wait for processes to fully terminate
sleep 2

print_success "Port cleanup completed!"
echo ""
echo "📊 Port Status:"
echo "==============="
for port in 3000 4000 4001 4002 4003 4004; do
    if lsof -i:$port > /dev/null 2>&1; then
        echo "Port $port: ❌ In use"
    else
        echo "Port $port: ✅ Available"
    fi
done
