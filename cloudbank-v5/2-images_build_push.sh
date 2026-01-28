#!/bin/bash
# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

# CloudBank v5 Build and Push Images Script
# Builds all microservice images and pushes them to a container registry.
#
# Usage:
#   ./2-images_build_push.sh [options]
#
# Options:
#   -r, --registry REGISTRY      Full container registry path (use as-is, no prefix added)
#                                If not provided, auto-detects from OCI CLI with cloudbank-v5 prefix
#   -p, --prefix PREFIX          Repository prefix for OCIR auto-detection (default: cloudbank-v5)
#   -t, --tag TAG                Image tag (default: 0.0.1-SNAPSHOT)
#   --run-tests                  Run tests during build (default: tests are skipped)
#   --skip-push                  Build images but don't push to registry
#   -h, --help                   Show this help message
#
# Prerequisites:
#   - Docker daemon running
#   - OCI CLI configured (if not providing -r/--registry)
#   - Logged into container registry (docker login)
#
# Example:
#   ./2-images_build_push.sh                                        # Auto-detect OCIR from OCI CLI
#   ./2-images_build_push.sh -p my-app                              # Auto-detect OCIR with custom prefix
#   ./2-images_build_push.sh -r us-phoenix-1.ocir.io/ns/cloudbank   # Explicit OCIR path
#   ./2-images_build_push.sh -r docker.io/myuser/cloudbank          # Docker Hub

set -e

# =============================================================================
# Script Directory and Prerequisites Library
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the prerequisites check library
# shellcheck source=check_prereqs.sh
source "${SCRIPT_DIR}/check_prereqs.sh"

# =============================================================================
# Variables
# =============================================================================

REGISTRY=""
REPO_PREFIX="cloudbank-v5"
JKUBE_VERSION=$(grep '<jkube.version>' "${SCRIPT_DIR}/pom.xml" | sed 's/.*<jkube.version>\(.*\)<\/jkube.version>.*/\1/')
IMAGE_TAG="0.0.1-SNAPSHOT"
SKIP_TESTS=true
SKIP_PUSH=false
SKIP_PREREQS=false
CLEAN_BUILD=false
PARALLEL_THREADS="1C"  # 1 thread per CPU core, or set to specific number like "4"

# Services to build
SERVICES=(
    "account"
    "customer"
    "transfer"
    "checks"
    "creditscore"
    "testrunner"
)

# =============================================================================
# Parse Arguments
# =============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--registry)
                REGISTRY="$2"
                shift 2
                ;;
            -p|--prefix)
                REPO_PREFIX="$2"
                shift 2
                ;;
            -t|--tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            --run-tests)
                SKIP_TESTS=false
                shift
                ;;
            --skip-push)
                SKIP_PUSH=true
                shift
                ;;
            --skip-prereqs)
                SKIP_PREREQS=true
                shift
                ;;
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            -j|--parallel)
                PARALLEL_THREADS="$2"
                shift 2
                ;;
            --check-prereqs-only)
                # Run prerequisite checks and exit (used by install.sh)
                prereq_check_build
                exit $?
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
CloudBank v5 Build and Push Images Script

Builds all microservice container images and pushes them to a registry.

Usage:
  ./2-images_build_push.sh [options]

Options:
  -r, --registry REGISTRY      Full container registry path (used as-is, no prefix added)
                               If not provided, auto-detects from OCI CLI with prefix
  -p, --prefix PREFIX          Repository prefix for OCIR auto-detection (default: cloudbank-v5)
                               Only used when -r is not provided
  -t, --tag TAG                Image tag (default: 0.0.1-SNAPSHOT)
  -j, --parallel THREADS       Number of parallel build threads (default: 1C = 1 per CPU core)
                               Use "1" to disable parallel builds
  --run-tests                  Run tests during build (default: tests are skipped)
  --skip-push                  Build images but don't push to registry
  --clean                      Clean build: remove cached artifacts and rebuild from scratch
  --skip-prereqs               Skip prerequisite checks (used by install.sh)
  -h, --help                   Show this help message

Prerequisites:
  - Java 21 with JAVA_HOME set
  - Docker daemon running
  - OCI CLI configured (if not providing -r/--registry)
  - Logged into container registry: docker login <registry>

Services built:
  account, customer, transfer, checks, creditscore, testrunner

Example:
  ./2-images_build_push.sh                                        # Auto-detect OCIR from OCI CLI
  ./2-images_build_push.sh -p my-app                              # Auto-detect OCIR with custom prefix
  ./2-images_build_push.sh -r us-phoenix-1.ocir.io/ns/cloudbank   # Explicit OCIR path
  ./2-images_build_push.sh -r docker.io/myuser/cloudbank          # Docker Hub
  ./2-images_build_push.sh --skip-push                            # Build only, don't push
EOF
}

# =============================================================================
# Prompt for Input
# =============================================================================
prompt_value() {
    local var_name="$1"
    local prompt="$2"
    local example="$3"
    local current_value="${!var_name}"

    if [[ -n "$current_value" ]]; then
        return 0
    fi

    local full_prompt="$prompt"
    if [[ -n "$example" ]]; then
        full_prompt="$prompt (e.g., $example)"
    fi

    while true; do
        read -p "$full_prompt: " value
        if [[ -n "$value" ]]; then
            eval "$var_name=\"$value\""
            return 0
        else
            print_error "Value is required. Please enter a value."
        fi
    done
}

# =============================================================================
# Validation
# =============================================================================

validate_inputs() {
    # No validation needed - registry is either provided, auto-detected, or we exit earlier
    return 0
}

# =============================================================================
# Build Functions
# =============================================================================
clean_artifacts() {
    print_header "Cleaning Build Artifacts"

    local module_list=("cloudbank-apps" "common" "buildtools" "${SERVICES[@]}")

    # Clean local Maven repository artifacts for this project
    print_step "Removing cached Maven artifacts..."
    for module in "${module_list[@]}"; do
        rm -rf ~/.m2/repository/com/example/"$module"
    done
    print_success "Maven cache cleared"

    # Clean target directories
    print_step "Removing target directories..."
    for module in "${module_list[@]}"; do
        rm -rf "$SCRIPT_DIR/$module/target" 2>/dev/null
    done
    rm -rf "$SCRIPT_DIR/target" 2>/dev/null
    print_success "Target directories cleared"
}

build_dependencies() {
    print_header "Building Dependencies"

    print_step "Installing parent pom and building modules..."
    print_info "This installs shared code to your local Maven repository"
    echo ""

    # Build order matters:
    # 1. buildtools first (needed by checkstyle plugin)
    # 2. parent pom (references buildtools for checkstyle)
    # 3. common module
    if ! mvn clean install -pl buildtools; then
        print_error "Failed to build buildtools"
        return 1
    fi

    if ! mvn clean install -N; then
        print_error "Failed to install parent pom"
        return 1
    fi

    if ! mvn clean install -pl common; then
        print_error "Failed to build common module"
        return 1
    fi

    print_success "Dependencies built successfully"
}


pull_base_image() {
    # CloudBank services use Oracle's OBaaS OpenJDK image as base
    local base_image_name="ghcr.io/oracle/openjdk-image-obaas:${PREREQ_REQUIRED_JAVA_VERSION}"

    print_step "Pre-pulling base image: $base_image_name"
    if docker pull "$base_image_name"; then
        print_success "Base image ready"
    else
        print_warning "Could not pre-pull base image (will be pulled during build)"
    fi
}

build_and_push() {
    local registry="$1"

    print_header "Building and Pushing Images"

    # Pre-pull base image first
    pull_base_image

    local service_list
    service_list=$(IFS=,; echo "${SERVICES[*]}")

    # Common Maven options
    local maven_options=""
    if [[ -n "$registry" ]]; then
        maven_options="$maven_options -Dimage.registry=$registry"
    fi
    if [[ "$SKIP_TESTS" == true ]]; then
        maven_options="$maven_options -DskipTests"
    fi

    # Step 1: Build JARs in parallel (benefits from -T flag)
    print_step "Building JAR files..."
    if [[ "$PARALLEL_THREADS" != "1" ]]; then
        print_info "Building in parallel with $PARALLEL_THREADS threads..."
    fi
    local maven_build_command="mvn -T $PARALLEL_THREADS clean package -pl $service_list $maven_options"
    print_info "Running: $maven_build_command"
    echo ""
    if ! $maven_build_command; then
        print_error "Failed to build JARs"
        return 1
    fi
    print_success "JAR files built"
    echo ""

    # Step 2: Build and push Docker images sequentially
    # Docker daemon and registry pushes don't parallelize well
    print_step "Building and pushing container images..."

    local jkube_goals="org.eclipse.jkube:kubernetes-maven-plugin:${JKUBE_VERSION}:build"
    if [[ "$SKIP_PUSH" != true ]]; then
        jkube_goals="$jkube_goals org.eclipse.jkube:kubernetes-maven-plugin:${JKUBE_VERSION}:push"
    fi

    for service in "${SERVICES[@]}"; do
        print_step "  $service..."
        if ! mvn $jkube_goals -pl "$service" $maven_options -q; then
            print_error "Failed to build/push $service"
            print_info "  - Check Docker is running: docker ps"
            print_info "  - Check registry login: docker login $registry"
            return 1
        fi
        print_success "  $service done"
    done

    print_success "All images built and pushed successfully"
}

verify_images() {
    local registry="$1"

    print_header "Verifying Images"

    print_step "Checking local images..."
    echo ""

    local image_count=0
    for service in "${SERVICES[@]}"; do
        local image_name="$registry/$service:$IMAGE_TAG"
        if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "$registry/$service"; then
            print_success "$service image found"
            ((image_count++))
        else
            print_warning "$service image not found locally"
        fi
    done

    echo ""
    if [[ $image_count -eq ${#SERVICES[@]} ]]; then
        print_success "All ${#SERVICES[@]} images built successfully"
    else
        print_warning "Only $image_count of ${#SERVICES[@]} images found"
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    print_header "CloudBank v5 Build and Push Images"

    # Parse command line arguments
    parse_args "$@"

    # Check prerequisites (unless skipped)
    if [[ "$SKIP_PREREQS" != true ]]; then
        if ! prereq_check_build; then
            exit 1
        fi
    fi

    # Determine final registry path
    local final_registry=""

    if [[ -n "$REGISTRY" ]]; then
        # User provided explicit registry - use as-is (no prefix)
        final_registry="$REGISTRY"
    elif [[ "$SKIP_PUSH" == true ]]; then
        # Build-only mode - use localhost
        final_registry="localhost/${REPO_PREFIX}"
    else
        # No registry provided - auto-detect from OCI CLI and add prefix
        print_step "Auto-detecting registry from OCI CLI configuration..."
        if prereq_check_oci; then
            final_registry="${PREREQ_OCI_REGISTRY}/${REPO_PREFIX}"
            print_success "Registry: $final_registry"
        else
            print_error "Could not auto-detect registry from OCI CLI."
            print_info "Either configure OCI CLI (oci setup config) or provide -r/--registry"
            exit 1
        fi
    fi

    # Validate inputs
    if ! validate_inputs; then
        exit 1
    fi

    # Check registry connectivity (only if pushing)
    if [[ "$SKIP_PUSH" != true ]]; then
        if ! prereq_check_registry_connectivity "$final_registry"; then
            exit 1
        fi
    fi

    # Show configuration
    print_header "Configuration"
    echo "  Registry:    $final_registry"
    echo "  Image Tag:   $IMAGE_TAG"
    echo "  Parallel:    $PARALLEL_THREADS threads"
    echo "  Skip Tests:  $SKIP_TESTS"
    echo "  Skip Push:   $SKIP_PUSH"
    echo "  Clean Build: $CLEAN_BUILD"
    echo ""
    echo "  Services:    ${SERVICES[*]}"
    echo ""

    read -p "Continue with build? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Build cancelled."
        exit 0
    fi

    # Clean artifacts if requested
    if [[ "$CLEAN_BUILD" == true ]]; then
        clean_artifacts
    fi

    # Build dependencies first
    if ! build_dependencies; then
        exit 1
    fi

    # Build and push images
    if ! build_and_push "$final_registry"; then
        exit 1
    fi

    # Verify images
    verify_images "$final_registry"

    # Summary
    print_header "Summary"
    print_success "Images built and pushed successfully!"
    echo ""
    echo "Images pushed to:"
    for service in "${SERVICES[@]}"; do
        echo "  $final_registry/$service:$IMAGE_TAG"
    done
    echo ""
    echo "Next step:"
    echo "  Create database secrets: ./3-k8s_db_secrets.sh -n <namespace> -d <dbname>"
}

# Run main function
main "$@"
