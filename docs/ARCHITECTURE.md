# TMS Service Architecture & Data Flow

## System Architecture Overview

The Transportation Management System follows a microservices architecture pattern with the following key components:

### 1. Client Layer
- **Web Application**: React/Next.js frontend
- **Mobile Application**: React Native mobile app
- **API Clients**: Third-party integrations

### 2. API Gateway Layer
- **Gateway Service**: Single entry point for all client requests
- **Authentication**: JWT-based authentication and authorization
- **Rate Limiting**: Request throttling and validation
- **Load Balancing**: Distributes requests to appropriate services

### 3. Microservices Layer

#### User Service (Port 4001)
**Responsibilities**:
- User registration and authentication
- Profile management
- Role-based access control
- JWT token management

**Data Model**:
```
User {
  id: UUID
  email: string (unique)
  passwordHash: string
  firstName: string
  lastName: string
  role: enum [user, admin, driver]
  isActive: boolean
  createdAt: timestamp
  updatedAt: timestamp
}
```

**Key Operations**:
- `POST /auth/register` - User registration
- `POST /auth/login` - User authentication
- `GET /users/:id` - Get user profile
- `PUT /users/:id` - Update user profile
- `GET /.well-known/jwks.json` - JWT public keys

#### Vehicle Service (Port 4002)
**Responsibilities**:
- Vehicle registration and management
- Vehicle-owner relationships
- Vehicle status tracking
- Maintenance records

**Data Model**:
```
Vehicle {
  id: UUID
  licensePlate: string (unique)
  make: string
  model: string
  year: number
  color: string
  ownerId: UUID (FK to User)
  status: enum [active, inactive, maintenance]
  vin: string
  createdAt: timestamp
  updatedAt: timestamp
}
```

**Key Operations**:
- `POST /vehicles` - Register new vehicle
- `GET /vehicles` - List vehicles
- `GET /vehicles/:id` - Get vehicle details
- `PUT /vehicles/:id` - Update vehicle
- `GET /vehicles/owner/:ownerId` - Get vehicles by owner

#### GPS Service (Port 4003)
**Responsibilities**:
- Real-time location tracking
- Historical location data
- Geofencing capabilities
- Location analytics

**Data Model**:
```
GPSLocation {
  id: UUID
  vehicleId: UUID (FK to Vehicle)
  latitude: decimal(10,8)
  longitude: decimal(11,8)
  altitude: decimal(8,2)
  speed: decimal(5,2)
  heading: decimal(5,2)
  accuracy: decimal(5,2)
  timestamp: timestamp
  createdAt: timestamp
}
```

**Key Operations**:
- `POST /gps/locations` - Record GPS location
- `GET /gps/locations/:vehicleId` - Get current location
- `GET /gps/locations/:vehicleId/history` - Get location history
- `GET /gps/vehicles/:vehicleId/track` - Real-time tracking

#### Traffic Service (Port 4004)
**Responsibilities**:
- Traffic condition monitoring
- Route optimization
- Traffic pattern analysis
- External API integration

**Data Model**:
```
TrafficCondition {
  id: UUID
  location: point
  condition: enum [clear, slow, heavy, blocked]
  severity: enum [low, medium, high, critical]
  description: string
  timestamp: timestamp
  source: string
}
```

**Key Operations**:
- `GET /traffic/conditions` - Get current traffic conditions
- `POST /traffic/routes/optimize` - Optimize route
- `GET /traffic/alerts` - Get traffic alerts
- `GET /traffic/patterns` - Get traffic patterns

### 4. Data Layer

#### PostgreSQL Databases (RDS)
- **User DB**: User profiles, authentication data
- **Vehicle DB**: Vehicle information, ownership
- **GPS DB**: Location data, tracking history

#### Redis Cache (ElastiCache)
- **Session Storage**: User sessions and tokens
- **Application Cache**: Frequently accessed data
- **Rate Limiting**: Request throttling data

#### S3 Storage
- **Document Storage**: Vehicle documents, user files
- **Static Assets**: Images, reports, exports

### 5. External Integrations
- **Google Maps API**: Maps, geocoding, directions
- **Traffic APIs**: Real-time traffic data
- **Weather APIs**: Weather conditions for routes

## Data Flow Diagrams

### User Registration Flow
```
Client → Gateway → User Service → User DB
                ↓
            Redis Cache (Session)
                ↓
            JWT Token Generation
                ↓
            Response to Client
```

### Vehicle Tracking Flow
```
GPS Device → GPS Service → GPS DB
                ↓
            Event Publishing (Kafka)
                ↓
            Vehicle Service (Update Status)
                ↓
            Real-time Updates to Client
```

### Authentication Flow
```
Client → Gateway → User Service → User DB
                ↓
            JWT Validation
                ↓
            JWKS Endpoint
                ↓
            Authorized Request to Service
```

## Service Communication Patterns

### 1. Synchronous Communication (REST)
- **Gateway ↔ Services**: HTTP/REST API calls
- **Service ↔ Service**: Direct HTTP calls for immediate data
- **Client ↔ Gateway**: HTTPS requests

### 2. Asynchronous Communication (Kafka)
- **Event Publishing**: Domain events between services
- **Event Consumption**: Service-specific event handlers
- **Event Sourcing**: Audit trail and state reconstruction

### 3. Database Patterns
- **Database per Service**: Each service owns its data
- **API Composition**: Gateway composes data from multiple services
- **Eventual Consistency**: Data consistency through events

## Security Architecture

### Authentication & Authorization
```
Client Request → Gateway → JWT Validation → Service Authorization
```

### Security Layers
1. **Network Security**: VPC, Security Groups, NACLs
2. **Application Security**: JWT tokens, input validation
3. **Data Security**: Encryption at rest and in transit
4. **Infrastructure Security**: IAM roles, least privilege access

### JWT Token Structure
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "user-id",
    "email": "user@example.com",
    "role": "user",
    "iat": 1640995200,
    "exp": 1641081600
  }
}
```

## Deployment Architecture

### AWS Infrastructure
```
Internet → Application Load Balancer → EC2 Instance
                                    ↓
                              Docker Containers
                                    ↓
                              RDS PostgreSQL
                                    ↓
                              ElastiCache Redis
                                    ↓
                              S3 Storage
```

### Container Orchestration
```yaml
# docker-compose.aws.yml structure
services:
  gateway:
    image: ECR/gateway:latest
    ports: ["4000:4000"]
    environment:
      - USER_SERVICE_URL=http://user-service:4001
      - VEHICLE_SERVICE_URL=http://vehicle-service:4002
  
  user-service:
    image: ECR/user-service:latest
    ports: ["4001:4001"]
    environment:
      - DATABASE_URL=postgresql://...
      - REDIS_URL=redis://...
  
  vehicle-service:
    image: ECR/vehicle-service:latest
    ports: ["4002:4002"]
    environment:
      - DATABASE_URL=postgresql://...
      - REDIS_URL=redis://...
```

## Monitoring & Observability

### Health Checks
- **Service Health**: `/health` endpoint for each service
- **Database Health**: Connection and query performance
- **External Dependencies**: API availability checks

### Logging Strategy
- **Structured Logging**: JSON format for all services
- **Log Aggregation**: Centralized logging system
- **Log Levels**: DEBUG, INFO, WARN, ERROR

### Metrics Collection
- **Application Metrics**: Request count, response time, error rate
- **Infrastructure Metrics**: CPU, memory, disk usage
- **Business Metrics**: User registrations, vehicle tracking events

## Scalability Considerations

### Horizontal Scaling
- **Stateless Services**: All services are stateless
- **Load Balancing**: Multiple instances behind load balancer
- **Database Scaling**: Read replicas for read-heavy workloads

### Vertical Scaling
- **Instance Types**: Upgrade EC2 instance types as needed
- **Database Scaling**: Upgrade RDS instance classes
- **Cache Scaling**: Increase ElastiCache node size

### Performance Optimization
- **Caching Strategy**: Redis for frequently accessed data
- **Database Optimization**: Proper indexing and query optimization
- **CDN Integration**: CloudFront for static assets

## Disaster Recovery

### Backup Strategy
- **Database Backups**: Automated RDS snapshots
- **Application Backups**: ECR image versioning
- **Configuration Backups**: Infrastructure as Code

### Recovery Procedures
- **RTO (Recovery Time Objective)**: 4 hours
- **RPO (Recovery Point Objective)**: 1 hour
- **Failover Process**: Automated failover to standby region

This architecture provides a robust, scalable, and maintainable foundation for the Transportation Management System while staying within AWS Free Tier limits.
