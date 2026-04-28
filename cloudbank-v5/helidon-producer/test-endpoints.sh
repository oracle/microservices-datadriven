#!/bin/bash
# Simple test script for helidon-producer

NAMESPACE=${1:-obaas}
GATEWAY_URL=${2:-localhost:8080}

echo "Testing helidon-producer in namespace: $NAMESPACE"

# Test POST /post
echo "Sending message to /post..."
curl -X POST -H "Content-Type: text/plain" -d "Hello from Helidon Producer at $(date)" "http://$GATEWAY_URL/post"
echo -e "\n"

echo "Check logs to verify Kafka delivery:"
echo "kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=helidon-producer"
