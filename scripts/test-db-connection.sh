#!/bin/bash

# Test Database Connection Script
# This script tests the database connections to ensure they're working

set -e

echo "🔍 Testing Database Connections"
echo "=============================="

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

# Function to test database connection
test_db_connection() {
    local db_name=$1
    local port=$2
    local container_name=$3
    
    print_status "Testing $db_name connection on port $port..."
    
    # Test if container is running
    if ! docker ps | grep -q "$container_name"; then
        print_error "$db_name container is not running"
        return 1
    fi
    
    # Test database connectivity
    if docker exec "$container_name" pg_isready -U postgres -d "$db_name" > /dev/null 2>&1; then
        print_success "$db_name is ready and accepting connections"
        
        # Test actual connection with credentials
        if docker exec "$container_name" psql -U postgres -d "$db_name" -c "SELECT 1;" > /dev/null 2>&1; then
            print_success "$db_name authentication successful"
        else
            print_error "$db_name authentication failed"
            return 1
        fi
    else
        print_error "$db_name is not ready"
        return 1
    fi
}

# Test all databases
echo ""
print_status "Testing all database connections..."

# Test User Database
test_db_connection "tms_user" "5432" "tms-postgres-user-dev"

# Test Vehicle Database
test_db_connection "tms_vehicle" "5433" "tms-postgres-vehicle-dev"

# Test GPS Database
test_db_connection "tms_gps" "5434" "tms-postgres-gps-dev"

echo ""
print_status "Testing Prisma connections..."

# Test Prisma connection for User Service
print_status "Testing User Service Prisma connection..."
cd apps/user-service
export DATABASE_URL="postgresql://postgres:password@localhost:5432/tms_user"
if npx prisma db pull --force > /dev/null 2>&1; then
    print_success "User Service Prisma connection successful"
else
    print_error "User Service Prisma connection failed"
fi
cd ../..

# Test Prisma connection for Vehicle Service
print_status "Testing Vehicle Service Prisma connection..."
cd apps/vehicle-service
export DATABASE_URL="postgresql://postgres:password@localhost:5433/tms_vehicle"
if npx prisma db pull --force > /dev/null 2>&1; then
    print_success "Vehicle Service Prisma connection successful"
else
    print_error "Vehicle Service Prisma connection failed"
fi
cd ../..

echo ""
print_success "🎉 Database connection tests completed!"
echo ""
echo "📋 Connection Summary:"
echo "====================="
echo "If all tests passed, your databases are ready for development."
echo "If any tests failed, check the Docker containers and credentials."
echo ""
echo "🔧 Troubleshooting:"
echo "=================="
echo "1. Check if containers are running: docker-compose -f docker-compose.dev.yml ps"
echo "2. View container logs: docker-compose -f docker-compose.dev.yml logs"
echo "3. Restart containers: docker-compose -f docker-compose.dev.yml restart"
echo "4. Reset environment: npm run dev:reset"
