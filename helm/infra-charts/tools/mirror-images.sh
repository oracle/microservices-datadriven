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
#   ./mirror-images.sh myregistry.example.com -f /path/to/images.txt --platform linux/amd64 --export-only --archive-dir /tmp/obaas-images
#   ./mirror-images.sh myregistry.example.com --import-only --archive-dir /tmp/obaas-images
#
# Prerequisites:
#   - docker or podman must be installed
#   - Login to source registries for normal or export-only mode
#   - Login to the target registry for normal or import-only mode
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
MODE="mirror"
ARCHIVE_DIR=""
MANIFEST_FILE=""
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
    --export-only          Pull, tag, and save images to --archive-dir without pushing
    --import-only          Load images from --archive-dir and push them without pulling
    --archive-dir DIR      Directory used by --export-only and --import-only
                          Successful --import-only runs remove imported archives

Examples:
    $(basename "$0") myregistry.example.com
    $(basename "$0") myregistry.example.com --dry-run
    $(basename "$0") myregistry.example.com -f /path/to/images.txt
    $(basename "$0") myregistry.example.com -f /path/to/images.txt --platform linux/amd64 --export-only --archive-dir /tmp/obaas-images
    $(basename "$0") myregistry.example.com --import-only --archive-dir /tmp/obaas-images

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

get_image_hash() {
    local image=$1

    if command -v sha256sum &> /dev/null; then
        printf '%s' "$image" | sha256sum | awk '{print $1}'
    elif command -v shasum &> /dev/null; then
        printf '%s' "$image" | shasum -a 256 | awk '{print $1}'
    else
        printf '%s' "$image" | cksum | awk '{print $1}'
    fi
}

get_archive_name() {
    local target_image=$1
    local safe_name
    local image_hash

    safe_name=$(echo "$target_image" | sed -E 's|[^A-Za-z0-9_.-]+|_|g')
    safe_name="${safe_name:0:80}"
    image_hash=$(get_image_hash "$target_image")

    echo "${safe_name}_${image_hash}.tar"
}

get_image_name_without_tag_or_digest() {
    local image=${1%%@*}
    local last_path_part=${image##*/}

    if [[ "$last_path_part" == *:* ]]; then
        echo "${image%:*}"
    else
        echo "$image"
    fi
}

get_platform_digest() {
    local image=$1
    local platform=$2
    local os=${platform%%/*}
    local arch_variant=${platform#*/}
    local arch=${arch_variant%%/*}
    local variant=""
    local manifest

    if [[ "$arch_variant" == */* ]]; then
        variant=${arch_variant#*/}
    fi

    manifest=$($CONTAINER_CMD manifest inspect "$image" 2>/dev/null || true)
    if [[ -z "$manifest" || "$manifest" != *'"manifests"'* ]]; then
        return 1
    fi

    awk -v wanted_os="$os" -v wanted_arch="$arch" -v wanted_variant="$variant" '
        function json_value(line) {
            sub(/^.*:[[:space:]]*"/, "", line)
            sub(/".*$/, "", line)
            return line
        }
        /"digest"[[:space:]]*:/ {
            digest = json_value($0)
        }
        /"platform"[[:space:]]*:/ {
            in_platform = 1
            os = ""
            arch = ""
            variant = ""
        }
        in_platform && /"architecture"[[:space:]]*:/ {
            arch = json_value($0)
        }
        in_platform && /"os"[[:space:]]*:/ {
            os = json_value($0)
        }
        in_platform && /"variant"[[:space:]]*:/ {
            variant = json_value($0)
        }
        in_platform && /^[[:space:]]*}/ {
            if (os == wanted_os && arch == wanted_arch && (wanted_variant == "" || variant == wanted_variant)) {
                print digest
                exit
            }
            in_platform = 0
        }
    ' <<< "$manifest"
}

should_skip_image() {
    local source_image=$1
    local target_registry=$2

    if [[ "$source_image" == "${target_registry}/"* ]]; then
        log warn "Skipping (already in target registry): $source_image"
        ((SKIPPED_COUNT+=1))
        return 0
    fi

    if [[ "$source_image" == *"oke-public"* ]]; then
        log warn "Skipping (oke-public): $source_image"
        ((SKIPPED_COUNT+=1))
        return 0
    fi

    return 1
}

# Mirror a single image
mirror_image() {
    local source_image=$1
    local target_registry=$2
    local target_image

    if should_skip_image "$source_image" "$target_registry"; then
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

export_image() {
    local source_image=$1
    local target_registry=$2
    local target_image
    local platform_digest
    local pull_image
    local archive_name
    local archive_path
    local temp_archive_path

    if should_skip_image "$source_image" "$target_registry"; then
        return 0
    fi

    target_image=$(get_target_image "$source_image" "$target_registry")
    archive_name=$(get_archive_name "$target_image")
    archive_path="${ARCHIVE_DIR}/${archive_name}"
    temp_archive_path="${archive_path}.tmp"

    if [[ "$DRY_RUN" == "true" ]]; then
        log none "[DRY-RUN] Would export ($PLATFORM): $source_image -> $target_image -> $archive_path"
        return 0
    fi

    platform_digest=$(get_platform_digest "$source_image" "$PLATFORM" || true)
    if [[ -n "$platform_digest" ]]; then
        pull_image="$(get_image_name_without_tag_or_digest "$source_image")@${platform_digest}"
        log info "Resolved $PLATFORM digest: $platform_digest"
        log info "Pulling: $pull_image"
        if ! $CONTAINER_CMD pull "$pull_image"; then
            log error "Failed to pull: $pull_image"
            return 1
        fi
    else
        pull_image="$source_image"
        log info "Pulling: $source_image (platform: $PLATFORM)"
        if ! $CONTAINER_CMD pull --platform "$PLATFORM" "$source_image"; then
            log error "Failed to pull: $source_image"
            return 1
        fi
    fi

    log info "Tagging: $target_image"
    if ! $CONTAINER_CMD tag "$pull_image" "$target_image"; then
        log error "Failed to tag: $target_image"
        return 1
    fi

    log info "Saving archive: $archive_path"
    if ! $CONTAINER_CMD save -o "$temp_archive_path" "$target_image"; then
        log error "Failed to save archive: $archive_path"
        rm -f "$temp_archive_path"
        return 1
    fi

    if [[ ! -s "$temp_archive_path" ]]; then
        log error "Failed to save archive: $archive_path"
        rm -f "$temp_archive_path"
        return 1
    fi

    mv "$temp_archive_path" "$archive_path"
    printf '%s\t%s\t%s\t%s\n' "$source_image" "$target_image" "$archive_name" "$PLATFORM" >> "$MANIFEST_FILE"

    # Clean up local images to save space
    $CONTAINER_CMD rmi "$pull_image" "$source_image" "$target_image" &> /dev/null || true

    log success "Exported: $source_image -> $archive_path"
}

import_image() {
    local source_image=$1
    local target_image=$2
    local archive_name=$3
    local image_platform=${4:-unknown}
    local archive_path="${ARCHIVE_DIR}/${archive_name}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log none "[DRY-RUN] Would import and push ($image_platform): $archive_path -> $target_image"
        return 0
    fi

    if [[ ! -f "$archive_path" ]]; then
        log error "Archive not found: $archive_path"
        return 1
    fi

    log info "Loading archive: $archive_path"
    if ! $CONTAINER_CMD load -i "$archive_path"; then
        log error "Failed to load archive: $archive_path"
        return 1
    fi

    log info "Pushing: $target_image"
    if ! $CONTAINER_CMD push "$target_image"; then
        log error "Failed to push: $target_image"
        return 1
    fi

    # Clean up loaded image to save space
    $CONTAINER_CMD rmi "$target_image" &> /dev/null || true

    log success "Imported and pushed ($image_platform): $source_image -> $target_image"
}

count_images_file() {
    local total=0
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        ((total+=1))
    done < "$IMAGES_FILE"

    echo "$total"
}

count_manifest_file() {
    local total=0
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        ((total+=1))
    done < "$MANIFEST_FILE"

    echo "$total"
}

process_images_file() {
    local total_images=$1
    local current=0
    local successful=0
    local failed=0
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        line=$(echo "$line" | xargs)

        ((current+=1))
        echo
        log none "[$current/$total_images] Processing: $line"

        if [[ "$MODE" == "export" ]]; then
            if export_image "$line" "$TARGET_REGISTRY"; then
                ((successful+=1))
            else
                ((failed+=1))
                FAILED_IMAGES+=("$line")
            fi
        else
            if mirror_image "$line" "$TARGET_REGISTRY"; then
                ((successful+=1))
            else
                ((failed+=1))
                FAILED_IMAGES+=("$line")
            fi
        fi
    done < "$IMAGES_FILE"

    print_summary "$total_images" "$successful" "$failed"
}

process_manifest_file() {
    local total_images=$1
    local current=0
    local successful=0
    local failed=0
    local line
    local source_image
    local target_image
    local archive_name
    local image_platform

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        IFS=$'\t' read -r source_image target_image archive_name image_platform <<< "$line"

        if [[ -z "$source_image" || -z "$target_image" || -z "$archive_name" ]]; then
            log error "Invalid manifest line: $line"
            ((failed+=1))
            FAILED_IMAGES+=("$line")
            continue
        fi
        image_platform="${image_platform:-unknown}"

        if [[ "$target_image" != "${TARGET_REGISTRY}/"* ]]; then
            log error "Manifest target does not match target registry: $target_image"
            ((failed+=1))
            FAILED_IMAGES+=("$source_image")
            continue
        fi

        if [[ "$image_platform" != "$PLATFORM" ]]; then
            log error "Manifest platform $image_platform does not match requested platform $PLATFORM: $source_image"
            ((failed+=1))
            FAILED_IMAGES+=("$source_image")
            continue
        fi

        ((current+=1))
        echo
        log none "[$current/$total_images] Processing: $source_image"

        if import_image "$source_image" "$target_image" "$archive_name" "$image_platform"; then
            ((successful+=1))
        else
            ((failed+=1))
            FAILED_IMAGES+=("$source_image")
        fi
    done < "$MANIFEST_FILE"

    print_summary "$total_images" "$successful" "$failed"
}

cleanup_import_archives() {
    local line
    local source_image
    local target_image
    local archive_name
    local image_platform
    local archive_path

    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    log info "Cleaning up imported archives from: $ARCHIVE_DIR"

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        IFS=$'\t' read -r source_image target_image archive_name image_platform <<< "$line"
        if [[ -z "$archive_name" || "$archive_name" == */* || "$archive_name" == "." || "$archive_name" == ".." ]]; then
            log warn "Skipping cleanup for invalid archive name: ${archive_name:-<empty>}"
            continue
        fi

        archive_path="${ARCHIVE_DIR}/${archive_name}"
        rm -f -- "$archive_path"
    done < "$MANIFEST_FILE"

    rm -f -- "$MANIFEST_FILE"

    if rmdir -- "$ARCHIVE_DIR" 2>/dev/null; then
        log success "Removed archive directory: $ARCHIVE_DIR"
    else
        log warn "Archive directory is not empty; left in place: $ARCHIVE_DIR"
    fi
}

print_summary() {
    local total_images=$1
    local successful=$2
    local failed=$3
    local action

    case "$MODE" in
        export) action="Export" ;;
        import) action="Import" ;;
        *)      action="Mirror" ;;
    esac

    echo
    log none "=============================================="
    log none "${action} Complete"
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
    log success "All images processed successfully!"
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
                if [[ $# -lt 2 ]]; then
                    log error "$1 requires a file path"
                    usage
                fi
                IMAGES_FILE="$2"
                shift 2
                ;;
            -p|--platform)
                if [[ $# -lt 2 ]]; then
                    log error "$1 requires a platform"
                    usage
                fi
                PLATFORM="$2"
                shift 2
                ;;
            --export-only)
                if [[ "$MODE" != "mirror" ]]; then
                    log error "Use only one of --export-only or --import-only"
                    usage
                fi
                MODE="export"
                shift
                ;;
            --import-only)
                if [[ "$MODE" != "mirror" ]]; then
                    log error "Use only one of --export-only or --import-only"
                    usage
                fi
                MODE="import"
                shift
                ;;
            --archive-dir)
                if [[ $# -lt 2 ]]; then
                    log error "$1 requires a directory"
                    usage
                fi
                ARCHIVE_DIR="$2"
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

    if [[ "$MODE" != "mirror" && -z "$ARCHIVE_DIR" ]]; then
        log error "--archive-dir is required with --export-only and --import-only"
        usage
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    parse_args "$@"
    detect_container_cmd

    if [[ "$MODE" != "import" && ! -f "$IMAGES_FILE" ]]; then
        log error "Images file not found: $IMAGES_FILE"
        exit 1
    fi

    # Remove trailing slash from registry
    TARGET_REGISTRY="${TARGET_REGISTRY%/}"

    if [[ -n "$ARCHIVE_DIR" ]]; then
        ARCHIVE_DIR="${ARCHIVE_DIR%/}"
        MANIFEST_FILE="${ARCHIVE_DIR}/manifest.tsv"
    fi

    if [[ "$MODE" == "export" && "$DRY_RUN" != "true" ]]; then
        mkdir -p "$ARCHIVE_DIR"
        printf '# source_image\ttarget_image\tarchive_file\tplatform\n' > "$MANIFEST_FILE"
    fi

    if [[ "$MODE" == "import" && ! -f "$MANIFEST_FILE" ]]; then
        log error "Manifest file not found: $MANIFEST_FILE"
        exit 1
    fi

    log none "=============================================="
    log none "OBaaS Image Mirror"
    log none "=============================================="
    log none "App Version: ${APP_VERSION}"
    log none "Target Registry: $TARGET_REGISTRY"
    if [[ "$MODE" != "import" ]]; then
        log none "Images File: $IMAGES_FILE"
    fi
    log none "Platform: $PLATFORM"
    log none "Mode: $MODE"
    if [[ -n "$ARCHIVE_DIR" ]]; then
        log none "Archive Dir: $ARCHIVE_DIR"
        log none "Manifest File: $MANIFEST_FILE"
    fi
    log none "Dry Run: $DRY_RUN"
    log none "=============================================="
    echo

    if [[ "$MODE" == "import" ]]; then
        local total_images
        total_images=$(count_manifest_file)
        log info "Found $total_images archived images to import"
        echo
        process_manifest_file "$total_images"
        cleanup_import_archives
    else
        local total_images
        total_images=$(count_images_file)
        if [[ "$MODE" == "export" ]]; then
            log info "Found $total_images images to export"
        else
            log info "Found $total_images images to mirror"
        fi
        echo
        process_images_file "$total_images"
    fi
}

main "$@"
