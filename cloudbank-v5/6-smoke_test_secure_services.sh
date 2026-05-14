#!/bin/bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

# CloudBank v5 Secure Services Smoke Test Script
# Verifies APISIX routes, OAuth2 token issuance, endpoint authorization, and
# the main secured CloudBank workflows.

set -e

# =============================================================================
# Script Directory and Prerequisites Library
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=check_prereqs.sh
source "${SCRIPT_DIR}/check_prereqs.sh"

# =============================================================================
# Variables
# =============================================================================
NAMESPACE=""
OBAAS_RELEASE=""
DB_NAME=""
GATEWAY_URL=""
LOCAL_PORT="9080"
KEEP_PORT_FORWARD=false
READ_ONLY=false
FROM_ACCOUNT_ID=""
TO_ACCOUNT_ID=""
CLIENT_ID="cloudbank-client"
CLIENT_SECRET=""
TEST_CLIENT_ID="cloudbank-test-client"
TEST_CLIENT_SECRET=""
READ_TOKEN=""
TEST_TOKEN=""
TRANSFER_TOKEN=""
PORT_FORWARD_PID=""
FAILURES=0

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
            --gateway-url)
                GATEWAY_URL="$2"
                shift 2
                ;;
            --local-port)
                LOCAL_PORT="$2"
                shift 2
                ;;
            --from-account)
                FROM_ACCOUNT_ID="$2"
                shift 2
                ;;
            --to-account)
                TO_ACCOUNT_ID="$2"
                shift 2
                ;;
            --read-only)
                READ_ONLY=true
                shift
                ;;
            --keep-port-forward)
                KEEP_PORT_FORWARD=true
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
CloudBank v5 Secure Services Smoke Test Script

Verifies secured CloudBank services through APISIX.

Usage:
  ./6-smoke_test_secure_services.sh [options]

Options:
  -n, --namespace NAMESPACE      Kubernetes namespace (required)
  -o, --obaas-release RELEASE    OBaaS platform release name (auto-detected if not provided)
  -d, --database DBNAME          OBaaS database name/prefix for azn-server auth secret
  --gateway-url URL              Existing APISIX gateway URL, for example http://example.com
  --local-port PORT              Local port for APISIX port-forward (default: 9080)
  --from-account ACCOUNT_ID      Source account for transfer test
  --to-account ACCOUNT_ID        Destination account for deposit/transfer tests
  --read-only                    Skip mutating deposit and transfer tests
  --keep-port-forward            Leave the temporary port-forward running
  -h, --help                     Show this help message

Examples:
  ./6-smoke_test_secure_services.sh -n obaas-dev -o obaas -d obaas
  ./6-smoke_test_secure_services.sh -n obaas-dev -d obaas --read-only
  ./6-smoke_test_secure_services.sh -n obaas-dev -d obaas --gateway-url http://localhost:9080
EOF
}

# =============================================================================
# Prompt, Cleanup, and Prerequisites
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
            printf -v "$var_name" '%s' "$value"
            return 0
        fi
        print_error "Value is required. Please enter a value."
    done
}

cleanup() {
    if [[ -n "$PORT_FORWARD_PID" && "$KEEP_PORT_FORWARD" != true ]]; then
        print_step "Stopping APISIX gateway port-forward..."
        kill "$PORT_FORWARD_PID" 2>/dev/null || true
        wait "$PORT_FORWARD_PID" 2>/dev/null || true
        print_success "Port-forward stopped"
    elif [[ -n "$PORT_FORWARD_PID" ]]; then
        print_warning "Leaving APISIX gateway port-forward running (PID: $PORT_FORWARD_PID)"
    fi
}

trap cleanup EXIT

check_prerequisites() {
    print_step "Checking prerequisites..."

    local errors=0
    if ! prereq_check_kubectl; then
        ((++errors))
    fi
    if ! prereq_check_namespace "$NAMESPACE"; then
        ((++errors))
    fi
    if ! command -v curl &>/dev/null; then
        print_error "curl is required"
        ((++errors))
    else
        print_success "curl is available"
    fi
    if ! command -v jq &>/dev/null; then
        print_error "jq is required"
        ((++errors))
    else
        print_success "jq is available"
    fi

    return "$errors"
}

# =============================================================================
# Gateway and Token Helpers
# =============================================================================
start_gateway_port_forward() {
    local service_name="${OBAAS_RELEASE}-apisix-gateway"

    print_step "Starting APISIX gateway port-forward to $service_name on localhost:$LOCAL_PORT..."
    kubectl port-forward -n "$NAMESPACE" "svc/$service_name" "${LOCAL_PORT}:80" &>/dev/null &
    PORT_FORWARD_PID=$!

    local attempt_count=0
    while ! curl --noproxy '*' -s "http://127.0.0.1:${LOCAL_PORT}/.well-known/oauth-authorization-server" &>/dev/null; do
        sleep 1
        ((++attempt_count))
        if [[ $attempt_count -ge 60 ]]; then
            print_error "APISIX gateway port-forward did not become ready"
            return 1
        fi
    done

    GATEWAY_URL="http://127.0.0.1:${LOCAL_PORT}"
    print_success "APISIX gateway is reachable at $GATEWAY_URL"
}

get_client_secret() {
    local auth_secret_name="${DB_NAME}-azn-server-auth"

    print_step "Reading OAuth client secrets from $auth_secret_name..."
    CLIENT_SECRET=$(kubectl get secret "$auth_secret_name" -n "$NAMESPACE" \
        -o jsonpath='{.data.client-secret}' 2>/dev/null | base64 -d)
    TEST_CLIENT_SECRET=$(kubectl get secret "$auth_secret_name" -n "$NAMESPACE" \
        -o jsonpath='{.data.test-client-secret}' 2>/dev/null | base64 -d)

    if [[ -z "$CLIENT_SECRET" ]]; then
        print_error "Could not read client-secret from secret $auth_secret_name"
        return 1
    fi
    if [[ -z "$TEST_CLIENT_SECRET" ]]; then
        print_error "Could not read test-client-secret from secret $auth_secret_name"
        return 1
    fi

    print_success "OAuth client secrets are available"
}

get_token() {
    local scope="$1"
    local client_id="${2:-$CLIENT_ID}"
    local client_secret="${3:-$CLIENT_SECRET}"
    local token

    token=$(curl --noproxy '*' -s -u "${client_id}:${client_secret}" \
        -X POST "${GATEWAY_URL}/oauth2/token" \
        -d grant_type=client_credentials \
        -d "scope=${scope}" | jq -r '.access_token // empty')

    if [[ -z "$token" ]]; then
        print_error "Could not get token for scope: $scope"
        return 1
    fi

    echo "$token"
}

get_tokens() {
    print_step "Requesting scoped OAuth tokens..."
    READ_TOKEN=$(get_token "cloudbank.read")
    TEST_TOKEN=$(get_token "cloudbank.test" "$TEST_CLIENT_ID" "$TEST_CLIENT_SECRET")
    TRANSFER_TOKEN=$(get_token "cloudbank.transfer")
    print_success "Scoped OAuth tokens issued"
}

# =============================================================================
# Test Helpers
# =============================================================================
record_result() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == "$expected" ]]; then
        print_success "$test_name returned $actual"
    else
        print_error "$test_name returned $actual, expected $expected"
        ((++FAILURES))
    fi
}

request_status() {
    local output_file="$1"
    shift
    curl --noproxy '*' -s -o "$output_file" -w '%{http_code}' "$@"
}

discover_account_ids() {
    if [[ -n "$FROM_ACCOUNT_ID" && -n "$TO_ACCOUNT_ID" ]]; then
        print_success "Using provided account IDs: from=$FROM_ACCOUNT_ID to=$TO_ACCOUNT_ID"
        return 0
    fi

    print_step "Discovering valid account IDs..."
    local status_code
    status_code=$(request_status /tmp/cloudbank-smoke-accounts.json \
        -H "Authorization: Bearer ${READ_TOKEN}" \
        "${GATEWAY_URL}/api/v1/accounts")
    record_result "Account list with read token" "200" "$status_code"

    if [[ "$status_code" != "200" ]]; then
        return 1
    fi

    if [[ -z "$FROM_ACCOUNT_ID" ]]; then
        FROM_ACCOUNT_ID=$(jq -r '[.[] | select((.accountBalance // 0) > 1) | .accountId][0] // empty' \
            /tmp/cloudbank-smoke-accounts.json)
    fi

    if [[ -z "$TO_ACCOUNT_ID" ]]; then
        TO_ACCOUNT_ID=$(jq -r --argjson from "${FROM_ACCOUNT_ID:-0}" \
            '[.[] | select(.accountId != $from) | .accountId][0] // empty' \
            /tmp/cloudbank-smoke-accounts.json)
    fi

    if [[ -z "$FROM_ACCOUNT_ID" || -z "$TO_ACCOUNT_ID" ]]; then
        print_error "Could not discover two valid account IDs"
        ((++FAILURES))
        return 1
    fi

    print_success "Discovered account IDs: from=$FROM_ACCOUNT_ID to=$TO_ACCOUNT_ID"
}

run_smoke_tests() {
    print_header "Running Smoke Tests"

    local status_code

    status_code=$(request_status /tmp/cloudbank-smoke-metadata.json \
        "${GATEWAY_URL}/.well-known/oauth-authorization-server")
    record_result "Authorization metadata without token" "200" "$status_code"

    status_code=$(request_status /tmp/cloudbank-smoke-jwks.json \
        "${GATEWAY_URL}/oauth2/jwks")
    record_result "Authorization JWK set without token" "200" "$status_code"
    if [[ "$status_code" == "200" ]]; then
        local signing_key_id
        signing_key_id=$(jq -r '.keys[0].kid // empty' /tmp/cloudbank-smoke-jwks.json)
        if [[ -n "$signing_key_id" ]]; then
            print_success "Authorization JWK set exposes a signing key id"
        else
            print_error "Authorization JWK set did not expose a signing key id"
            ((++FAILURES))
        fi
    fi

    status_code=$(request_status /tmp/cloudbank-smoke-creditscore-anon.json \
        "${GATEWAY_URL}/api/v1/creditscore")
    record_result "Creditscore without token" "401" "$status_code"

    status_code=$(request_status /tmp/cloudbank-smoke-creditscore-read.json \
        -H "Authorization: Bearer ${READ_TOKEN}" \
        "${GATEWAY_URL}/api/v1/creditscore")
    record_result "Creditscore with read token" "200" "$status_code"

    status_code=$(request_status /tmp/cloudbank-smoke-user-api.json \
        "${GATEWAY_URL}/user/api/v1/ping")
    record_result "Azn-server user API not externally routed" "404" "$status_code"

    status_code=$(request_status /tmp/cloudbank-smoke-internal-journal.json \
        -X POST \
        -H "Authorization: Bearer ${READ_TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{"journalId":999999999,"accountId":1,"journalType":"DEPOSIT","journalAmount":1}' \
        "${GATEWAY_URL}/api/v1/account/journal")
    record_result "Internal account journal route with read token" "403" "$status_code"

    discover_account_ids || true

    if [[ "$READ_ONLY" == true ]]; then
        print_warning "Read-only mode: skipping deposit and transfer workflow tests"
        return 0
    fi

    status_code=$(request_status /tmp/cloudbank-smoke-deposit-read.json \
        -X POST \
        -H "Authorization: Bearer ${READ_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"accountId\":${TO_ACCOUNT_ID},\"amount\":1}" \
        "${GATEWAY_URL}/api/v1/testrunner/deposit")
    record_result "Testrunner deposit with read token" "403" "$status_code"

    status_code=$(request_status /tmp/cloudbank-smoke-deposit-test.json \
        -X POST \
        -H "Authorization: Bearer ${TEST_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"accountId\":${TO_ACCOUNT_ID},\"amount\":1}" \
        "${GATEWAY_URL}/api/v1/testrunner/deposit")
    record_result "Testrunner deposit with test token" "201" "$status_code"

    status_code=$(request_status /tmp/cloudbank-smoke-transfer.json \
        -X POST \
        -H "Authorization: Bearer ${TRANSFER_TOKEN}" \
        "${GATEWAY_URL}/transfer?fromAccount=${FROM_ACCOUNT_ID}&toAccount=${TO_ACCOUNT_ID}&amount=1")
    record_result "Transfer with transfer token" "200" "$status_code"
}

# =============================================================================
# Main
# =============================================================================
main() {
    print_header "CloudBank v5 Secure Services Smoke Test"

    parse_args "$@"

    if [[ -z "$NAMESPACE" || -z "$DB_NAME" ]]; then
        echo "Please provide the following configuration values."
        echo ""
        prompt_value NAMESPACE "Kubernetes namespace" "obaas-dev"
        prompt_value DB_NAME "Database name" "obaas"
    fi

    if ! check_prerequisites; then
        exit 1
    fi

    if [[ -z "$OBAAS_RELEASE" ]]; then
        print_step "Auto-detecting OBaaS release..."
        if prereq_check_obaas_release "$NAMESPACE"; then
            OBAAS_RELEASE="$PREREQ_OBAAS_RELEASE"
        else
            print_error "Could not auto-detect OBaaS release. Use -o/--obaas-release to specify."
            exit 1
        fi
    fi

    if [[ -z "$GATEWAY_URL" ]]; then
        start_gateway_port_forward
    else
        GATEWAY_URL="${GATEWAY_URL%/}"
        print_success "Using gateway URL: $GATEWAY_URL"
    fi

    get_client_secret
    get_tokens
    run_smoke_tests

    print_header "Summary"
    if [[ "$FAILURES" -eq 0 ]]; then
        print_success "Secure services smoke test passed"
    else
        print_error "Secure services smoke test failed: $FAILURES failure(s)"
        exit 1
    fi
}

main "$@"
