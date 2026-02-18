#!/usr/bin/env bash
# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

# =============================================================================
# OBaaS Image Mirror Script
# =============================================================================
# Mirrors container images from public registries to a private registry.
#
# Usage:
#   ./mirror-images.sh <target-registry> [options]
#
# Examples:
#   ./mirror-images.sh myregistry.example.com
#   ./mirror-images.sh myregistry.example.com --dry-run
#   ./mirror-images.sh myregistry.example.com -f /path/to/images.txt
#
# Prerequisites:
#   - docker or podman must be installed
#   - Login to both source and target registries before running
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
IMAGES_FILE="${IMAGE_LISTS_DIR}/k8s_images_${APP_VERSION}.txt"

# Default values
DRY_RUN=false
CONTAINER_CMD=""
PLATFORM="linux/amd64"
FAILED_IMAGES=()
SKIPPED_COUNT=0

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
Usage: $(basename "$0") <target-registry> [options]

Mirror OBaaS container images to a private registry.

Arguments:
    target-registry    The target registry URL (e.g., myregistry.example.com)

Options:
    -h, --help             Show this help message
    -n, --dry-run          Show what would be done without actually mirroring
    -f, --file FILE        Path to images file (default: ./image_lists/k8s_images_<appVersion>.txt)
    -p, --platform PLATFORM  Target platform for images (default: linux/amd64)

Examples:
    $(basename "$0") myregistry.example.com
    $(basename "$0") myregistry.example.com --dry-run
    $(basename "$0") myregistry.example.com -f /path/to/images.txt

EOF
    exit 0
}

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

# Detect docker or podman
detect_container_cmd() {
    if command -v docker &> /dev/null; then
        CONTAINER_CMD="docker"
    elif command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
    else
        log error "Neither docker nor podman is installed"
        echo "Install docker: https://docs.docker.com/get-docker/" >&2
        echo "Install podman: https://podman.io/getting-started/installation" >&2
        exit 1
    fi
    log none "Using: $CONTAINER_CMD"
}

# Transform source image to target image path
get_target_image() {
    local source_image=$1
    local target_registry=$2
    local image_path

    # Remove known registry prefixes
    image_path=$(echo "$source_image" | sed -E '
        s|^docker\.io/||;
        s|^registry\.k8s\.io/||;
        s|^quay\.io/||;
        s|^ghcr\.io/||;
        s|^gcr\.io/||;
        s|^container-registry\.oracle\.com/||;
        s|^us-phoenix-1\.ocir\.io/||;
        s|^[a-zA-Z0-9.-]+\.ocir\.io/||;
    ')

    echo "${target_registry}/${image_path}"
}

# Mirror a single image
mirror_image() {
    local source_image=$1
    local target_registry=$2
    local target_image

    # Skip if source image already starts with target registry
    if [[ "$source_image" == "${target_registry}/"* ]]; then
        log warn "Skipping (already in target registry): $source_image"
        ((SKIPPED_COUNT++))
        return 0
    fi

    # Skip OKE public images
    if [[ "$source_image" == *"oke-public"* ]]; then
        log warn "Skipping (oke-public): $source_image"
        ((SKIPPED_COUNT++))
        return 0
    fi

    target_image=$(get_target_image "$source_image" "$target_registry")

    if [[ "$DRY_RUN" == "true" ]]; then
        log none "[DRY-RUN] Would mirror ($PLATFORM): $source_image -> $target_image"
        return 0
    fi

    log info "Pulling: $source_image (platform: $PLATFORM)"
    if ! $CONTAINER_CMD pull --platform "$PLATFORM" "$source_image"; then
        log error "Failed to pull: $source_image"
        return 1
    fi

    log info "Tagging: $target_image"
    if ! $CONTAINER_CMD tag "$source_image" "$target_image"; then
        log error "Failed to tag: $target_image"
        return 1
    fi

    log info "Pushing: $target_image"
    if ! $CONTAINER_CMD push "$target_image"; then
        log error "Failed to push: $target_image"
        return 1
    fi

    # Clean up local images to save space
    $CONTAINER_CMD rmi "$source_image" "$target_image" &> /dev/null || true

    log success "Mirrored: $source_image -> $target_image"
}

# Parse command line arguments
parse_args() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    TARGET_REGISTRY=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--file)
                IMAGES_FILE="$2"
                shift 2
                ;;
            -p|--platform)
                PLATFORM="$2"
                shift 2
                ;;
            -*)
                log error "Unknown option: $1"
                usage
                ;;
            *)
                if [[ -z "$TARGET_REGISTRY" ]]; then
                    TARGET_REGISTRY="$1"
                else
                    log error "Unexpected argument: $1"
                    usage
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$TARGET_REGISTRY" ]]; then
        log error "Target registry is required"
        usage
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    parse_args "$@"
    detect_container_cmd

    if [[ ! -f "$IMAGES_FILE" ]]; then
        log error "Images file not found: $IMAGES_FILE"
        exit 1
    fi

    # Remove trailing slash from registry
    TARGET_REGISTRY="${TARGET_REGISTRY%/}"

    log none "=============================================="
    log none "OBaaS Image Mirror"
    log none "=============================================="
    log none "App Version: ${APP_VERSION}"
    log none "Target Registry: $TARGET_REGISTRY"
    log none "Images File: $IMAGES_FILE"
    log none "Platform: $PLATFORM"
    log none "Dry Run: $DRY_RUN"
    log none "=============================================="
    echo

    # Count images
    local total_images=0
    local successful=0
    local failed=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        ((total_images++))
    done < "$IMAGES_FILE"

    log info "Found $total_images images to mirror"
    echo

    # Process images
    local current=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        line=$(echo "$line" | xargs)

        ((current++))
        echo
        log none "[$current/$total_images] Processing: $line"

        if mirror_image "$line" "$TARGET_REGISTRY"; then
            ((successful++))
        else
            ((failed++))
            FAILED_IMAGES+=("$line")
        fi

    done < "$IMAGES_FILE"

    # Summary
    echo
    log none "=============================================="
    log none "Mirror Complete"
    log none "=============================================="
    log info "Total: $total_images"
    log success "Successful: $successful"
    if [[ $SKIPPED_COUNT -gt 0 ]]; then
        log warn "Skipped: $SKIPPED_COUNT"
    fi

    if [[ $failed -gt 0 ]]; then
        log error "Failed: $failed"
        echo
        log error "Failed images:"
        for img in "${FAILED_IMAGES[@]}"; do
            echo "  - $img"
        done
        exit 1
    fi

    echo
    log success "All images mirrored successfully!"
}

main "$@"
