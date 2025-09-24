#!/bin/bash

# Local Development Environment Setup with Hot Reloading
# This script sets up your local development environment with hot reloading

set -e

echo "🚀 Starting Local Development Environment with Hot Reloading"
echo "============================================================"

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

# Step 1: Install dependencies
print_status "Step 1: Installing dependencies..."

# Kill any existing processes on development ports
print_status "Cleaning up any existing processes on development ports..."
lsof -ti:4000,4001,4002,4003,4004,3000 | xargs kill -9 2>/dev/null || true
pkill -f "nest start" || true
pkill -f "next dev" || true
pkill -f "concurrently" || true

# Wait for processes to fully terminate
sleep 2

npm install

# Install dependencies for each service
print_status "Installing dependencies for all services..."
cd apps/gateway && npm install && cd ../..
cd apps/user-service && npm install && cd ../..
cd apps/vehicle-service && npm install && cd ../..
cd apps/gps-service && npm install && cd ../..
cd apps/traffic-service && npm install && cd ../..
cd apps/client && npm install && cd ../..

# Step 2: Start infrastructure services
print_status "Step 2: Starting infrastructure services (PostgreSQL, Redis, Kafka)..."

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

# Step 3: Run database migrations
print_status "Step 3: Running database migrations..."

# User Service migrations
print_status "Running User Service migrations..."
cd apps/user-service
export DATABASE_URL="postgresql://postgres:password@localhost:5432/tms_user"
npx prisma migrate deploy
npx prisma generate
cd ../..

# Vehicle Service migrations
print_status "Running Vehicle Service migrations..."
cd apps/vehicle-service
export DATABASE_URL="postgresql://postgres:password@localhost:5433/tms_vehicle"
npx prisma migrate deploy
npx prisma generate
cd ../..

print_success "Database migrations completed!"

# Step 4: Start development servers with hot reloading
print_status "Step 4: Starting development servers with hot reloading..."

# Create a script to start all services with hot reloading
cat > start-dev-services.sh << 'EOF'
#!/bin/bash

# Start all services with hot reloading using concurrently
echo "🔥 Starting all services with hot reloading..."

# Kill any existing processes on development ports
echo "🧹 Cleaning up any existing processes on development ports..."
lsof -ti:4000,4001,4002,4003,4004,3000 | xargs kill -9 2>/dev/null || true
pkill -f "nest start" || true
pkill -f "next dev" || true
pkill -f "concurrently" || true

# Wait for processes to fully terminate
sleep 2

# Start all services concurrently with proper environment variables
npx concurrently \
  --names "GATEWAY,USER,VEHICLE,GPS,TRAFFIC,CLIENT" \
  --prefix-colors "cyan,magenta,yellow,green,blue,red" \
  --kill-others-on-fail \
  "cd apps/gateway && NODE_ENV=development PORT=4000 USER_SERVICE_URL=http://localhost:4001 VEHICLE_SERVICE_URL=http://localhost:4002 GPS_SERVICE_URL=http://localhost:4003 TRAFFIC_SERVICE_URL=http://localhost:4004 AUTH_JWKS_URI=http://localhost:4001/.well-known/jwks.json AUTH_ISSUER=yatms-user-service-dev REDIS_URL=redis://localhost:6379 KAFKA_BROKERS=localhost:9092 npm run start:dev" \
  "cd apps/user-service && NODE_ENV=development PORT=4001 DATABASE_URL=postgresql://postgres:password@localhost:5432/tms_user JWT_SECRET=dev-jwt-secret-key-change-in-production JWT_REFRESH_SECRET=dev-refresh-secret-key-change-in-production REDIS_URL=redis://localhost:6379 KAFKA_BROKERS=localhost:9092 npm run start:dev" \
  "cd apps/vehicle-service && NODE_ENV=development PORT=4002 DATABASE_URL=postgresql://postgres:password@localhost:5433/tms_vehicle REDIS_URL=redis://localhost:6379 KAFKA_BROKERS=localhost:9092 npm run start:dev" \
  "cd apps/gps-service && NODE_ENV=development PORT=4003 DATABASE_URL=postgresql://postgres:password@localhost:5434/tms_gps REDIS_URL=redis://localhost:6379 KAFKA_BROKERS=localhost:9092 npm run start:dev" \
  "cd apps/traffic-service && NODE_ENV=development PORT=4004 REDIS_URL=redis://localhost:6379 KAFKA_BROKERS=localhost:9092 npm run start:dev" \
  "cd apps/client && npm run dev"
EOF

chmod +x start-dev-services.sh

print_success "🎉 Local Development Environment Ready!"
echo ""
echo "📋 Development Environment Summary:"
echo "=================================="
echo "✅ Infrastructure services running in Docker"
echo "✅ Database migrations completed"
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
echo "🚀 Start Development Servers:"
echo "============================="
echo "Run: ./start-dev-services.sh"
echo ""
echo "🛑 Stop Development Environment:"
echo "==============================="
echo "Run: ./scripts/stop-local-dev.sh"
echo ""
echo "📊 Check Service Status:"
echo "======================="
echo "Run: docker-compose -f docker-compose.dev.yml ps"
