# TMS Quick Start Guide

## 🚀 Getting Started in 5 Minutes

### Prerequisites
- Node.js 18+ and npm
- Docker and Docker Compose
- Git

### 1. Clone and Install
```bash
git clone <your-repo-url>
cd transportation-management-system
npm install
```

### 2. Start Local Environment
```bash
# Start infrastructure (PostgreSQL, Redis, Kafka)
docker-compose up -d

# Start all services
npm run dev
```

### 3. Test the API
```bash
# Health check
curl http://localhost:4000/health

# Register a user
curl -X POST http://localhost:4000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","firstName":"Test","lastName":"User"}'

# Login
curl -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## 🏗️ Development Workflow

### Running Individual Services
```bash
# User Service
cd apps/user-service
npm run start:dev

# Vehicle Service  
cd apps/vehicle-service
npm run start:dev

# Gateway
cd apps/gateway
npm run start:dev
```

### Database Management
```bash
# Run migrations
cd apps/user-service
npx prisma migrate dev
npx prisma generate

# View database
npx prisma studio
```

### Testing
```bash
# Run all tests
npm test

# Run specific service tests
cd apps/user-service
npm test
```

## 🚀 Production Deployment

### One-Command Deployment
```bash
# Setup everything
./scripts/setup-aws-infrastructure.sh
./scripts/deploy-to-ec2.sh all
```

### Manual Steps
```bash
# 1. Build and push images
./scripts/deploy-to-ec2.sh build

# 2. Deploy to EC2
./scripts/deploy-to-ec2.sh deploy

# 3. Verify deployment
curl http://3.123.1.193:4000/health
```

## 📊 Service Endpoints

| Service | Port | Health Check | Main Endpoints |
|---------|------|--------------|----------------|
| Gateway | 4000 | `/health` | `/api/auth/*`, `/api/users/*`, `/api/vehicles/*` |
| User | 4001 | `/health` | `/users`, `/auth/login`, `/auth/register` |
| Vehicle | 4002 | `/health` | `/vehicles`, `/vehicles/owner/:id` |
| GPS | 4003 | `/health` | `/gps/locations`, `/gps/track` |
| Traffic | 4004 | `/health` | `/traffic/conditions`, `/traffic/routes` |

## 🔧 Common Commands

### Development
```bash
# Start all services
npm run dev

# Build for production
npm run build

# Run tests
npm test

# Lint code
npm run lint
```

### Docker
```bash
# Build images
docker build -t tms-user-service ./apps/user-service/

# Run container
docker run -p 4001:4001 tms-user-service

# View logs
docker logs <container-id>
```

### AWS CLI
```bash
# Check EC2 status
aws ec2 describe-instances

# Check RDS status
aws rds describe-db-instances

# Check ElastiCache
aws elasticache describe-cache-clusters
```

## 🐛 Troubleshooting

### Service Not Starting
```bash
# Check logs
docker logs <service-name>

# Check if port is available
netstat -tulpn | grep :4001

# Restart service
docker restart <service-name>
```

### Database Connection Issues
```bash
# Test connection
psql -h localhost -U postgres -d tms_user

# Check if database exists
psql -h localhost -U postgres -c "\l"
```

### Memory Issues
```bash
# Check memory usage
free -h
docker stats

# Clean up Docker
docker system prune -f
```

## 📈 Monitoring

### Health Checks
```bash
# All services
curl http://localhost:4000/health
curl http://localhost:4001/health
curl http://localhost:4002/health
curl http://localhost:4003/health
curl http://localhost:4004/health
```

### Log Monitoring
```bash
# Follow logs
docker logs -f gateway
docker logs -f user-service

# Check specific errors
docker logs user-service | grep ERROR
```

## 🔐 Security

### JWT Token Management
```bash
# Get JWKS
curl http://localhost:4001/.well-known/jwks.json

# Validate token
curl -H "Authorization: Bearer <token>" http://localhost:4000/api/users/me
```

### Environment Variables
```bash
# Check environment
echo $DATABASE_URL
echo $JWT_SECRET

# Set production environment
export NODE_ENV=production
export DATABASE_URL=postgresql://...
```

## 📚 Additional Resources

- [Full Deployment Guide](./DEPLOYMENT_GUIDE.md)
- [Architecture Documentation](./ARCHITECTURE.md)
- [API Documentation](./API_DOCUMENTATION.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)

## 🆘 Getting Help

1. **Check logs**: `docker logs <service-name>`
2. **Verify health**: `curl http://localhost:4000/health`
3. **Check documentation**: See docs/ folder
4. **Review configuration**: Check .env files
5. **Test connectivity**: Use health check endpoints

---

**Happy Coding! 🎉**
