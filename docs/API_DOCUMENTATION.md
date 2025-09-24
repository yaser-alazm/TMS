# TMS API Documentation

## Base URL
- **Development**: `http://localhost:4000`
- **Production**: `http://3.123.1.193:4000`

## Authentication
All API endpoints (except login/register) require a valid JWT token in the Authorization header:
```
Authorization: Bearer <jwt-token>
```

## Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation successful",
  "timestamp": "2025-09-21T16:00:00Z"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": { ... }
  },
  "timestamp": "2025-09-21T16:00:00Z"
}
```

## Authentication Endpoints

### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "user",
      "createdAt": "2025-09-21T16:00:00Z"
    },
    "tokens": {
      "accessToken": "jwt-token",
      "refreshToken": "refresh-token"
    }
  }
}
```

### Login User
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "user"
    },
    "tokens": {
      "accessToken": "jwt-token",
      "refreshToken": "refresh-token"
    }
  }
}
```

### Refresh Token
```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "refresh-token"
}
```

### Get Current User
```http
GET /api/auth/me
Authorization: Bearer <jwt-token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "user",
    "createdAt": "2025-09-21T16:00:00Z"
  }
}
```

## User Management Endpoints

### Get All Users
```http
GET /api/users
Authorization: Bearer <jwt-token>
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)
- `search` (optional): Search term

**Response:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": "uuid",
        "email": "user@example.com",
        "firstName": "John",
        "lastName": "Doe",
        "role": "user",
        "isActive": true,
        "createdAt": "2025-09-21T16:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 1,
      "pages": 1
    }
  }
}
```

### Get User by ID
```http
GET /api/users/{userId}
Authorization: Bearer <jwt-token>
```

### Update User
```http
PUT /api/users/{userId}
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "jane@example.com"
}
```

### Delete User
```http
DELETE /api/users/{userId}
Authorization: Bearer <jwt-token>
```

## Vehicle Management Endpoints

### Create Vehicle
```http
POST /api/vehicles
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "licensePlate": "ABC123",
  "make": "Toyota",
  "model": "Camry",
  "year": 2020,
  "color": "Blue",
  "vin": "1HGBH41JXMN109186"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "licensePlate": "ABC123",
    "make": "Toyota",
    "model": "Camry",
    "year": 2020,
    "color": "Blue",
    "vin": "1HGBH41JXMN109186",
    "ownerId": "user-uuid",
    "status": "active",
    "createdAt": "2025-09-21T16:00:00Z"
  }
}
```

### Get All Vehicles
```http
GET /api/vehicles
Authorization: Bearer <jwt-token>
```

**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Items per page
- `ownerId` (optional): Filter by owner
- `status` (optional): Filter by status

### Get Vehicle by ID
```http
GET /api/vehicles/{vehicleId}
Authorization: Bearer <jwt-token>
```

### Update Vehicle
```http
PUT /api/vehicles/{vehicleId}
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "make": "Honda",
  "model": "Accord",
  "year": 2021,
  "color": "Red"
}
```

### Delete Vehicle
```http
DELETE /api/vehicles/{vehicleId}
Authorization: Bearer <jwt-token>
```

### Get Vehicles by Owner
```http
GET /api/vehicles/owner/{ownerId}
Authorization: Bearer <jwt-token>
```

## GPS Tracking Endpoints

### Record GPS Location
```http
POST /api/gps/locations
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "vehicleId": "uuid",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "altitude": 10.5,
  "speed": 65.5,
  "heading": 180.0,
  "accuracy": 5.0
}
```

### Get Current Location
```http
GET /api/gps/locations/{vehicleId}/current
Authorization: Bearer <jwt-token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "vehicleId": "uuid",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "altitude": 10.5,
    "speed": 65.5,
    "heading": 180.0,
    "accuracy": 5.0,
    "timestamp": "2025-09-21T16:00:00Z"
  }
}
```

### Get Location History
```http
GET /api/gps/locations/{vehicleId}/history
Authorization: Bearer <jwt-token>
```

**Query Parameters:**
- `startDate` (optional): Start date (ISO 8601)
- `endDate` (optional): End date (ISO 8601)
- `limit` (optional): Number of records (default: 100)

### Start Real-time Tracking
```http
GET /api/gps/track/{vehicleId}
Authorization: Bearer <jwt-token>
```

**Response:** Server-Sent Events stream

## Traffic Information Endpoints

### Get Traffic Conditions
```http
GET /api/traffic/conditions
Authorization: Bearer <jwt-token>
```

**Query Parameters:**
- `latitude` (required): Latitude coordinate
- `longitude` (required): Longitude coordinate
- `radius` (optional): Search radius in meters (default: 1000)

**Response:**
```json
{
  "success": true,
  "data": {
    "conditions": [
      {
        "id": "uuid",
        "location": {
          "latitude": 40.7128,
          "longitude": -74.0060
        },
        "condition": "heavy",
        "severity": "medium",
        "description": "Heavy traffic on Main Street",
        "timestamp": "2025-09-21T16:00:00Z"
      }
    ]
  }
}
```

### Optimize Route
```http
POST /api/traffic/routes/optimize
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "origin": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "destination": {
    "latitude": 40.7589,
    "longitude": -73.9851
  },
  "preferences": {
    "avoidTolls": false,
    "avoidHighways": false,
    "preferTraffic": true
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "route": {
      "distance": 15.5,
      "duration": 1800,
      "durationInTraffic": 2100,
      "steps": [
        {
          "instruction": "Head north on Main Street",
          "distance": 500,
          "duration": 120
        }
      ]
    }
  }
}
```

### Get Traffic Alerts
```http
GET /api/traffic/alerts
Authorization: Bearer <jwt-token>
```

**Query Parameters:**
- `severity` (optional): Filter by severity level
- `active` (optional): Filter active alerts only

## Health Check Endpoints

### Gateway Health
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-09-21T16:00:00Z",
  "services": {
    "user-service": "healthy",
    "vehicle-service": "healthy",
    "gps-service": "healthy",
    "traffic-service": "healthy"
  }
}
```

### Service Health Checks
```http
GET /api/users/health
GET /api/vehicles/health
GET /api/gps/health
GET /api/traffic/health
```

## Error Codes

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Invalid input data |
| `AUTHENTICATION_ERROR` | Invalid or missing authentication |
| `AUTHORIZATION_ERROR` | Insufficient permissions |
| `NOT_FOUND` | Resource not found |
| `CONFLICT` | Resource already exists |
| `INTERNAL_ERROR` | Server internal error |
| `SERVICE_UNAVAILABLE` | External service unavailable |

## Rate Limiting

- **Authentication endpoints**: 5 requests per minute per IP
- **API endpoints**: 100 requests per minute per user
- **GPS tracking**: 1000 requests per minute per vehicle

## WebSocket Endpoints

### Real-time Vehicle Tracking
```javascript
const ws = new WebSocket('ws://localhost:4000/ws/track/{vehicleId}');

ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('Location update:', data);
};
```

### Traffic Updates
```javascript
const ws = new WebSocket('ws://localhost:4000/ws/traffic');

ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('Traffic update:', data);
};
```

## SDK Examples

### JavaScript/Node.js
```javascript
const axios = require('axios');

const api = axios.create({
  baseURL: 'http://localhost:4000',
  headers: {
    'Content-Type': 'application/json'
  }
});

// Add auth token
api.interceptors.request.use(config => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Usage
const response = await api.post('/api/vehicles', {
  licensePlate: 'ABC123',
  make: 'Toyota',
  model: 'Camry'
});
```

### Python
```python
import requests

class TMSClient:
    def __init__(self, base_url, token=None):
        self.base_url = base_url
        self.session = requests.Session()
        if token:
            self.session.headers.update({
                'Authorization': f'Bearer {token}'
            })
    
    def create_vehicle(self, vehicle_data):
        response = self.session.post(
            f'{self.base_url}/api/vehicles',
            json=vehicle_data
        )
        return response.json()

# Usage
client = TMSClient('http://localhost:4000', 'your-jwt-token')
vehicle = client.create_vehicle({
    'licensePlate': 'ABC123',
    'make': 'Toyota',
    'model': 'Camry'
})
```

## Testing

### Postman Collection
Import the Postman collection from `docs/postman/TMS-API.postman_collection.json`

### cURL Examples
```bash
# Register user
curl -X POST http://localhost:4000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","firstName":"Test","lastName":"User"}'

# Login
curl -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Create vehicle
curl -X POST http://localhost:4000/api/vehicles \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"licensePlate":"ABC123","make":"Toyota","model":"Camry","year":2020,"color":"Blue"}'
```

This API documentation provides comprehensive information for integrating with the Transportation Management System.
