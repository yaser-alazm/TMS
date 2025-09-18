# Authentication System Documentation

## Overview

The Transportation Management System (TMS) implements a robust JWT-based authentication system using RS256 asymmetric encryption with JWKS (JSON Web Key Set) for secure token verification. The system follows a microservices architecture with separate authentication concerns handled by different services.

## Architecture Overview

```mermaid
graph TB
    Client[Next.js Client] --> Gateway[API Gateway]
    Gateway --> UserService[User Service]
    Gateway --> VehicleService[Vehicle Service]
    Gateway --> GPSService[GPS Service]
    Gateway --> TrafficService[Traffic Service]
    
    UserService --> Database[(PostgreSQL)]
    
    subgraph "Authentication Flow"
        Client --> |1. Login Request| Gateway
        Gateway --> |2. Forward to User Service| UserService
        UserService --> |3. Generate JWT| UserService
        UserService --> |4. Return Tokens| Gateway
        Gateway --> |5. Set HTTP-Only Cookies| Client
        Client --> |6. Subsequent Requests| Gateway
        Gateway --> |7. Verify JWT with JWKS| UserService
    end
```

## Components

### 1. User Service (`apps/user-service/`)
**Role**: Authentication authority, JWT token generation, user management

#### Key Features:
- **JWT Token Generation**: Creates RS256-signed JWT tokens
- **JWKS Endpoint**: Exposes public keys for token verification
- **User Management**: Handles user registration, login, profile management
- **Refresh Token Management**: Manages long-lived refresh tokens
- **Database**: PostgreSQL with Prisma ORM

#### Environment Variables:
```bash
# JWT Configuration
JWT_PRIVATE_KEY_PEM="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
JWT_PUBLIC_KEY_PEM="-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
JWT_KID="primary-2025-09"  # Key ID for JWKS
JWT_ISSUER="yatms-user-service"

# Database
DATABASE_URL="postgresql://user:password@localhost:5432/tms"

# Service Configuration
PORT=4001
NODE_ENV=development
```

#### Database Schema:
```sql
-- Core authentication tables
User {
  id: String (UUID, Primary Key)
  username: String (Unique)
  email: String (Unique)
  password: String (Hashed)
  firstName: String?
  lastName: String?
  isActive: Boolean
  lastLogin: DateTime?
  createdAt: DateTime
  updatedAt: DateTime
}

Role {
  id: String (UUID, Primary Key)
  name: String (Unique)
  description: String?
  createdAt: DateTime
  updatedAt: DateTime
}

Permission {
  id: String (UUID, Primary Key)
  name: String (Unique)
  description: String?
  createdAt: DateTime
  updatedAt: DateTime
}

RefreshToken {
  id: String (UUID, Primary Key)
  token: String (Unique)
  userId: String (Foreign Key)
  expiresAt: DateTime
  createdAt: DateTime
}
```

#### JWT Token Structure:
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "primary-2025-09"
  },
  "payload": {
    "userId": "uuid",
    "email": "user@example.com",
    "roles": ["admin", "user"],
    "iat": 1640995200,
    "exp": 1640998800,
    "iss": "yatms-user-service"
  }
}
```

### 2. API Gateway (`apps/gateway/`)
**Role**: Authentication middleware, request routing, cookie management

#### Key Features:
- **JWT Verification**: Verifies tokens using JWKS from User Service
- **Cookie Management**: Sets and manages HTTP-only cookies
- **Request Routing**: Routes authenticated requests to appropriate services
- **Middleware**: AuthMiddleware for protecting routes

#### Environment Variables:
```bash
# Service URLs
USER_SERVICE_URL="http://user-srv:4001"
VEHICLE_SERVICE_URL="http://vehicle-srv:4002"
GPS_SERVICE_URL="http://gps-srv:4003"
TRAFFIC_SERVICE_URL="http://traffic-srv:4004"

# JWT Verification
AUTH_JWKS_URI="http://user-srv:4001/.well-known/jwks.json"
AUTH_ISSUER="yatms-user-service"

# Service Configuration
PORT=4000
NODE_ENV=development
```

#### Protected Routes:
```typescript
// Whitelisted paths (no authentication required)
const whitelistedPaths = [
  'api/auth/login',
  'api/auth/register', 
  'api/auth/refresh',
  'api/auth/logout'
]
```

#### Cookie Configuration:
```typescript
// Access Token Cookie
{
  name: 'auth_token',
  httpOnly: true,
  secure: false,        // true in production
  sameSite: 'lax',
  maxAge: 3600000,     // 1 hour
  path: '/'
}

// Refresh Token Cookie
{
  name: 'refresh_token',
  httpOnly: true,
  secure: false,        // true in production
  sameSite: 'lax',
  maxAge: 1209600000,   // 14 days
  path: '/'
}
```

### 3. Client Application (`apps/client/`)
**Role**: User interface, authentication state management, API communication

#### Key Features:
- **React Context**: AuthContext for global authentication state
- **React Query**: Server state management and caching
- **Protected Routes**: Route protection based on authentication
- **Cookie Handling**: Automatic cookie inclusion in requests

#### Authentication State Management:
```typescript
interface AuthContextType {
  user: UserContextClient | null
  loading: boolean
  isFetched: boolean
  error: Error | null
  refetch: () => void
  setUser: (user: UserContextClient | null) => void
  setLoading: (loading: boolean) => void
  setError: (error: Error | null) => void
  handleLogin: (userData: UserContextClient) => void
}
```

#### React Query Configuration:
```typescript
const queryConfig = {
  queryKey: ['auth', 'me'],
  queryFn: getUserProfile,
  staleTime: 0,
  refetchOnMount: 'always',
  refetchOnWindowFocus: false,
  refetchOnReconnect: 'always',
  retry: false,
  refetchInterval: false,
  notifyOnChangeProps: ['data', 'error', 'isLoading', 'isFetching']
}
```

## Authentication Flow

### 1. Login Process

```mermaid
sequenceDiagram
    participant C as Client
    participant G as Gateway
    participant U as User Service
    participant D as Database

    C->>G: POST /api/auth/login
    G->>U: POST /auth/login
    U->>D: Validate credentials
    D-->>U: User data
    U->>U: Generate JWT + Refresh Token
    U-->>G: { user, accessToken, refreshToken }
    G->>G: Set HTTP-only cookies
    G-->>C: { user }
    C->>C: Update AuthContext state
    C->>C: Redirect to dashboard
```

**Step-by-step Login Flow:**

1. **Client Login Request**:
   ```typescript
   const response = await fetch('/api/auth/login', {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({ username, password }),
     credentials: 'include'
   })
   ```

2. **Gateway Processing**:
   - Forwards request to User Service
   - Receives tokens in response
   - Sets HTTP-only cookies for both tokens

3. **User Service Processing**:
   - Validates credentials against database
   - Generates RS256-signed JWT with user claims
   - Creates refresh token and stores in database
   - Returns user data and tokens

4. **Client State Update**:
   ```typescript
   // Direct AuthContext update (bypasses React Query timing issues)
   handleLogin(userData)
   
   // Also update React Query cache for consistency
   queryClient.setQueryData(['auth', 'me'], userData)
   ```

### 2. Authenticated Request Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant G as Gateway
    participant U as User Service
    participant S as Service

    C->>G: GET /api/users/me (with cookies)
    G->>G: Extract JWT from cookie
    G->>U: GET /.well-known/jwks.json
    U-->>G: JWKS
    G->>G: Verify JWT signature
    G->>G: Extract user claims
    G->>S: Forward request with user headers
    S-->>G: Response
    G-->>C: Response
```

**Step-by-step Authenticated Request:**

1. **Client Request**:
   ```typescript
   const response = await fetchWithAuth('/api/users/me')
   ```

2. **Gateway Middleware**:
   ```typescript
   // Extract token from cookie
   const token = req.cookies?.auth_token
   
   // Verify JWT with JWKS
   const { payload } = await jwtVerify(token, jwks, {
     algorithms: ['RS256'],
     issuer: 'yatms-user-service'
   })
   
   // Add user context to request headers
   req.headers['x-auth-user-id'] = payload.userId
   req.headers['x-auth-user-email'] = payload.email
   req.headers['x-auth-user-roles'] = JSON.stringify(payload.roles)
   ```

3. **Service Processing**:
   - Receives request with user context headers
   - Processes business logic
   - Returns response

### 3. Token Refresh Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant G as Gateway
    participant U as User Service
    participant D as Database

    C->>G: POST /api/auth/refresh (with refresh cookie)
    G->>U: POST /auth/refresh
    U->>D: Validate refresh token
    D-->>U: Valid token
    U->>U: Generate new JWT + Refresh Token
    U->>D: Store new refresh token
    U-->>G: { accessToken, refreshToken }
    G->>G: Update cookies
    G-->>C: Success
```

**Automatic Token Refresh:**
- Client automatically refreshes tokens every 30 minutes
- Uses refresh token stored in HTTP-only cookie
- Updates both access and refresh tokens
- Handles refresh failures by clearing authentication state

### 4. Logout Process

```mermaid
sequenceDiagram
    participant C as Client
    participant G as Gateway
    participant U as User Service
    participant D as Database

    C->>G: POST /api/auth/logout
    G->>U: POST /auth/logout
    U->>D: Delete refresh tokens
    U-->>G: Success
    G->>G: Clear cookies
    G-->>C: Success
    C->>C: Clear AuthContext state
    C->>C: Redirect to login
```

## Security Features

### 1. JWT Security
- **Algorithm**: RS256 (RSA with SHA-256)
- **Key Management**: JWKS endpoint for public key distribution
- **Token Expiration**: Access tokens expire in 1 hour
- **Refresh Tokens**: Long-lived (14 days) with database storage

### 2. Cookie Security
- **HTTP-Only**: Prevents XSS attacks
- **SameSite**: Lax policy for CSRF protection
- **Secure**: HTTPS-only in production
- **Path**: Restricted to application root

### 3. CORS Configuration
```typescript
// Gateway CORS settings
{
  origin: process.env.CLIENT_URL || 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-auth-user-id', 'x-auth-user-email', 'x-auth-user-roles']
}
```

### 4. Rate Limiting
- Login attempts: 5 per minute per IP
- API requests: 100 per minute per user
- Refresh token attempts: 10 per hour per user

## Error Handling

### 1. Authentication Errors
```typescript
// Common error responses
{
  "message": "Authentication failed",
  "error": "Invalid token" | "Token expired" | "Missing token"
}

// Client error handling
if (response.status === 401) {
  const refreshed = await refreshAccessToken()
  if (!refreshed) {
    // Redirect to login
    router.replace('/login')
  }
}
```

### 2. Token Refresh Errors
```typescript
// Refresh token failure
if (!refreshSuccess) {
  // Clear all authentication state
  setUser(null)
  setError(new Error('Session expired'))
  queryClient.clear()
  router.replace('/login')
}
```

## Development Setup

### 1. Generate RSA Keys
```bash
# Generate private key
openssl genrsa -out private.pem 2048

# Generate public key
openssl rsa -in private.pem -pubout -out public.pem

# Convert to single-line format for environment variables
cat private.pem | tr '\n' '\\n'
cat public.pem | tr '\n' '\\n'
```

### 2. Environment Configuration
```bash
# User Service (.env)
JWT_PRIVATE_KEY_PEM="-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----"
JWT_PUBLIC_KEY_PEM="-----BEGIN PUBLIC KEY-----\\n...\\n-----END PUBLIC KEY-----"
JWT_KID="primary-2025-09"
JWT_ISSUER="yatms-user-service"
DATABASE_URL="postgresql://user:password@localhost:5432/tms"

# Gateway (.env)
USER_SERVICE_URL="http://localhost:4001"
AUTH_JWKS_URI="http://localhost:4001/.well-known/jwks.json"
AUTH_ISSUER="yatms-user-service"

# Client (.env.local)
NEXT_PUBLIC_API_URL="http://localhost:4000"
```

### 3. Database Setup
```bash
# Run migrations
cd apps/user-service
npx prisma migrate dev

# Seed database
npx prisma db seed
```

## Production Considerations

### 1. Security Hardening
- Enable HTTPS for all services
- Set `secure: true` for cookies
- Implement proper CORS policies
- Use environment-specific JWKS URIs
- Implement proper logging and monitoring

### 2. Performance Optimization
- Implement Redis for session storage
- Use CDN for JWKS endpoint
- Implement token caching strategies
- Monitor token refresh patterns

### 3. Monitoring and Alerting
- Track authentication success/failure rates
- Monitor token refresh patterns
- Alert on suspicious login attempts
- Log all authentication events

## Troubleshooting

### Common Issues

1. **"Authentication failed" errors**:
   - Check JWT key configuration
   - Verify JWKS endpoint accessibility
   - Check token expiration times

2. **Cookie not being sent**:
   - Verify `credentials: 'include'` in requests
   - Check cookie domain/path settings
   - Ensure HTTPS in production

3. **Token refresh failures**:
   - Check refresh token database storage
   - Verify refresh token expiration
   - Check network connectivity to User Service

4. **CORS errors**:
   - Verify CORS configuration in Gateway
   - Check client URL configuration
   - Ensure credentials are included in CORS

### Debug Tools
- JWT.io for token inspection
- Browser DevTools for cookie inspection
- Network tab for request/response analysis
- Server logs for authentication events

## API Reference

### Authentication Endpoints

#### POST /api/auth/login
```typescript
// Request
{
  username: string
  password: string
}

// Response
{
  user: {
    userId: string
    email: string
    roles: string[]
  }
  accessToken: string  // Set as HTTP-only cookie
  refreshToken: string  // Set as HTTP-only cookie
}
```

#### POST /api/auth/refresh
```typescript
// Request (refresh token sent via cookie)
// Response
{
  accessToken: string  // Set as HTTP-only cookie
  refreshToken: string  // Set as HTTP-only cookie
}
```

#### POST /api/auth/logout
```typescript
// Request (tokens sent via cookies)
// Response
{
  message: "Logged out successfully"
}
```

#### GET /.well-known/jwks.json
```typescript
// Response
{
  keys: [
    {
      kty: "RSA",
      kid: "primary-2025-09",
      use: "sig",
      alg: "RS256",
      n: "...",
      e: "AQAB"
    }
  ]
}
```

This documentation provides a comprehensive overview of the authentication system, covering all aspects from architecture to implementation details and troubleshooting.
