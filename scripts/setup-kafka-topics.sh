#!/bin/bash

# Setup Kafka topics for vehicle data requests/responses

echo "Setting up Kafka topics..."

# Create vehicle-requests topic
docker exec tms-kafka-dev kafka-topics --bootstrap-server localhost:9092 \
  --create --topic vehicle-requests \
  --partitions 3 \
  --replication-factor 1 \
  --if-not-exists

# Create vehicle-responses topic  
docker exec tms-kafka-dev kafka-topics --bootstrap-server localhost:9092 \
  --create --topic vehicle-responses \
  --partitions 3 \
  --replication-factor 1 \
  --if-not-exists

echo "Kafka topics created successfully!"
echo "Available topics:"
docker exec tms-kafka-dev kafka-topics --bootstrap-server localhost:9092 --list