#!/usr/bin/env bash
# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

# =============================================================================
# OBaaS Image List Generator
# =============================================================================
# Extracts all container images from a running OBaaS deployment using kubectl.
#
# Usage:
#   ./generate-images-list.sh [options] [namespace...]
#
# Examples:
#   ./generate-images-list.sh                          # All namespaces (default)
#   ./generate-images-list.sh obaas                    # Single namespace
#   ./generate-images-list.sh obaas obaas-prereqs      # Multiple namespaces
#   ./generate-images-list.sh -A                       # All namespaces (explicit)
#
# Output:
#   image_lists/k8s_images_<appVersion>.txt - Complete list of container images (e.g., image_lists/k8s_images_2.0.0.txt)
#
# Prerequisites:
#   - kubectl must be installed and configured
#   - Access to the Kubernetes cluster
#
# =============================================================================

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_FILE="${SCRIPT_DIR}/../obaas/Chart.yaml"

# Extract appVersion from Chart.yaml
get_app_version() {
    if [[ -f "$CHART_FILE" ]]; then
        grep '^appVersion:' "$CHART_FILE" | sed 's/appVersion:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}/\1/'
    else
        echo "unknown"
    fi
}

APP_VERSION=$(get_app_version)
IMAGE_LISTS_DIR="${SCRIPT_DIR}/image_lists"
OUTPUT_FILE="${IMAGE_LISTS_DIR}/k8s_images_${APP_VERSION}.txt"

# Default values
NAMESPACES=()
ALL_NAMESPACES=false

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
log() {
    case "$1" in
        none)    echo "$2" ;;
        info)    echo "ℹ️  $2" ;;
        success) echo "✅ $2" ;;
        warn)    echo "⚠️  $2" ;;
        error)   echo "❌ $2" >&2 ;;
    esac
}

# -----------------------------------------------------------------------------
# Usage
# -----------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $(basename "$0") [options] [namespace...]

Extract container images from a running OBaaS deployment.

Options:
    -h, --help         Show this help message
    -A, --all          Get images from all namespaces (default if no namespace specified)
    -o, --output FILE  Output file (default: ./image_lists/k8s_images_<appVersion>.txt)

Examples:
    $(basename "$0")                          # All namespaces (default)
    $(basename "$0") obaas                    # Single namespace
    $(basename "$0") obaas obaas-prereqs      # Multiple namespaces
    $(basename "$0") -A                       # All namespaces (explicit)

EOF
    exit 0
}

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

# Test cluster access
test_cluster_access() {
    log none "Testing cluster access..."

    if ! kubectl cluster-info &> /dev/null; then
        log error "Cannot connect to Kubernetes cluster"
        echo "Please check:" >&2
        echo "  - KUBECONFIG is set correctly" >&2
        echo "  - Cluster is reachable" >&2
        echo "  - Credentials are valid" >&2
        exit 1
    fi

    if ! kubectl auth can-i get pods &> /dev/null; then
        log error "No permission to get pods"
        echo "Please check your RBAC permissions" >&2
        exit 1
    fi

    log success "Cluster access verified"
}

# Check if namespace exists
check_namespace() {
    local ns=$1
    if ! kubectl get namespace "$ns" &> /dev/null; then
        log error "Namespace '$ns' does not exist or is not accessible"
        return 1
    fi
    return 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -A|--all)
                ALL_NAMESPACES=true
                shift
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -*)
                log error "Unknown option: $1"
                usage
                ;;
            *)
                NAMESPACES+=("$1")
                shift
                ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# Prerequisites
# -----------------------------------------------------------------------------
if ! command -v kubectl &> /dev/null; then
    log error "kubectl is not installed or not in PATH"
    echo "Install kubectl: https://kubernetes.io/docs/tasks/tools/" >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    parse_args "$@"

    log none "=============================================="
    log none "OBaaS Image List Generator"
    log none "=============================================="
    log none "App Version: ${APP_VERSION}"
    echo

    # Test cluster access first
    test_cluster_access
    echo

    # Validate arguments and namespaces
    # Default to all namespaces if none specified
    if [[ ${#NAMESPACES[@]} -eq 0 ]]; then
        ALL_NAMESPACES=true
    fi

    if [[ "$ALL_NAMESPACES" == "true" ]]; then
        log none "Extracting images from all namespaces..."
    else
        # Verify all namespaces exist
        for ns in "${NAMESPACES[@]}"; do
            if ! check_namespace "$ns"; then
                exit 1
            fi
        done
        log info "Extracting images from namespace(s): ${NAMESPACES[*]}"
    fi

    echo

    # Ensure output directory exists
    mkdir -p "$IMAGE_LISTS_DIR"

    # Collect images
    {
        echo "# OBaaS Helm Charts - Complete Image List"
        echo "# Generated for private registry mirroring"
        echo "# Generated on: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "#"
        echo "# ============================================================================"
        echo ""

        if [[ "$ALL_NAMESPACES" == "true" ]]; then
            # Get all images from all namespaces
            kubectl get pods -A -o jsonpath="{.items[*].spec.containers[*].image}" | tr ' ' '\n'
            kubectl get pods -A -o jsonpath="{.items[*].spec.initContainers[*].image}" | tr ' ' '\n'
        else
            # Get images from specified namespaces
            for ns in "${NAMESPACES[@]}"; do
                kubectl get pods -n "$ns" -o jsonpath="{.items[*].spec.containers[*].image}" 2>/dev/null | tr ' ' '\n'
                kubectl get pods -n "$ns" -o jsonpath="{.items[*].spec.initContainers[*].image}" 2>/dev/null | tr ' ' '\n'
            done
        fi
    } | grep -v '^\s*$' | sort -u > "$OUTPUT_FILE"

    # Count images
    local count
    count=$(grep -v '^#' "$OUTPUT_FILE" | grep -v '^\s*$' | wc -l | tr -d ' ')

    echo

    if [[ "$count" -eq 0 ]]; then
        log error "No images found. Are there any running pods in the specified namespace(s)?"
        rm -f "$OUTPUT_FILE"
        exit 1
    fi

    log none "=============================================="
    log none "Generation Complete"
    log none "=============================================="
    log success "Generated: ${OUTPUT_FILE}"
    log info "Total unique images: ${count}"
}

main "$@"
