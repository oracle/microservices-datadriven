#!/bin/bash

# Script to update image repository and tag in values.yaml files
# Usage: ./update-image.sh <repository> <tag>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <repository> <tag>"
    echo "Example: $0 my-repository 0.0.1-SNAPSHOT"
    return 1 2>/dev/null || exit 1
fi

REPOSITORY="$1"
TAG="$2"

# Ensure repository ends with /
if [[ ! "$REPOSITORY" =~ /$ ]]; then
    REPOSITORY="${REPOSITORY}/"
fi

# Find all values.yaml files in helm directories
find . -path "*/helm/values.yaml" -type f | while read -r file; do
    # Get the directory containing the values.yaml file
    helm_dir=$(dirname "$file")

    # Look for Chart.yaml in the same directory
    chart_file="${helm_dir}/Chart.yaml"

    if [ -f "$chart_file" ]; then
        # Extract the application name from Chart.yaml
        app_name=$(grep "^name:" "$chart_file" | sed 's/name: *//;s/ *#.*//' | tr -d ' ')

        if [ -n "$app_name" ]; then
            full_repository="${REPOSITORY}${app_name}"
            echo "Updating $file with repository: $full_repository"

            # Update repository line
            sed -i.bak "s|repository:.*|repository: \"$full_repository\"|" "$file"

            # Update tag line
            sed -i.bak "s|tag:.*|tag: \"$TAG\"|" "$file"

            # Remove backup file
            rm "${file}.bak"
        else
            echo "Warning: Could not extract app name from $chart_file"
        fi
    else
        echo "Warning: No Chart.yaml found for $file"
    fi
done

echo "All values.yaml files updated with repository: $REPOSITORY and tag: $TAG"
