#!/bin/bash
# Simple test script for helidon-producer

NAMESPACE=${1:-obaas}
GATEWAY_URL=${2:-localhost:8080}

echo "Testing helidon-producer in namespace: $NAMESPACE"

# Test POST /post
echo "Fetching service client secret..."
# Retrieve the service-client secret from the new azn-server secret structure
CLIENT_SECRET=$(kubectl get secret otelopupgrd-azn-server-auth -n $NAMESPACE -o jsonpath='{.data.service-client-secret}' | base64 -d)

echo "Port-forwarding azn-server to get auth token..."
kubectl port-forward svc/azn-server 8081:8080 -n $NAMESPACE > /dev/null 2>&1 &
PF_PID=$!
sleep 3

echo "Fetching OAuth2 Bearer Token..."
TOKEN=$(curl -s -X POST http://localhost:8081/oauth2/token \
  -H "Host: azn-server:8080" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "cloudbank-service-client:${CLIENT_SECRET}" \
  -d "grant_type=client_credentials&scope=cloudbank.internal" | grep -o '"access_token":"[^"]*' | grep -o '[^"]*$')

# Clean up port-forward
kill $PF_PID

if [ -z "$TOKEN" ]; then
  echo "Failed to get OAuth2 token. Check if azn-server is running properly."
  exit 1
fi

echo "Port-forwarding helidon-producer to send message..."
kubectl port-forward svc/helidon-producer 8080:8080 -n $NAMESPACE > /dev/null 2>&1 &
PROD_PF_PID=$!
sleep 3

echo "Sending message to /post..."
curl -X POST -H "Content-Type: text/plain" -H "Authorization: Bearer $TOKEN" -d "Hello from Helidon Producer at $(date)" "http://$GATEWAY_URL/post"
echo -e "\n"

# Clean up producer port-forward
kill $PROD_PF_PID

echo "Check logs to verify Kafka delivery:"
echo "kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=helidon-producer"
