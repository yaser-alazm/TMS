#!/bin/bash

# Standardized service management script for TMS microservices
# Usage: ./service-manager.sh [command] [service]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service configurations (using functions instead of associative arrays)
get_service_port() {
  case "$1" in
    "gateway") echo "4000" ;;
    "user-service") echo "4001" ;;
    "vehicle-service") echo "4002" ;;
    "gps-service") echo "4003" ;;
    "traffic-service") echo "4004" ;;
    "client") echo "3000" ;;
    *) echo "" ;;
  esac
}

get_service_path() {
  case "$1" in
    "gateway") echo "apps/gateway" ;;
    "user-service") echo "apps/user-service" ;;
    "vehicle-service") echo "apps/vehicle-service" ;;
    "gps-service") echo "apps/gps-service" ;;
    "traffic-service") echo "apps/traffic-service" ;;
    "client") echo "apps/client" ;;
    *) echo "" ;;
  esac
}

get_all_services() {
  echo "gateway user-service vehicle-service gps-service traffic-service client"
}

# Helper functions
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

# Check if service exists
service_exists() {
  local service=$1
  local port=$(get_service_port "$service")
  if [[ -n "$port" ]]; then
    return 0
  else
    return 1
  fi
}


# Start a single service
start_service() {
  local service=$1
  local port=$(get_service_port $service)
  local path=$(get_service_path $service)
  
  print_status "Starting $service on port $port..."
  
  cd "$path"
  
  # Copy environment file if it exists
  if [[ -f "../../env/$service.env" ]]; then
    cp "../../env/$service.env" .env
    print_status "Environment file copied for $service"
  fi
  
  # Install dependencies if needed
  if [[ ! -d "node_modules" ]]; then
    print_status "Installing dependencies for $service..."
    npm install
  fi
  
  # Start the service
  if [[ "$service" == "client" ]]; then
    npm run dev &
  else
    npm run start:dev &
  fi
  
  cd - > /dev/null
  print_success "$service started on port $port"
}

# Stop a single service
stop_service() {
  local service=$1
  local port=$(get_service_port $service)
  
  print_status "Stopping $service on port $port..."
  
  # Kill process on the port
  lsof -ti:$port | xargs kill -9 2>/dev/null || true
  
  print_success "$service stopped"
}

# Check service health
check_service_health() {
  local service=$1
  local port=$(get_service_port $service)
  
  print_status "Checking health of $service..."
  
  if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
    print_success "$service is healthy"
    return 0
  else
    print_warning "$service health check failed"
    return 1
  fi
}

# Install dependencies for all services
install_all() {
  print_status "Installing dependencies for all services..."
  
  for service in $(get_all_services); do
    local path=$(get_service_path $service)
    print_status "Installing dependencies for $service..."
    cd "$path"
    npm install
    cd - > /dev/null
  done
  
  print_success "All dependencies installed"
}

# Start all services
start_all() {
  print_status "Starting all TMS services..."
  
  for service in $(get_all_services); do
    start_service $service
    sleep 2
  done
  
  print_success "All services started"
}

# Stop all services
stop_all() {
  print_status "Stopping all TMS services..."
  
  for service in $(get_all_services); do
    stop_service $service
  done
  
  print_success "All services stopped"
}

# Check health of all services
health_check_all() {
  print_status "Checking health of all services..."
  
  local all_healthy=true
  
  for service in $(get_all_services); do
    if ! check_service_health $service; then
      all_healthy=false
    fi
  done
  
  if $all_healthy; then
    print_success "All services are healthy"
  else
    print_warning "Some services are not healthy"
  fi
}

# Show service status
show_status() {
  print_status "TMS Services Status:"
  echo
  
  for service in $(get_all_services); do
    local port=$(get_service_port $service)
    local path=$(get_service_path $service)
    
    if lsof -i:$port > /dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} $service (port $port) - Running"
    else
      echo -e "  ${RED}✗${NC} $service (port $port) - Stopped"
    fi
  done
}

# Main command handler
case "$1" in
  "start")
    if [[ -n "$2" ]]; then
      if service_exists "$2"; then
        start_service "$2"
      else
        print_error "Service '$2' not found"
        exit 1
      fi
    else
      start_all
    fi
    ;;
  "stop")
    if [[ -n "$2" ]]; then
      if service_exists "$2"; then
        stop_service "$2"
      else
        print_error "Service '$2' not found"
        exit 1
      fi
    else
      stop_all
    fi
    ;;
  "restart")
    if [[ -n "$2" ]]; then
      if service_exists "$2"; then
        stop_service "$2"
        sleep 2
        start_service "$2"
      else
        print_error "Service '$2' not found"
        exit 1
      fi
    else
      stop_all
      sleep 3
      start_all
    fi
    ;;
  "health")
    if [[ -n "$2" ]]; then
      if service_exists "$2"; then
        check_service_health "$2"
      else
        print_error "Service '$2' not found"
        exit 1
      fi
    else
      health_check_all
    fi
    ;;
  "status")
    show_status
    ;;
  "install")
    install_all
    ;;
  *)
    echo "TMS Service Manager"
    echo
    echo "Usage: $0 [command] [service]"
    echo
    echo "Commands:"
    echo "  start [service]    Start a service or all services"
    echo "  stop [service]     Stop a service or all services"
    echo "  restart [service]  Restart a service or all services"
    echo "  health [service]   Check health of a service or all services"
    echo "  status            Show status of all services"
    echo "  install           Install dependencies for all services"
    echo
    echo "Available services:"
    for service in $(get_all_services); do
      echo "  - $service (port $(get_service_port $service))"
    done
    ;;
esac
