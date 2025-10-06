#!/bin/bash

# Script to update @yatms/common package across all services
# This script will update the common package in all microservices

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

# Function to update common package in a service
update_service() {
    local service_name=$1
    local service_path=$2
    
    print_status "Updating @yatms/common in $service_name..."
    
    if [ ! -d "$service_path" ]; then
        print_error "Service directory not found: $service_path"
        return 1
    fi
    
    cd "$service_path"
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        print_error "package.json not found in $service_path"
        return 1
    fi
    
    # Check if @yatms/common is listed as a dependency
    if ! grep -q "@yatms/common" package.json; then
        print_warning "@yatms/common not found in $service_name dependencies, skipping..."
        return 0
    fi
    
    # Update the package
    if npm update @yatms/common; then
        print_success "Updated @yatms/common in $service_name"
    else
        print_error "Failed to update @yatms/common in $service_name"
        return 1
    fi
    
    return 0
}

# Main execution
main() {
    print_status "🚀 Starting @yatms/common package update across all services..."
    echo ""
    
    # Get the script directory (should be in scripts/)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    
    print_status "Project root: $PROJECT_ROOT"
    echo ""
    
    # Define services to update (using arrays instead of associative arrays)
    SERVICES=(
        "gateway:apps/gateway"
        "user-service:apps/user-service"
        "vehicle-service:apps/vehicle-service"
        "gps-service:apps/gps-service"
        "traffic-service:apps/traffic-service"
        "client:apps/client"
    )
    
    # Track results
    local success_count=0
    local total_count=${#SERVICES[@]}
    local failed_services=()
    
    # Update each service
    for service_entry in "${SERVICES[@]}"; do
        service_name="${service_entry%%:*}"
        service_path="$PROJECT_ROOT/${service_entry##*:}"
        
        echo "----------------------------------------"
        if update_service "$service_name" "$service_path"; then
            ((success_count++))
        else
            failed_services+=("$service_name")
        fi
        echo ""
    done
    
    # Summary
    echo "========================================"
    print_status "📊 Update Summary:"
    echo "========================================"
    print_success "Successfully updated: $success_count/$total_count services"
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        print_error "Failed services:"
        for service in "${failed_services[@]}"; do
            echo "  - $service"
        done
        echo ""
        print_warning "Some services failed to update. Check the logs above for details."
        exit 1
    else
        print_success "🎉 All services updated successfully!"
        echo ""
        print_status "Next steps:"
        echo "1. Test your services to ensure everything works correctly"
        echo "2. If you made changes to the common package, consider rebuilding affected services"
        echo "3. Check for any breaking changes in the updated common package"
    fi
}

# Check if we're in the right directory
if [ ! -f "package.json" ] && [ ! -d "apps" ]; then
    print_error "This script should be run from the project root directory"
    print_error "Expected to find 'apps' directory or 'package.json' file"
    exit 1
fi

# Run main function
main "$@"
