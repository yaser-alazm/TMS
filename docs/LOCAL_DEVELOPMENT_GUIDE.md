# Local Development Environment Guide

This guide will help you set up and run the Transportation Management System locally with hot reloading and all necessary infrastructure services.

## 🚀 Quick Start

### Prerequisites

- **Node.js 18+** - [Download here](https://nodejs.org/)
- **Docker & Docker Compose** - [Download here](https://www.docker.com/products/docker-desktop/)
- **Git** - [Download here](https://git-scm.com/)

### One-Command Setup

```bash
# Clone the repository (if not already done)
git clone <your-repo-url>
cd transportation-management-system

# Start the entire development environment
npm run dev
```

This single command will:
- Install all dependencies
- Start infrastructure services (PostgreSQL, Redis, Kafka)
- Run database migrations
- Set up hot reloading for all services

## 📋 Available Commands

### Development Commands

```bash
# Start complete development environment
npm run dev

# Stop development environment
npm run dev:stop

# Check status of all services
npm run dev:status

# Start only infrastructure services
npm run dev:infra

# Stop infrastructure services
npm run dev:infra:stop

# View infrastructure logs
npm run dev:infra:logs

# Restart infrastructure services
npm run dev:infra:restart
```

### Manual Service Management

```bash
# Start all services with hot reloading
./start-dev-services.sh

# Start individual services
cd apps/gateway && npm run start:dev
cd apps/user-service && npm run start:dev
cd apps/vehicle-service && npm run start:dev
cd apps/gps-service && npm run start:dev
cd apps/traffic-service && npm run start:dev
cd apps/client && npm run dev
```

## 🔗 Service URLs

### Application Services
- **Gateway API**: http://localhost:4000
- **User Service**: http://localhost:4001
- **Vehicle Service**: http://localhost:4002
- **GPS Service**: http://localhost:4003
- **Traffic Service**: http://localhost:4004
- **Client App**: http://localhost:3000

### Development Tools
- **Adminer (Database)**: http://localhost:8080
- **Redis Commander**: http://localhost:8081
- **Kafka UI**: http://localhost:8082

## 🛠️ Development Features

### Hot Reloading
All services are configured with hot reloading:
- **NestJS Services**: Automatically restart on file changes
- **Next.js Client**: Hot module replacement for instant updates
- **TypeScript**: Automatic compilation and type checking

### Database Management
- **PostgreSQL**: Three separate databases for different services
- **Redis**: Caching and session storage
- **Kafka**: Message queuing for event-driven architecture

### Development Tools
- **Adminer**: Web-based database management
- **Redis Commander**: Redis data browser
- **Kafka UI**: Kafka cluster management

## 📊 Service Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client App    │    │   Gateway API   │    │  User Service   │
│   (Next.js)     │◄──►│   (NestJS)      │◄──►│   (NestJS)      │
│   Port: 3000    │    │   Port: 4000    │    │   Port: 4001    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │ Vehicle Service │    │   GPS Service   │
                       │   (NestJS)      │    │   (NestJS)      │
                       │   Port: 4002    │    │   Port: 4003    │
                       └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ Traffic Service │
                       │   (NestJS)      │
                       │   Port: 4004    │
                       └─────────────────┘
```

## 🔧 Configuration

### Environment Variables

Each service has its own environment configuration:

#### Gateway Service
```bash
PORT=4000
USER_SERVICE_URL=http://localhost:4001
VEHICLE_SERVICE_URL=http://localhost:4002
GPS_SERVICE_URL=http://localhost:4003
TRAFFIC_SERVICE_URL=http://localhost:4004
AUTH_JWKS_URI=http://localhost:4001/.well-known/jwks.json
AUTH_ISSUER=yatms-user-service
REDIS_URL=redis://localhost:6379
NODE_ENV=development
```

#### User Service
```bash
PORT=4001
DATABASE_URL=postgresql://postgres:password@localhost:5432/tms_user
JWT_SECRET=your-super-secure-jwt-secret-key-change-this-in-production
JWT_REFRESH_SECRET=your-super-secure-refresh-secret-key-change-this-in-production
REDIS_URL=redis://localhost:6379
NODE_ENV=development
```

#### Vehicle Service
```bash
PORT=4002
DATABASE_URL=postgresql://postgres:password@localhost:5433/tms_vehicle
REDIS_URL=redis://localhost:6379
NODE_ENV=development
```

#### GPS Service
```bash
PORT=4003
DATABASE_URL=postgresql://postgres:password@localhost:5434/tms_gps
REDIS_URL=redis://localhost:6379
NODE_ENV=development
```

#### Traffic Service
```bash
PORT=4004
REDIS_URL=redis://localhost:6379
NODE_ENV=development
```

## 🐛 Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Check what's using a port
lsof -i :4000

# Kill the process
kill -9 <PID>
```

#### Docker Issues
```bash
# Restart Docker services
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.dev.yml up -d

# Check Docker logs
docker-compose -f docker-compose.dev.yml logs -f
```

#### Database Connection Issues
```bash
# Check if databases are running
docker-compose -f docker-compose.dev.yml ps

# Restart databases
docker-compose -f docker-compose.dev.yml restart postgres-user-dev postgres-vehicle-dev postgres-gps-dev
```

#### Service Not Starting
```bash
# Check service status
npm run dev:status

# View specific service logs
cd apps/gateway && npm run start:dev
```

### Reset Everything

If you encounter persistent issues:

```bash
# Stop everything
npm run dev:stop

# Clean Docker volumes
docker-compose -f docker-compose.dev.yml down -v

# Remove node_modules and reinstall
rm -rf node_modules
rm -rf apps/*/node_modules
npm install

# Start fresh
npm run dev
```

## 📝 Development Workflow

### 1. Start Development Environment
```bash
npm run dev
```

### 2. Make Changes
- Edit any service code
- Changes will automatically reload
- Check the terminal for compilation errors

### 3. Test Changes
- Use the service URLs to test your changes
- Check the development tools for database/Redis/Kafka status

### 4. Stop When Done
```bash
npm run dev:stop
```

## 🔍 Monitoring and Debugging

### View Logs
```bash
# All infrastructure logs
npm run dev:infra:logs

# Specific service logs
cd apps/gateway && npm run start:dev
```

### Database Access
- **Adminer**: http://localhost:8080
- **Connection**: Use the service-specific database URLs from the environment variables

### Redis Access
- **Redis Commander**: http://localhost:8081
- **CLI**: `docker exec -it tms-redis-dev redis-cli`

### Kafka Access
- **Kafka UI**: http://localhost:8082
- **CLI**: `docker exec -it tms-kafka-dev kafka-console-consumer --bootstrap-server localhost:9092 --topic <topic-name>`

## 🚀 Production vs Development

### Development (Local)
- Hot reloading enabled
- Debug logging
- Local databases
- Development tools available

### Production (Railway)
- Optimized builds
- Production databases
- No development tools
- Environment-specific configuration

## 📚 Additional Resources

- [NestJS Documentation](https://docs.nestjs.com/)
- [Next.js Documentation](https://nextjs.org/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
