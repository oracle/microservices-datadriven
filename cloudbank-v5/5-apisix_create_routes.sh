#!/bin/bash
# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

# CloudBank v5 APISIX Routes Script
# Creates APISIX routes for all CloudBank microservices.
#
# Usage:
#   ./5-apisix_create_routes.sh [options]
#
# Options:
#   -n, --namespace NAMESPACE    Kubernetes namespace (required)
#   -o, --obaas-release RELEASE  OBaaS platform release name (auto-detected if not provided)
#   --dry-run                    Show what would be done without doing it
#   -h, --help                   Show this help message
#
# Example:
#   ./5-apisix_create_routes.sh -n obaas-dev

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
NAMESPACE=""
OBAAS_RELEASE=""
DRY_RUN=false
PORT_FORWARD_PID=""

# =============================================================================
# Parse Arguments
# =============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -o|--obaas-release)
                OBAAS_RELEASE="$2"
                shift 2
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
CloudBank v5 APISIX Routes Script

Creates APISIX routes for all CloudBank microservices.

Usage:
  ./5-apisix_create_routes.sh [options]

Options:
  -n, --namespace NAMESPACE    Kubernetes namespace (required)
  -o, --obaas-release RELEASE  OBaaS platform release name (auto-detected if not provided)
  --dry-run                    Show what would be done without doing it
  -h, --help                   Show this help message

Example:
  ./5-apisix_create_routes.sh -n obaas-dev
  ./5-apisix_create_routes.sh -n obaas-dev -o obaas
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
# Cleanup
# =============================================================================
cleanup() {
    if [[ -n "$PORT_FORWARD_PID" ]]; then
        print_step "Stopping port-forward..."
        kill "$PORT_FORWARD_PID" 2>/dev/null || true
        wait "$PORT_FORWARD_PID" 2>/dev/null || true
        print_success "Port-forward stopped"
    fi
}

trap cleanup EXIT

# =============================================================================
# APISIX Functions
# =============================================================================
get_apisix_admin_key() {
    local configmap_name="${OBAAS_RELEASE}-apisix"

    print_step "Getting APISIX admin key from configmap $configmap_name..."

    # Get the config.yaml from the configmap
    local config_yaml
    config_yaml=$(kubectl get configmap "$configmap_name" -n "$NAMESPACE" -o jsonpath='{.data.config\.yaml}' 2>/dev/null)

    if [[ -z "$config_yaml" ]]; then
        print_error "Could not get config.yaml from configmap $configmap_name"
        return 1
    fi

    # Parse YAML to find admin key using portable bash
    # Looking for: - name: "admin" followed by key: <value>
    local found_admin=false
    while IFS= read -r line; do
        if [[ "$line" == *'name:'*'"admin"'* ]] || [[ "$line" == *"name:"*"'admin'"* ]] || [[ "$line" == *'name: admin'* ]]; then
            found_admin=true
        elif [[ "$found_admin" == true ]] && [[ "$line" == *'key:'* ]]; then
            # Extract key value - remove "key:" prefix and any quotes/whitespace
            APISIX_ADMIN_KEY="${line#*key:}"
            APISIX_ADMIN_KEY="${APISIX_ADMIN_KEY# }"      # trim leading space
            APISIX_ADMIN_KEY="${APISIX_ADMIN_KEY%% *}"   # trim trailing content
            APISIX_ADMIN_KEY="${APISIX_ADMIN_KEY//\"/}"  # remove double quotes
            APISIX_ADMIN_KEY="${APISIX_ADMIN_KEY//\'/}"  # remove single quotes
            break
        fi
    done <<< "$config_yaml"

    if [[ -z "$APISIX_ADMIN_KEY" ]]; then
        print_error "Could not extract APISIX admin key from configmap $configmap_name"
        return 1
    fi

    print_success "APISIX admin key retrieved"
    return 0
}

start_port_forward() {
    local service_name="${OBAAS_RELEASE}-apisix-admin"

    print_step "Starting port-forward to $service_name:9180..."

    kubectl port-forward -n "$NAMESPACE" "svc/$service_name" 9180:9180 &>/dev/null &
    PORT_FORWARD_PID=$!

    # Wait for port-forward to be ready
    local attempts=0
    while ! curl -s http://localhost:9180 &>/dev/null; do
        sleep 1
        ((attempts++))
        if [[ $attempts -ge 30 ]]; then
            print_error "Port-forward failed to start after 30 seconds"
            return 1
        fi
    done

    print_success "Port-forward started (PID: $PORT_FORWARD_PID)"
    return 0
}

create_route() {
    local route_id="$1"
    local route_name="$2"
    local uri_pattern="$3"
    local service_name="$4"
    local description="$5"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would create route: $route_name ($uri_pattern -> $service_name)"
        return 0
    fi

    local response_file
    response_file=$(mktemp)

    local http_code
    http_code=$(curl -s -w "%{http_code}" -o "$response_file" "http://localhost:9180/apisix/admin/routes/$route_id" \
        -H "X-API-KEY: $APISIX_ADMIN_KEY" \
        -H "Content-Type: application/json" \
        -X PUT \
        -d "{
    \"name\": \"$route_name\",
    \"labels\": {
        \"version\": \"1.0\"
    },
    \"desc\": \"$description\",
    \"uri\": \"$uri_pattern\",
    \"methods\": [
        \"GET\",
        \"POST\",
        \"PUT\",
        \"DELETE\",
        \"OPTIONS\",
        \"HEAD\"
    ],
    \"upstream\": {
        \"service_name\": \"$service_name\",
        \"type\": \"roundrobin\",
        \"discovery_type\": \"eureka\"
    },
    \"plugins\": {
        \"opentelemetry\": {
           \"sampler\": {
               \"name\": \"always_on\"
           }
        },
        \"prometheus\": {
            \"prefer_name\": true
        }
    }
}")

    if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
        print_success "Created route: $route_name"
        rm -f "$response_file"
        return 0
    else
        print_error "Failed to create route: $route_name (HTTP $http_code)"
        print_error "Response: $(cat "$response_file")"
        rm -f "$response_file"
        return 1
    fi
}

create_all_routes() {
    print_header "Creating APISIX Routes"

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "DRY RUN MODE - No routes will be created"
        echo ""
    fi

    local errors=0

    # Define routes: id, name, uri_pattern, service_name, description
    create_route 1000 "accounts" "/api/v1/account*" "ACCOUNT" "ACCOUNT Service" || ((errors++))
    create_route 1001 "creditscore" "/api/v1/creditscore*" "CREDITSCORE" "CREDITSCORE Service" || ((errors++))
    create_route 1002 "customer" "/api/v1/customer*" "CUSTOMER" "CUSTOMER Service" || ((errors++))
    create_route 1003 "testrunner" "/api/v1/testrunner*" "TESTRUNNER" "TESTRUNNER Service" || ((errors++))
    create_route 1004 "transfer" "/api/v1/transfer*" "TRANSFER" "TRANSFER Service" || ((errors++))

    if [[ $errors -gt 0 ]]; then
        print_error "$errors route(s) failed to create"
        return 1
    fi

    return 0
}

# =============================================================================
# Main
# =============================================================================
main() {
    print_header "CloudBank v5 APISIX Routes"

    # Parse command line arguments
    parse_args "$@"

    # Prompt for missing required values
    if [[ -z "$NAMESPACE" ]]; then
        echo "Please provide the following configuration values."
        echo ""
        prompt_value NAMESPACE "Kubernetes namespace" "obaas-dev"
    fi

    # Check prerequisites
    print_step "Checking prerequisites..."
    if ! prereq_check_kubectl; then
        exit 1
    fi

    if ! prereq_check_namespace "$NAMESPACE"; then
        exit 1
    fi

    # Auto-detect OBaaS release if not provided
    if [[ -z "$OBAAS_RELEASE" ]]; then
        print_step "Auto-detecting OBaaS release..."
        if prereq_check_obaas_release "$NAMESPACE"; then
            OBAAS_RELEASE="$PREREQ_OBAAS_RELEASE"
        else
            print_error "Could not auto-detect OBaaS release. Use -o/--obaas-release to specify."
            exit 1
        fi
    fi

    # Get APISIX admin key
    if ! get_apisix_admin_key; then
        exit 1
    fi

    # Show configuration
    print_header "Configuration"
    echo "  Namespace:     $NAMESPACE"
    echo "  OBaaS Release: $OBAAS_RELEASE"
    echo "  Dry Run:       $DRY_RUN"
    echo ""

    # Start port-forward (unless dry-run)
    if [[ "$DRY_RUN" != true ]]; then
        if ! start_port_forward; then
            exit 1
        fi
    fi

    # Create routes
    if ! create_all_routes; then
        exit 1
    fi

    # Summary
    print_header "Summary"
    if [[ "$DRY_RUN" == true ]]; then
        print_info "Dry run complete. Run without --dry-run to create routes."
    else
        print_success "All routes created successfully!"
        echo ""
        echo "Test with:"
        echo "  curl -s http://<apisix-gateway>/api/v1/testrunner/ping"
    fi
}

# Run main function
main "$@"
