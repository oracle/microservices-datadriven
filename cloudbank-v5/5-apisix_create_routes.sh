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
#   -d, --database DBNAME        OBaaS database name/prefix for azn-server auth secret
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
DB_NAME=""
DRY_RUN=false
port_forward_pid=""
APISIX_ADMIN_KEY=""
OIDC_CLIENT_ID="cloudbank-client"
OIDC_CLIENT_SECRET=""

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
            -d|--database)
                DB_NAME="$2"
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
  -d, --database DBNAME        OBaaS database name/prefix for azn-server auth secret
  --dry-run                    Show what would be done without doing it
  -h, --help                   Show this help message

Example:
  ./5-apisix_create_routes.sh -n obaas-dev
  ./5-apisix_create_routes.sh -n obaas-dev -o obaas
  ./5-apisix_create_routes.sh -n obaas-dev -o obaas -d obaas
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
    if [[ -n "$port_forward_pid" ]]; then
        print_step "Stopping port-forward..."
        kill "$port_forward_pid" 2>/dev/null || true
        wait "$port_forward_pid" 2>/dev/null || true
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
    port_forward_pid=$!

    # Wait for port-forward to be ready
    local attempt_count=0
    while ! curl --noproxy '*' -s http://localhost:9180 &>/dev/null; do
        sleep 1
        ((++attempt_count))
        if [[ $attempt_count -ge 30 ]]; then
            print_error "Port-forward failed to start after 30 seconds"
            return 1
        fi
    done

    print_success "Port-forward started (PID: $port_forward_pid)"
    return 0
}

get_oidc_client_secret() {
    local auth_secret_name="${DB_NAME}-azn-server-auth"

    print_step "Getting OAuth client secret from secret $auth_secret_name..."

    OIDC_CLIENT_SECRET=$(kubectl get secret "$auth_secret_name" -n "$NAMESPACE" \
        -o jsonpath='{.data.client-secret}' 2>/dev/null | base64 -d)

    if [[ -z "$OIDC_CLIENT_SECRET" ]]; then
        print_error "Could not read client-secret from secret $auth_secret_name"
        return 1
    fi

    print_success "OAuth client secret retrieved"
    return 0
}

oidc_plugin() {
    local required_scope="$1"

    cat << EOF
        "openid-connect": {
            "client_id": "$OIDC_CLIENT_ID",
            "client_secret": "$OIDC_CLIENT_SECRET",
            "discovery": "http://azn-server.${NAMESPACE}.svc.cluster.local:8080/.well-known/openid-configuration",
            "scope": "$required_scope",
            "required_scopes": [
                "$required_scope"
            ],
            "bearer_only": true,
            "unauth_action": "deny",
            "ssl_verify": false,
            "set_access_token_header": true,
            "access_token_in_authorization_header": true,
            "set_id_token_header": false,
            "set_userinfo_header": false,
            "set_refresh_token_header": false
        }
EOF
}

methods_json() {
    local json="["
    local delimiter=""
    local method

    for method in "$@"; do
        json+="${delimiter}\"${method}\""
        delimiter=","
    done

    json+="]"
    echo "$json"
}

create_route() {
    local route_id="$1"
    local route_name="$2"
    local uri_pattern="$3"
    local service_name="$4"
    local description="$5"
    local extra_plugins="${6:-}"
    local route_methods="${7:-[\"GET\",\"POST\",\"PUT\",\"DELETE\",\"OPTIONS\",\"HEAD\"]}"

    if [[ "$DRY_RUN" == true ]]; then
        if [[ -n "$extra_plugins" ]]; then
            print_info "[DRY-RUN] Would create protected route: $route_name ($route_methods $uri_pattern -> $service_name)"
        else
            print_info "[DRY-RUN] Would create public route: $route_name ($route_methods $uri_pattern -> $service_name)"
        fi
        return 0
    fi

    local temp_response_file
    temp_response_file=$(mktemp)

    local response_code
    local plugins_json
    plugins_json="        \"opentelemetry\": {
           \"sampler\": {
               \"name\": \"always_on\"
           }
        },
        \"prometheus\": {
            \"prefer_name\": true
        }"

    if [[ -n "$extra_plugins" ]]; then
        plugins_json="$plugins_json,
$extra_plugins"
    fi

    response_code=$(curl --noproxy '*' -s -w "%{http_code}" -o "$temp_response_file" "http://localhost:9180/apisix/admin/routes/$route_id" \
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
    \"methods\": $route_methods,
    \"upstream\": {
        \"service_name\": \"$service_name\",
        \"type\": \"roundrobin\",
        \"discovery_type\": \"eureka\"
    },
    \"plugins\": {
$plugins_json
    }
}")

    if [[ "$response_code" == "200" || "$response_code" == "201" ]]; then
        print_success "Created route: $route_name"
        rm -f "$temp_response_file"
        return 0
    else
        print_error "Failed to create route: $route_name (HTTP $response_code)"
        print_error "Response: $(cat "$temp_response_file")"
        rm -f "$temp_response_file"
        return 1
    fi
}

delete_route_if_present() {
    local route_id="$1"
    local route_name="$2"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would remove route if present: $route_name"
        return 0
    fi

    local temp_response_file
    temp_response_file=$(mktemp)

    local response_code
    response_code=$(curl --noproxy '*' -s -w "%{http_code}" -o "$temp_response_file" \
        "http://localhost:9180/apisix/admin/routes/$route_id" \
        -H "X-API-KEY: $APISIX_ADMIN_KEY" \
        -X DELETE)

    if [[ "$response_code" == "200" || "$response_code" == "202" || "$response_code" == "404" ]]; then
        print_success "Removed route if present: $route_name"
        rm -f "$temp_response_file"
        return 0
    else
        print_error "Failed to remove route: $route_name (HTTP $response_code)"
        print_error "Response: $(cat "$temp_response_file")"
        rm -f "$temp_response_file"
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

    # Define routes: id, name, uri_pattern, service_name, description, optional plugin JSON, optional methods JSON.
    create_route 999 "account-internal-journal-block" "/api/v1/account/journal*" "ACCOUNT" \
        "Block external access to internal account journal endpoints" "$(oidc_plugin cloudbank.external-denied)" || ((++errors))
    create_route 1000 "accounts-read" "/api/v1/account*" "ACCOUNT" "ACCOUNT read APIs" \
        "$(oidc_plugin cloudbank.read)" "$(methods_json GET HEAD)" || ((++errors))
    create_route 1001 "creditscore-read" "/api/v1/creditscore*" "CREDITSCORE" "CREDITSCORE read APIs" \
        "$(oidc_plugin cloudbank.read)" "$(methods_json GET HEAD)" || ((++errors))
    create_route 1002 "customer-read" "/api/v1/customer*" "CUSTOMER" "CUSTOMER read APIs" \
        "$(oidc_plugin cloudbank.read)" "$(methods_json GET HEAD)" || ((++errors))
    create_route 1003 "testrunner" "/api/v1/testrunner*" "TESTRUNNER" "TESTRUNNER Service" \
        "$(oidc_plugin cloudbank.test)" "$(methods_json POST)" || ((++errors))
    create_route 1004 "transfer" "/transfer" "TRANSFER" "TRANSFER Service" \
        "$(oidc_plugin cloudbank.transfer)" "$(methods_json POST)" || ((++errors))
    create_route 1005 "account-write" "/api/v1/account" "ACCOUNT" "ACCOUNT write APIs" \
        "$(oidc_plugin cloudbank.write)" "$(methods_json POST)" || ((++errors))
    create_route 1006 "account-admin" "/api/v1/account*" "ACCOUNT" "ACCOUNT admin APIs" \
        "$(oidc_plugin cloudbank.admin)" "$(methods_json DELETE)" || ((++errors))
    create_route 1007 "customer-write" "/api/v1/customer*" "CUSTOMER" "CUSTOMER write APIs" \
        "$(oidc_plugin cloudbank.write)" "$(methods_json POST PUT)" || ((++errors))
    create_route 1008 "customer-admin" "/api/v1/customer*" "CUSTOMER" "CUSTOMER admin APIs" \
        "$(oidc_plugin cloudbank.admin)" "$(methods_json DELETE)" || ((++errors))
    create_route 1010 "azn-metadata" "/.well-known/*" "AZN-SERVER" "Authorization Server Metadata" || ((++errors))
    create_route 1011 "azn-oauth2" "/oauth2/*" "AZN-SERVER" "Authorization Server OAuth2 Endpoints" || ((++errors))
    delete_route_if_present 1012 "azn-user-api" || ((++errors))

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

    if [[ -z "$DB_NAME" ]]; then
        DB_NAME="$OBAAS_RELEASE"
    fi

    # Get APISIX admin key
    if ! get_apisix_admin_key; then
        exit 1
    fi

    # Show configuration
    print_header "Configuration"
    echo "  Namespace:     $NAMESPACE"
    echo "  OBaaS Release: $OBAAS_RELEASE"
    echo "  Database:      $DB_NAME"
    echo "  Dry Run:       $DRY_RUN"
    echo ""

    if [[ "$DRY_RUN" != true ]]; then
        if ! get_oidc_client_secret; then
            exit 1
        fi
    fi

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
        echo "  curl -s http://<apisix-gateway>/.well-known/oauth-authorization-server"
        echo "  curl -s -H 'Authorization: Bearer <token>' http://<apisix-gateway>/api/v1/creditscore"
    fi
}

# Run main function
main "$@"
