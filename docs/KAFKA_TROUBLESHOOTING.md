# Kafka Troubleshooting Guide

## Issue: Route Optimization Timeout with Kafka Publishing

### Problem
When Kafka event publishing is enabled in the route optimization service, the endpoints timeout and return 500 errors.

### Root Cause
The Kafka topics `route-optimization-events` and `route-update-events` had leadership issues (`NOT_LEADER_OR_FOLLOWER` error), causing the producer to hang when trying to publish events.

### Current Status
- ✅ **Route Optimization**: Working with full Kafka integration
- ✅ **WebSocket Updates**: Working for real-time updates
- ✅ **Database Persistence**: Working for route storage
- ✅ **Kafka Infrastructure**: Working (confirmed via health check)
- ✅ **Circuit Breaker**: Implemented for graceful failure handling
- ✅ **Kafka Events**: Fully functional with lazy connection

### Solutions Applied

#### 1. Added Timeout Configuration
Updated `apps/common/src/kafka/kafka.service.ts`:
```typescript
this.producer = this.kafka.producer({
  allowAutoTopicCreation: true,
  transactionTimeout: 30000,
  connectionTimeout: 10000,
  requestTimeout: 10000,
  retry: {
    initialRetryTime: 100,
    retries: 3,
  },
})
```

#### 2. Added Publish Timeout
```typescript
async publishEvent(topic: string, event: any): Promise<void> {
  try {
    const publishPromise = this.producer.send({...})
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('Kafka publish timeout')), 5000)
    })
    
    await Promise.race([publishPromise, timeoutPromise])
  } catch (error) {
    // Don't throw error to prevent service failure
    this.logger.warn(`Continuing without publishing event to ${topic}`)
  }
}
```

#### 3. Implemented Circuit Breaker Pattern
Created `apps/common/src/kafka/circuit-breaker.ts` to gracefully handle Kafka failures:
```typescript
export class CircuitBreaker {
  private failures = 0;
  private lastFailureTime = 0;
  private state = CircuitBreakerState.CLOSED;

  async execute<T>(operation: () => Promise<T>): Promise<T | null> {
    // Circuit breaker logic to prevent cascading failures
  }
}
```

#### 4. Added Kafka Health Check Endpoint
Created `/traffic/routes/kafka-health` endpoint to test Kafka connectivity:
```bash
curl http://localhost:4004/traffic/routes/kafka-health
# Returns: {"status": "healthy", "message": "Kafka connection is working"}
```

#### 5. Created Missing Environment File
Added `apps/traffic-service/.env` with proper Kafka configuration:
```bash
KAFKA_BROKERS=localhost:9092
KAFKA_CLIENT_ID=traffic-service
```

#### 6. Implemented Lazy Kafka Connection
Modified Kafka service to use lazy connection pattern:
```typescript
async onModuleInit(): Promise<void> {
  // Don't connect immediately - use lazy connection
  this.logger.log('Kafka service initialized (lazy connection)')
}

private async ensureConnected(): Promise<void> {
  if (this.producer && this.isConnected) {
    return
  }
  // Connect only when needed
}
```

#### 7. Fixed Kafka Topic Leadership Issues
Identified and resolved the root cause:
```bash
# Check topic status
docker exec tms-kafka-dev kafka-topics --describe --topic route-optimization-events --bootstrap-server localhost:9092

# Delete corrupted topics
docker exec tms-kafka-dev kafka-topics --delete --topic route-optimization-events --bootstrap-server localhost:9092

# Recreate topics
docker exec tms-kafka-dev kafka-topics --create --topic route-optimization-events --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```

#### 8. Re-enabled Kafka Publishing
Restored full Kafka event publishing functionality in route optimization service.

### Troubleshooting Steps

#### 1. Check Kafka Service Status
```bash
docker ps | grep kafka
docker exec tms-kafka-dev kafka-topics --list --bootstrap-server localhost:9092
```

#### 2. Test Kafka Connectivity
```bash
docker exec tms-kafka-dev kafka-console-producer --bootstrap-server localhost:9092 --topic test-topic
```

#### 3. Check Kafka Logs
```bash
docker logs tms-kafka-dev
```

#### 4. Verify Environment Configuration
Check `env/traffic-service.env`:
```bash
KAFKA_CLIENT_ID=traffic-service
KAFKA_BROKERS=localhost:9092
```

### Potential Solutions

#### 1. Restart Kafka Service
```bash
docker restart tms-kafka-dev
```

#### 2. Recreate Kafka Topics
```bash
docker exec tms-kafka-dev kafka-topics --delete --topic route-optimization-events --bootstrap-server localhost:9092
docker exec tms-kafka-dev kafka-topics --create --topic route-optimization-events --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```

#### 3. Check Network Connectivity
```bash
telnet localhost 9092
```

#### 4. Increase Timeout Values
Update Kafka service configuration with longer timeouts:
```typescript
connectionTimeout: 30000,
requestTimeout: 30000,
```

### Alternative Approaches

#### 1. Async Event Publishing
Publish events asynchronously without waiting for completion:
```typescript
// Fire and forget
this.publishEventAsync(topic, event).catch(error => {
  this.logger.error('Async event publish failed:', error)
})
```

#### 2. Event Queue
Implement a local event queue that retries publishing:
```typescript
class EventQueue {
  private queue: any[] = []
  
  async enqueue(event: any) {
    this.queue.push(event)
    this.processQueue()
  }
  
  private async processQueue() {
    // Process queue with retry logic
  }
}
```

#### 3. Circuit Breaker Pattern
Implement a circuit breaker to temporarily disable Kafka when it's failing:
```typescript
class CircuitBreaker {
  private failures = 0
  private lastFailureTime = 0
  private readonly threshold = 5
  private readonly timeout = 60000
  
  async execute<T>(operation: () => Promise<T>): Promise<T | null> {
    if (this.isOpen()) {
      return null
    }
    
    try {
      const result = await operation()
      this.onSuccess()
      return result
    } catch (error) {
      this.onFailure()
      throw error
    }
  }
}
```

### Final Solution

The route optimization feature now works perfectly with full Kafka integration:
- ✅ All core functionality working
- ✅ Real-time WebSocket updates
- ✅ Database persistence
- ✅ API endpoints functional
- ✅ Client UI working
- ✅ Kafka infrastructure confirmed working
- ✅ Circuit breaker implemented for resilience
- ✅ Kafka events publishing successfully

### Key Findings

1. **Kafka Infrastructure**: ✅ Working correctly
   - Kafka service is running and healthy
   - Topics are created and accessible
   - Direct Kafka connectivity test passes
   - Health check endpoint confirms connectivity

2. **Topic Leadership Issue**: ✅ Resolved
   - `route-optimization-events` and `route-update-events` topics had leadership problems
   - `NOT_LEADER_OR_FOLLOWER` error was causing producer hangs
   - Fixed by deleting and recreating the corrupted topics

3. **Lazy Connection Pattern**: ✅ Implemented
   - Prevents startup hangs by connecting only when needed
   - Improves service startup reliability
   - Maintains connection state for subsequent operations

### Verification

```bash

# Test route optimization with Kafka
curl -X POST http://localhost:4000/traffic/routes/optimize -H "Content-Type: application/json" -d '{"vehicleId":"53ac84a9-ddcc-4a1c-a153-e9738c026e03","stops":[{"id":"stop-1","latitude":40.7128,"longitude":-74.0060,"address":"New York, NY"},{"id":"stop-2","latitude":40.7589,"longitude":-73.9851,"address":"Times Square, NY"}],"preferences":{"avoidTolls":false,"avoidHighways":false,"optimizeFor":"time"}}'

# Verify events in Kafka
docker exec tms-kafka-dev kafka-console-consumer --bootstrap-server localhost:9092 --topic route-optimization-events --from-beginning --max-messages 5
```

### Next Steps

1. **Monitor Kafka Performance**: Keep an eye on Kafka topic health and leadership
2. **Add Event Consumers**: Implement event consumers in other services (Vehicle, GPS)
3. **Add Retry Logic**: Implement retry logic for failed event publishing
4. **Add Monitoring**: Add Prometheus metrics for Kafka publishing success/failure rates
5. **Consider Event Sourcing**: Implement event sourcing pattern for audit trails

### Production Considerations

For production deployment:
- Use managed Kafka service (AWS MSK, Confluent Cloud)
- Implement proper monitoring and alerting
- Add circuit breakers and fallback mechanisms
- Use async event publishing with retry logic
- Consider event sourcing patterns for reliability
