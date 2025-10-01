#!/bin/bash

# Script to update image repository and tag in values.yaml files
# Usage: ./update-image.sh <repository> <tag>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <repository> <tag>"
    echo "Example: $0 my-repository/account 0.0.1-SNAPSHOT"
    exit 1
fi

REPOSITORY="$1"
TAG="$2"

# Find all values.yaml files
find . -name "values.yaml" -type f | while read -r file; do
    echo "Updating $file..."

    # Update repository line
    sed -i.bak "s|repository:.*|repository: \"$REPOSITORY\"|" "$file"

    # Update tag line
    sed -i.bak "s|tag:.*|tag: \"$TAG\"|" "$file"

    # Remove backup file
    rm "${file}.bak"
done

echo "All values.yaml files updated with repository: $REPOSITORY and tag: $TAG"
