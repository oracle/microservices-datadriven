#!/bin/bash

# Script to deploy all CloudBank v5 services using Helm
# Usage: ./deploy-all-services.sh <namespace>

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <namespace>"
    echo "Example: $0 obaas-dev"
    return 1 2>/dev/null || exit 1
fi

NAMESPACE="$1"

# Array of services to deploy
SERVICES=(
    "account"
    "customer"
    "transfer"
    "checks"
    "creditscore"
    "testrunner"
)

echo "Deploying CloudBank v5 services"
echo "================================"

# Deploy each service
for service in "${SERVICES[@]}"; do
    echo ""
    echo "Deploying $service..."

    if [ -d "$service/helm" ]; then
        helm upgrade --install "$service" "./$service/helm" --namespace "$NAMESPACE" --wait --debug

        if [ $? -eq 0 ]; then
            echo "✓ $service deployed successfully"
        else
            echo "✗ Failed to deploy $service"
            return 1 2>/dev/null || exit 1
        fi
    else
        echo "⚠ Warning: Helm chart not found for $service at $service/helm"
    fi
done

echo ""
echo "================================"
echo "All services deployed successfully!"
