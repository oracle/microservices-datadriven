#!/bin/bash

# Script to create OCI container repositories for CloudBank v5 services
# Usage: ./create-oci-repos.sh <compartment-name> <repository-prefix>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <compartment-name> <repository-prefix>"
    echo "Example: $0 my-compartment sjc.ocir.io/maacloud/cloudbank-v5"
    return 1 2>/dev/null || exit 1
fi

COMPARTMENT_NAME="$1"
REPO_PREFIX="$2"

# Look up compartment OCID from name
echo "Looking up compartment: $COMPARTMENT_NAME"
COMPARTMENT_OCID=$(oci iam compartment list --all --compartment-id-in-subtree true \
    --query "data[?name=='$COMPARTMENT_NAME'].id | [0]" --raw-output 2>&1)

if [ -z "$COMPARTMENT_OCID" ] || [ "$COMPARTMENT_OCID" = "null" ]; then
    echo "✗ Error: Compartment '$COMPARTMENT_NAME' not found"
    return 1 2>/dev/null || exit 1
fi

echo "Found compartment OCID: $COMPARTMENT_OCID"
echo ""

# Remove trailing slash if present
REPO_PREFIX="${REPO_PREFIX%/}"

# Array of services that need repositories
SERVICES=(
    "account"
    "customer"
    "transfer"
    "checks"
    "creditscore"
    "testrunner"
)

echo "Creating OCI container repositories"
echo "===================================="
echo "Compartment: $COMPARTMENT_OCID"
echo "Repository prefix: $REPO_PREFIX"
echo ""

# Create repository for each service
for service in "${SERVICES[@]}"; do
    REPO_NAME="${REPO_PREFIX}/${service}"
    echo "Creating repository: $REPO_NAME"

    oci artifacts container repository create \
        --compartment-id "$COMPARTMENT_OCID" \
        --display-name "$REPO_NAME" \
        --is-public true \
        2>&1

    if [ $? -eq 0 ]; then
        echo "✓ Repository $REPO_NAME created successfully"
    else
        echo "⚠ Warning: Failed to create repository $REPO_NAME (may already exist)"
    fi
    echo ""
done

echo "===================================="
echo "Repository creation complete!"
echo ""
echo "To list all repositories, run:"
echo "oci artifacts container repository list --compartment-id $COMPARTMENT_OCID"
