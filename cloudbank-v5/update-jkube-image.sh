#!/bin/bash

# Script to update JKube image name in pom.xml files
# Usage: ./update-jkube-image.sh <new-image-prefix>

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <new-image-prefix>"
    echo "Example: $0 myregistry.io/myorg/cloudbank-v5"
    echo ""
    echo "This will update the image name to: <new-image-prefix>/<service>:\${project.version}"
    return 1 2>/dev/null || exit 1
fi

NEW_IMAGE_PREFIX="$1"

# Array of services to update
SERVICES=(
    "account"
    "customer"
    "transfer"
    "checks"
    "creditscore"
    "testrunner"
)

echo "Updating JKube image names with prefix: $NEW_IMAGE_PREFIX"
echo "=========================================================="

for service in "${SERVICES[@]}"; do
    POM_FILE="$service/pom.xml"

    if [ -f "$POM_FILE" ]; then
        echo "Updating $POM_FILE..."

        # Update the <name> tag to: <new-prefix>/<service>:${project.version}
        sed -i.bak "s|<name>.*/${service}:\${project.version}</name>|<name>$NEW_IMAGE_PREFIX/$service:\${project.version}</name>|" "$POM_FILE"

        # Remove backup file
        rm "${POM_FILE}.bak"

        echo "✓ $service updated to $NEW_IMAGE_PREFIX/$service:\${project.version}"
    else
        echo "⚠ Warning: pom.xml not found for $service"
    fi
done

echo ""
echo "=========================================================="
echo "All pom.xml files updated successfully!"
