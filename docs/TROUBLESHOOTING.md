# TMS Troubleshooting Guide

## Quick Diagnostics

### 1. Check Service Status
```bash
# Check all services are running
curl http://localhost:4000/health
curl http://localhost:4001/health
curl http://localhost:4002/health
curl http://localhost:4003/health
curl http://localhost:4004/health
```

### 2. Check Docker Containers
```bash
# List running containers
docker ps

# Check container logs
docker logs gateway
docker logs user-service
docker logs vehicle-service
```

### 3. Check System Resources
```bash
# Memory usage
free -h

# Disk usage
df -h

# CPU usage
top
```

## Common Issues & Solutions

### Service Won't Start

#### Issue: Port Already in Use
```bash
# Error: EADDRINUSE: address already in use :::4000
```

**Solution:**
```bash
# Find process using port
lsof -i :4000

# Kill process
kill -9 <PID>

# Or use different port
export PORT=4001
```

#### Issue: Database Connection Failed
```bash
# Error: Can't reach database server
```

**Solution:**
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Start PostgreSQL
docker-compose up -d postgres

# Test connection
psql -h localhost -U postgres -d tms_user
```

#### Issue: Redis Connection Failed
```bash
# Error: Redis connection failed
```

**Solution:**
```bash
# Check Redis status
docker ps | grep redis

# Start Redis
docker-compose up -d redis

# Test connection
redis-cli ping
```

### Authentication Issues

#### Issue: JWT Token Invalid
```bash
# Error: Invalid token
```

**Solution:**
```bash
# Check JWT secret
echo $JWT_SECRET

# Verify token format
echo "your-token" | base64 -d

# Get new token
curl -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

#### Issue: JWKS Endpoint Not Working
```bash
# Error: JWKS endpoint not found
```

**Solution:**
```bash
# Check JWKS endpoint
curl http://localhost:4001/.well-known/jwks.json

# Restart user service
docker restart user-service
```

### Database Issues

#### Issue: Migration Failed
```bash
# Error: Migration failed
```

**Solution:**
```bash
# Reset database
cd apps/user-service
npx prisma migrate reset

# Run migrations
npx prisma migrate dev

# Generate client
npx prisma generate
```

#### Issue: Database Schema Out of Sync
```bash
# Error: Schema mismatch
```

**Solution:**
```bash
# Push schema to database
npx prisma db push

# Or create migration
npx prisma migrate dev --name fix-schema
```

### Docker Issues

#### Issue: Container Won't Start
```bash
# Error: Container failed to start
```

**Solution:**
```bash
# Check container logs
docker logs <container-name>

# Check image exists
docker images | grep tms

# Rebuild image
docker build -t tms-user-service ./apps/user-service/
```

#### Issue: Out of Disk Space
```bash
# Error: No space left on device
```

**Solution:**
```bash
# Clean up Docker
docker system prune -f
docker volume prune -f
docker image prune -f

# Remove unused images
docker rmi $(docker images -q --filter "dangling=true")
```

### Network Issues

#### Issue: Services Can't Communicate
```bash
# Error: Connection refused
```

**Solution:**
```bash
# Check Docker network
docker network ls
docker network inspect <network-name>

# Recreate network
docker network rm tms-network
docker network create tms-network
```

#### Issue: External API Calls Failing
```bash
# Error: External API timeout
```

**Solution:**
```bash
# Check API key
echo $GOOGLE_MAPS_API_KEY

# Test API directly
curl "https://maps.googleapis.com/maps/api/geocode/json?address=New+York&key=$GOOGLE_MAPS_API_KEY"

# Check network connectivity
ping google.com
```

## Production Issues

### AWS-Specific Issues

#### Issue: EC2 Instance Not Accessible
```bash
# Error: Connection timeout
```

**Solution:**
```bash
# Check instance status
aws ec2 describe-instances --instance-ids i-xxx

# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxx

# Check if instance is running
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"
```

#### Issue: RDS Connection Failed
```bash
# Error: Can't reach database server
```

**Solution:**
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier tms-user-db

# Check security groups
aws rds describe-db-instances --db-instance-identifier tms-user-db --query 'DBInstances[0].VpcSecurityGroups'

# Test connection from EC2
ssh -i tms-key.pem ec2-user@3.123.1.193
timeout 5 bash -c '</dev/tcp/tms-user-db.c7cwe8uog972.eu-central-1.rds.amazonaws.com/5432'
```

#### Issue: ElastiCache Connection Failed
```bash
# Error: Redis connection failed
```

**Solution:**
```bash
# Check ElastiCache status
aws elasticache describe-cache-clusters --cache-cluster-id tms-redis

# Get endpoint
aws elasticache describe-cache-clusters --cache-cluster-id tms-redis --query 'CacheClusters[0].Endpoint.Address'
```

### Performance Issues

#### Issue: High Memory Usage
```bash
# Check memory usage
free -h
docker stats
```

**Solution:**
```bash
# Restart services
docker restart gateway user-service vehicle-service

# Clean up logs
docker logs --tail 1000 gateway > /dev/null

# Upgrade instance type
aws ec2 modify-instance-attribute --instance-id i-xxx --instance-type t3.small
```

#### Issue: Slow Database Queries
```bash
# Check database performance
```

**Solution:**
```bash
# Check slow queries
aws rds describe-db-instances --db-instance-identifier tms-user-db --query 'DBInstances[0].PerformanceInsightsEnabled'

# Enable performance insights
aws rds modify-db-instance --db-instance-identifier tms-user-db --enable-performance-insights
```

## Log Analysis

### Service Logs
```bash
# View recent logs
docker logs --tail 100 gateway

# Follow logs in real-time
docker logs -f user-service

# Filter for errors
docker logs user-service | grep ERROR

# Filter for specific patterns
docker logs user-service | grep "database"
```

### Application Logs
```bash
# Check application logs
tail -f /var/log/tms/gateway.log
tail -f /var/log/tms/user-service.log

# Search for specific errors
grep -i "error" /var/log/tms/*.log
grep -i "timeout" /var/log/tms/*.log
```

### System Logs
```bash
# Check system logs
journalctl -u docker
journalctl -u docker-compose

# Check for memory issues
dmesg | grep -i "killed process"
```

## Monitoring & Alerting

### Health Check Monitoring
```bash
# Create health check script
cat > health-check.sh << 'EOF'
#!/bin/bash
services=("gateway:4000" "user-service:4001" "vehicle-service:4002" "gps-service:4003" "traffic-service:4004")

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    if curl -s http://localhost:$port/health > /dev/null; then
        echo "✅ $name is healthy"
    else
        echo "❌ $name is unhealthy"
        # Send alert
        curl -X POST "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" \
             -H "Content-Type: application/json" \
             -d "{\"text\":\"$name service is down!\"}"
    fi
done
EOF

chmod +x health-check.sh
```

### Resource Monitoring
```bash
# Create resource monitoring script
cat > resource-monitor.sh << 'EOF'
#!/bin/bash
# Check memory usage
memory_usage=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
if (( $(echo "$memory_usage > 80" | bc -l) )); then
    echo "⚠️ High memory usage: ${memory_usage}%"
fi

# Check disk usage
disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $disk_usage -gt 80 ]; then
    echo "⚠️ High disk usage: ${disk_usage}%"
fi

# Check CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
if (( $(echo "$cpu_usage > 80" | bc -l) )); then
    echo "⚠️ High CPU usage: ${cpu_usage}%"
fi
EOF

chmod +x resource-monitor.sh
```

## Recovery Procedures

### Service Recovery
```bash
# Restart all services
docker-compose restart

# Restart specific service
docker restart user-service

# Recreate service
docker-compose up -d --force-recreate user-service
```

### Database Recovery
```bash
# Restore from backup
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier tms-user-db-restored \
    --db-snapshot-identifier tms-user-backup-20250921

# Point application to restored database
export DATABASE_URL="postgresql://postgres:password@restored-db:5432/tms_user"
```

### Complete System Recovery
```bash
# Stop all services
docker-compose down

# Clean up
docker system prune -f

# Restart infrastructure
docker-compose up -d

# Redeploy application
./scripts/deploy-to-ec2.sh deploy
```

## Prevention Strategies

### Regular Maintenance
```bash
# Daily health checks
0 9 * * * /path/to/health-check.sh

# Weekly cleanup
0 2 * * 0 docker system prune -f

# Monthly backups
0 3 1 * * aws rds create-db-snapshot --db-instance-identifier tms-user-db --db-snapshot-identifier tms-user-backup-$(date +%Y%m%d)
```

### Monitoring Setup
```bash
# Install monitoring tools
sudo apt-get update
sudo apt-get install htop iotop nethogs

# Set up log rotation
sudo nano /etc/logrotate.d/tms
```

### Backup Strategy
```bash
# Database backups
aws rds create-db-snapshot --db-instance-identifier tms-user-db --db-snapshot-identifier daily-backup-$(date +%Y%m%d)

# Application backups
tar -czf tms-backup-$(date +%Y%m%d).tar.gz /path/to/application

# Configuration backups
cp -r /etc/tms /backup/tms-config-$(date +%Y%m%d)
```

## Getting Help

### Debug Information Collection
```bash
# Collect system information
cat > collect-debug-info.sh << 'EOF'
#!/bin/bash
echo "=== System Information ===" > debug-info.txt
uname -a >> debug-info.txt
free -h >> debug-info.txt
df -h >> debug-info.txt

echo "=== Docker Information ===" >> debug-info.txt
docker version >> debug-info.txt
docker ps >> debug-info.txt
docker images >> debug-info.txt

echo "=== Service Logs ===" >> debug-info.txt
docker logs gateway --tail 100 >> debug-info.txt
docker logs user-service --tail 100 >> debug-info.txt

echo "=== Network Information ===" >> debug-info.txt
netstat -tulpn >> debug-info.txt
EOF

chmod +x collect-debug-info.sh
./collect-debug-info.sh
```

### Support Channels
1. **Check Documentation**: Review docs/ folder
2. **Check Logs**: Use log analysis commands above
3. **Test Connectivity**: Use health check endpoints
4. **Review Configuration**: Check .env files and Docker configs
5. **Collect Debug Info**: Run debug information collection script

This troubleshooting guide should help you resolve most common issues with the Transportation Management System.
