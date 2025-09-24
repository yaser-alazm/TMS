# TMS Service Standardization Guide

## 🎯 **Overview**

This document outlines the standardized configurations and practices implemented across all TMS microservices to ensure consistency, maintainability, and better development experience.

## 📋 **Standardized Configurations**

### **1. Package.json Metadata**
All services now have consistent metadata:
```json
{
  "name": "service-name",
  "version": "0.0.1",
  "description": "Clear description of service purpose",
  "author": "Yaser Alazm",
  "private": true,
  "license": "UNLICENSED"
}
```

### **2. Standardized Scripts**
All NestJS services include these scripts:
```json
{
  "scripts": {
    "build": "nest build",
    "format": "prettier --write \"src/**/*.ts\" \"test/**/*.ts\"",
    "start": "nest start",
    "start:dev": "nest start --watch",
    "start:debug": "nest start --debug --watch",
    "start:prod": "node dist/main",
    "start:hot": "nest start --watch --preserveWatchOutput",
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:cov": "jest --coverage",
    "test:debug": "node --inspect-brk -r tsconfig-paths/register -r ts-node/register node_modules/.bin/jest --runInBand",
    "test:e2e": "jest --config ./test/jest-e2e.json"
  }
}
```

### **3. Dockerfile Standardization**
All services use Node.js 20 Alpine with consistent structure:

**Production Dockerfile:**
```dockerfile
FROM node:20-alpine
RUN apk add --no-cache openssl libc6-compat
WORKDIR /app
COPY package*.json ./
RUN npm install --production=false
COPY . .
RUN npm run build
RUN npm prune --production
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001
RUN chown -R nestjs:nodejs /app
USER nestjs
EXPOSE [PORT]
ENV NODE_ENV=production
ENV PORT=[PORT]
CMD ["node", "dist/main.js"]
```

**Development Dockerfile:**
```dockerfile
FROM node:20-alpine
RUN apk add --no-cache openssl libc6-compat
RUN npm install -g nodemon
WORKDIR /app
COPY package*.json ./
COPY tsconfig*.json ./
RUN npm install
COPY . .
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001
RUN chown -R nestjs:nodejs /app
USER nestjs
EXPOSE [PORT]
ENV NODE_ENV=development
ENV PORT=[PORT]
CMD ["npm", "run", "start:dev"]
```

### **4. Health Check Endpoints**
All services implement standardized health endpoints:

```typescript
@Controller('health')
export class HealthController {
  @Get()
  check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'service-name',
      version: '0.0.1',
    };
  }

  @Get('ready')
  ready() {
    return {
      status: 'ready',
      timestamp: new Date().toISOString(),
      service: 'service-name',
    };
  }

  @Get('live')
  live() {
    return {
      status: 'alive',
      timestamp: new Date().toISOString(),
      service: 'service-name',
    };
  }
}
```

### **5. Environment Validation**
Centralized environment validation using Zod schemas in `@yatms/common`:

```typescript
// apps/common/src/schemas/env.validation.ts
export const ServiceEnvSchema = CommonEnvSchema.extend({
  // Service-specific environment variables
});

export function validateEnvironment<T>(schema: z.ZodSchema<T>, env: Record<string, unknown>): T {
  // Validation logic with proper error handling
}
```

## 🛠️ **Service Management**

### **Service Manager Script**
New standardized service management script: `scripts/service-manager.sh`

**Usage:**
```bash
# Start all services
npm run service:start

# Start specific service
./scripts/service-manager.sh start user-service

# Check health of all services
npm run service:health

# Show status of all services
npm run service:status

# Stop all services
npm run service:stop
```

**Available Commands:**
- `start [service]` - Start a service or all services
- `stop [service]` - Stop a service or all services
- `restart [service]` - Restart a service or all services
- `health [service]` - Check health of a service or all services
- `status` - Show status of all services
- `install` - Install dependencies for all services

## 📊 **Service Ports**

| Service | Port | Health Check |
|---------|------|--------------|
| Gateway | 4000 | `http://localhost:4000/health` |
| User Service | 4001 | `http://localhost:4001/health` |
| Vehicle Service | 4002 | `http://localhost:4002/health` |
| GPS Service | 4003 | `http://localhost:4003/health` |
| Traffic Service | 4004 | `http://localhost:4004/health` |
| Client | 3000 | N/A (Next.js) |

## 🔧 **Development Workflow**

### **1. Starting Services**
```bash
# Start infrastructure (PostgreSQL, Redis, Kafka)
npm run dev:infra

# Start all services
npm run service:start

# Or start individual services
./scripts/service-manager.sh start user-service
```

### **2. Health Monitoring**
```bash
# Check all services health
npm run service:health

# Check specific service
./scripts/service-manager.sh health gateway
```

### **3. Service Management**
```bash
# View all services status
npm run service:status

# Restart a service
npm run service:restart user-service

# Stop all services
npm run service:stop
```

## 📁 **File Structure**

Each service follows this standardized structure:
```
apps/[service-name]/
├── src/
│   ├── app.controller.ts
│   ├── app.module.ts
│   ├── app.service.ts
│   ├── health.controller.ts  # ← Standardized health checks
│   └── main.ts
├── test/
├── Dockerfile               # ← Standardized production
├── Dockerfile.dev          # ← Standardized development
├── package.json            # ← Standardized scripts & metadata
├── tsconfig.json
├── nest-cli.json
└── README.md
```

## 🚀 **Benefits of Standardization**

1. **Consistency** - All services follow the same patterns
2. **Maintainability** - Easy to update configurations across services
3. **Developer Experience** - Familiar commands and structure
4. **Monitoring** - Standardized health checks and logging
5. **Deployment** - Consistent Docker configurations
6. **Testing** - Standardized test scripts and configurations

## 📝 **Next Steps**

1. **Environment Validation** - Implement Zod validation in each service
2. **Logging Standardization** - Add structured logging across services
3. **Metrics Collection** - Implement Prometheus metrics
4. **API Documentation** - Standardize OpenAPI/Swagger documentation
5. **Error Handling** - Implement consistent error handling patterns

## 🔗 **Related Documentation**

- [Architecture Overview](../docs/ARCHITECTURE.md)
- [Development Guide](../docs/LOCAL_DEVELOPMENT_GUIDE.md)
- [API Documentation](../docs/API_DOCUMENTATION.md)
- [Troubleshooting](../docs/TROUBLESHOOTING.md)
