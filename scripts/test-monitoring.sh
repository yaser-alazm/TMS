#!/bin/bash

echo "🧪 TMS Monitoring System Status Check"
echo "======================================"

echo ""
echo "📊 Monitoring Services Status:"
docker ps --filter "name=tms-prometheus-dev|tms-grafana-dev|tms-node-exporter-dev|tms-cadvisor-dev" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🔗 Access URLs:"
echo "   • Grafana Dashboard: http://localhost:3001 (admin/admin123)"
echo "   • Prometheus: http://localhost:9090"
echo "   • Prometheus Targets: http://localhost:9090/targets"
echo "   • Node Exporter: http://localhost:9100"
echo "   • cAdvisor: http://localhost:8083"

echo ""
echo "🧪 Testing Metrics Endpoints:"
echo "Testing if microservices are exposing metrics..."

# Test each service's metrics endpoint
services=("4000:Gateway" "4001:User Service" "4002:Vehicle Service" "4003:GPS Service" "4004:Traffic Service")

for service in "${services[@]}"; do
    port=$(echo $service | cut -d: -f1)
    name=$(echo $service | cut -d: -f2)
    
    if curl -s --connect-timeout 2 http://localhost:$port/metrics > /dev/null 2>&1; then
        echo "   ✅ $name (port $port) - Metrics endpoint accessible"
    else
        echo "   ❌ $name (port $port) - Metrics endpoint not accessible (service may not be running)"
    fi
done

echo ""
echo "📋 Next Steps:"
echo "1. Start your microservices: npm run dev:microservices"
echo "2. Check Prometheus targets: http://localhost:9090/targets"
echo "3. Access Grafana dashboards: http://localhost:3001"
echo "4. Set up alerts and notifications as needed"

echo ""
echo "🎉 TMS Monitoring System Status Check Complete!"
