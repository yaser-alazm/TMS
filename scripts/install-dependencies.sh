#!/bin/bash

# Install Dependencies for All Services
# This script installs dependencies for all services in the project

set -e

echo "📦 Installing Dependencies for All Services"
echo "==========================================="

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

# Install root dependencies
print_status "Installing root dependencies..."
npm install

# Install dependencies for each service
services=("gateway" "user-service" "vehicle-service" "gps-service" "traffic-service" "client")

for service in "${services[@]}"; do
    print_status "Installing dependencies for $service..."
    cd "apps/$service"
    npm install
    cd ../..
    print_success "$service dependencies installed"
done

print_success "🎉 All Dependencies Installed Successfully!"
echo ""
echo "📋 Installation Summary:"
echo "======================="
echo "✅ Root dependencies installed"
echo "✅ Gateway service dependencies installed"
echo "✅ User service dependencies installed"
echo "✅ Vehicle service dependencies installed"
echo "✅ GPS service dependencies installed"
echo "✅ Traffic service dependencies installed"
echo "✅ Client dependencies installed"
echo ""
echo "🚀 Next Steps:"
echo "============="
echo "1. Start development environment: npm run dev"
echo "2. Or start infrastructure only: npm run dev:infra"
echo "3. Check status: npm run dev:status"
