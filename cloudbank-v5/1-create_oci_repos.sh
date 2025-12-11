#!/bin/bash
# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

# CloudBank v5 OCI Container Repository Creation Script
# Creates container repositories in OCI for all CloudBank microservices.
#
# Usage:
#   ./1-create_oci_repos.sh [options]
#
# Options:
#   -c, --compartment COMPARTMENT  OCI compartment name (required)
#   -p, --prefix PREFIX            Repository prefix (required, e.g., cloudbank-v5)
#   --public                       Create public repositories (default)
#   --private                      Create private repositories
#   --dry-run                      Show what would be created without creating
#   -h, --help                     Show this help message
#
# Prerequisites:
#   - OCI CLI installed and configured
#   - Valid OCI credentials
#
# Note: The registry URL is determined from your OCI CLI configuration (region and namespace).
#
# Example:
#   ./1-create_oci_repos.sh -c my-compartment -p cloudbank-v5

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
COMPARTMENT=""
REPO_PREFIX=""
IS_PUBLIC=true
DRY_RUN=false
OCI_NAMESPACE=""
OCI_REGION=""
REGISTRY=""
COMPARTMENT_OCID=""

# Services that need repositories
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
            -c|--compartment)
                COMPARTMENT="$2"
                shift 2
                ;;
            -p|--prefix)
                REPO_PREFIX="$2"
                shift 2
                ;;
            --public)
                IS_PUBLIC=true
                shift
                ;;
            --private)
                IS_PUBLIC=false
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
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
CloudBank v5 OCI Container Repository Creation Script

Creates container repositories in OCI for all CloudBank microservices.

Usage:
  ./1-create_oci_repos.sh [options]

Options:
  -c, --compartment COMPARTMENT  OCI compartment name (required)
  -p, --prefix PREFIX            Repository prefix (required, e.g., cloudbank-v5)
  --public                       Create public repositories (default)
  --private                      Create private repositories
  --dry-run                      Show what would be created without creating
  -h, --help                     Show this help message

Prerequisites:
  - OCI CLI installed and configured (oci setup config)
  - Valid OCI credentials

Note:
  The registry URL is determined from your OCI CLI configuration (region and namespace).
  Repositories will be created in the region configured in ~/.oci/config.

Services:
  account, customer, transfer, checks, creditscore, testrunner

Example:
  ./1-create_oci_repos.sh -c my-compartment -p cloudbank-v5
  ./1-create_oci_repos.sh -c my-compartment -p cloudbank-v5 --private
  ./1-create_oci_repos.sh -c my-compartment -p cloudbank-v5 --dry-run
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
check_prerequisites() {
    # Use the prereq library functions
    if ! prereq_check_oci; then
        return 1
    fi

    # Copy results from prereq library to local variables
    OCI_NAMESPACE="$PREREQ_OCI_NAMESPACE"
    OCI_REGION="$PREREQ_OCI_REGION"
    REGISTRY="$PREREQ_OCI_REGISTRY"

    return 0
}

validate_inputs() {
    local errors=0

    if [[ -z "$COMPARTMENT" ]]; then
        print_error "Compartment is required (-c/--compartment)"
        ((errors++))
    fi

    if [[ -z "$REPO_PREFIX" ]]; then
        print_error "Repository prefix is required (-p/--prefix)"
        ((errors++))
    fi

    if [[ $errors -gt 0 ]]; then
        echo ""
        show_help
        return 1
    fi

    return 0
}

lookup_compartment() {
    # Use the prereq library function
    if ! prereq_lookup_compartment "$COMPARTMENT"; then
        return 1
    fi

    # Copy result from prereq library to local variable
    COMPARTMENT_OCID="$PREREQ_COMPARTMENT_OCID"
    return 0
}

# =============================================================================
# Repository Creation
# =============================================================================
create_repositories() {
    print_header "Creating Container Repositories"

    local visibility="public"
    if [[ "$IS_PUBLIC" != true ]]; then
        visibility="private"
    fi

    local created=0
    local skipped=0
    local failed=0

    for service in "${SERVICES[@]}"; do
        local display_name="${REPO_PREFIX}/${service}"

        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would create $visibility repository: $display_name"
            continue
        fi

        print_step "Creating repository: $display_name"

        local result
        local exit_code
        result=$(oci artifacts container repository create \
            --compartment-id "$COMPARTMENT_OCID" \
            --display-name "$display_name" \
            --is-public "$IS_PUBLIC" 2>&1) || exit_code=$?

        if [[ ${exit_code:-0} -eq 0 ]]; then
            print_success "$display_name created"
            ((created++))
        else
            if echo "$result" | grep -q "already exists"; then
                print_warning "$display_name already exists (skipped)"
                ((skipped++))
            else
                print_error "Failed to create $display_name"
                print_info "$result"
                ((failed++))
            fi
        fi
    done

    echo ""
    if [[ "$DRY_RUN" == true ]]; then
        print_info "Dry run complete. No repositories were created."
    else
        print_info "Created: $created | Skipped: $skipped | Failed: $failed"
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    print_header "CloudBank v5 OCI Repository Creation"

    # Parse command line arguments
    parse_args "$@"

    # Check prerequisites first (this retrieves OCI_NAMESPACE, OCI_REGION, and builds REGISTRY)
    if ! check_prerequisites; then
        exit 1
    fi

    # Prompt for missing required values
    if [[ -z "$COMPARTMENT" ]]; then
        echo "Please provide the following configuration values."
        echo ""
        prompt_value COMPARTMENT "OCI compartment name" "my-compartment"
    fi

    if [[ -z "$REPO_PREFIX" ]]; then
        prompt_value REPO_PREFIX "Repository prefix" "cloudbank-v5"
    fi

    # Validate inputs
    if ! validate_inputs; then
        exit 1
    fi

    # Lookup compartment OCID
    if ! lookup_compartment; then
        exit 1
    fi

    # Build full registry path with prefix
    local full_registry="${REGISTRY}/${REPO_PREFIX}"

    # Show configuration
    print_header "Configuration"
    local visibility="public"
    if [[ "$IS_PUBLIC" != true ]]; then
        visibility="private"
    fi
    echo "  Compartment:  $COMPARTMENT"
    echo "  OCID:         $COMPARTMENT_OCID"
    echo "  Region:       $OCI_REGION (from OCI CLI config)"
    echo "  Namespace:    $OCI_NAMESPACE"
    echo "  Prefix:       $REPO_PREFIX"
    echo "  Registry:     $full_registry"
    echo "  Visibility:   $visibility"
    echo "  Dry Run:      $DRY_RUN"
    echo ""
    echo "  Services:     ${SERVICES[*]}"
    echo ""

    if [[ "$DRY_RUN" != true ]]; then
        read -p "Continue with repository creation? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Repository creation cancelled."
            exit 0
        fi
    fi

    # Create repositories
    create_repositories

    # Summary
    print_header "Summary"
    if [[ "$DRY_RUN" == true ]]; then
        print_info "Dry run complete. Run without --dry-run to create repositories."
    else
        print_success "Repository creation complete!"
        echo ""
        echo "Repositories:"
        for service in "${SERVICES[@]}"; do
            echo "  ${full_registry}/${service}"
        done
        echo ""
        echo "To list repositories:"
        echo "  oci artifacts container repository list --compartment-id $COMPARTMENT_OCID --query 'data.items[*].{\"name\":\"display-name\",\"is-public\":\"is-public\"}' --output table"
        echo ""
        echo "Next steps:"
        echo "  1. Login to registry: docker login ${OCI_REGION}.ocir.io"
        echo "  2. Build images: ./2-images_build_push.sh -p $REPO_PREFIX"
    fi
}

# Run main function
main "$@"
