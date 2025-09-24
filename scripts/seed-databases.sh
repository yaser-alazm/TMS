#!/bin/bash

# Database Seeding Script
# This script runs database seeding for all services

set -e

echo "🌱 Running Database Seeding"
echo "=========================="

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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if databases are running
print_status "Checking if databases are running..."
if ! docker-compose -f docker-compose.dev.yml ps | grep -q "postgres-user-dev.*Up"; then
    print_error "User database is not running. Please start infrastructure first with 'npm run dev:infra'"
    exit 1
fi

if ! docker-compose -f docker-compose.dev.yml ps | grep -q "postgres-vehicle-dev.*Up"; then
    print_error "Vehicle database is not running. Please start infrastructure first with 'npm run dev:infra'"
    exit 1
fi

print_success "Databases are running"

# User Service seeding
print_status "Seeding User Service database..."
cd apps/user-service
cp ../../env/user-service.env .env
npm run db:seed
print_success "User Service seeded successfully"
cd ../..

# Vehicle Service seeding
print_status "Seeding Vehicle Service database..."
cd apps/vehicle-service
cp ../../env/vehicle-service.env .env
npm run db:seed
print_success "Vehicle Service seeded successfully"
cd ../..

print_success "🎉 All databases seeded successfully!"
echo ""
echo "📋 Seeded Data:"
echo "==============="
echo "User Service:"
echo "  - Roles: admin, moderator, user"
echo "  - Users: admin, testuser, yaser-az, yaser-hotmail"
echo "  - Password: Password123!"
echo ""
echo "Vehicle Service:"
echo "  - Demo vehicles with maintenance records"
echo "  - Shadow users matching User Service"
echo ""
echo "🔗 Access your data:"
echo "==================="
echo "Adminer: http://localhost:8080"
echo "User Service API: http://localhost:4001"
echo "Vehicle Service API: http://localhost:4002"

