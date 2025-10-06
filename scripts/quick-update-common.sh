#!/bin/bash

# Quick script to update @yatms/common package across all services
# Usage: ./scripts/quick-update-common.sh

set -e

echo "🚀 Updating @yatms/common across all services..."

# Update each service
for service in gateway user-service vehicle-service gps-service traffic-service client; do
    echo "📦 Updating $service..."
    cd "apps/$service" && npm update @yatms/common && cd ../..
done

echo "✅ All services updated successfully!"
echo ""
echo "Next steps:"
echo "1. Test your services to ensure everything works correctly"
echo "2. If you made changes to the common package, consider rebuilding affected services"

