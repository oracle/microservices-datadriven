#!/bin/bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

# CloudBank v5 All Services Test Script
# Verifies Kubernetes readiness, direct actuator health, APISIX/OAuth routing,
# endpoint authorization, and the main account/customer/check/transfer workflows.

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
LOCAL_PORT="19080"
AUTH_LOCAL_PORT="19081"
SERVICE_BASE_PORT="19100"
KEEP_PORT_FORWARD=false
READ_ONLY=false
FROM_ACCOUNT_ID=""
TO_ACCOUNT_ID=""
# Owner is the seeded CloudBank customer/account user used for ownership-scoped API tests.
OWNER_USERNAME="qwertysdwr"
# Keep empty by default so no cleartext password is stored in the script.
OWNER_PASSWORD=""
CLIENT_ID="cloudbank-client"
CLIENT_SECRET=""
TEST_CLIENT_ID="cloudbank-test-client"
TEST_CLIENT_SECRET=""
ADMIN_PASSWORD=""
READ_TOKEN=""
WRITE_TOKEN=""
TEST_TOKEN=""
TRANSFER_TOKEN=""
OWNER_TOKEN=""
PORT_FORWARD_PIDS=""
TMP_DIR=""
PASS_COUNT=0
FAILURES=0
LAST_OUT=""

SERVICES="azn-server account customer creditscore checks transfer testrunner"

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
            --auth-local-port)
                AUTH_LOCAL_PORT="$2"
                shift 2
                ;;
            --service-base-port)
                SERVICE_BASE_PORT="$2"
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
            --owner-username)
                OWNER_USERNAME="$2"
                shift 2
                ;;
            --owner-password)
                OWNER_PASSWORD="$2"
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
CloudBank v5 All Services Test Script

Verifies all deployed CloudBank services through Kubernetes, direct actuator
health checks, APISIX, OAuth2, and service workflows.

Usage:
  ./7-test_all_services.sh [options]

Options:
  -n, --namespace NAMESPACE       Kubernetes namespace (required)
  -o, --obaas-release RELEASE     OBaaS platform release name (auto-detected if not provided)
  -d, --database DBNAME           OBaaS database name/prefix for azn-server auth secret
  --gateway-url URL               Existing APISIX gateway URL, for example http://localhost:19080
  --local-port PORT               Local port for APISIX port-forward (default: 19080)
  --auth-local-port PORT          Local port for azn-server auth-code flow (default: 19081)
  --service-base-port PORT        First local port for direct service health checks (default: 19100)
  --from-account ACCOUNT_ID       Source account owned by --owner-username for transfer test
  --to-account ACCOUNT_ID         Destination account owned by --owner-username for deposit/transfer tests
  --owner-username USERNAME       Seeded customer/account owner username (default: qwertysdwr)
  --owner-password PASSWORD       Password to create/reset for owner username (default: generated at runtime)
  --read-only                     Skip mutating check deposit, check clear, and transfer tests
  --keep-port-forward             Leave the APISIX gateway port-forward running
  -h, --help                      Show this help message

Examples:
  ./7-test_all_services.sh -n obaas -d helmtest
  ./7-test_all_services.sh -n obaas -o obaas -d helmtest --read-only
  ./7-test_all_services.sh -n obaas -d helmtest --gateway-url http://localhost:19080
EOF
}

# =============================================================================
# Prompt, Cleanup, and Result Helpers
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
    local pid
    for pid in $PORT_FORWARD_PIDS; do
        if [[ "$KEEP_PORT_FORWARD" == true && "$pid" == "${GATEWAY_PORT_FORWARD_PID:-}" ]]; then
            print_warning "Leaving APISIX gateway port-forward running (PID: $pid)"
            continue
        fi
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    done
    if [[ -n "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}

trap cleanup EXIT

record_pass() {
    local test_name="$1"
    local detail="$2"
    ((++PASS_COUNT))
    print_success "$(printf '%-42s %s' "$test_name" "$detail")"
}

record_failure() {
    local test_name="$1"
    local detail="$2"
    ((++FAILURES))
    print_error "$(printf '%-42s %s' "$test_name" "$detail")"
}

record_status() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == "$expected" ]]; then
        record_pass "$test_name" "HTTP $actual"
    else
        local body=""
        if [[ -n "$LAST_OUT" && -f "$LAST_OUT" ]]; then
            body=$(head -c 300 "$LAST_OUT")
        fi
        record_failure "$test_name" "HTTP $actual expected $expected; body=$body"
    fi
}

request_status() {
    local output_file="$1"
    shift
    curl --noproxy '*' -sS -o "$output_file" -w '%{http_code}' "$@"
}

wait_for_url() {
    local url="$1"
    local i

    for i in $(seq 1 60); do
        if curl --noproxy '*' -fsS "$url" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    return 1
}

url_encode() {
    jq -rn --arg value "$1" '$value|@uri'
}

# Generates a one-run owner password for OAuth login and password reset.
generate_owner_password() {
    local random_part
    random_part=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24)
    printf 'Cbv5-%s9!' "$random_part"
}

# =============================================================================
# Prerequisites and Port Forwarding
# =============================================================================
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
    if ! command -v openssl &>/dev/null; then
        print_error "openssl is required"
        ((++errors))
    else
        print_success "openssl is available"
    fi

    return "$errors"
}

start_port_forward() {
    local service_name="$1"
    local local_port="$2"
    local service_port="$3"
    local log_file="$4"
    local pid

    kubectl -n "$NAMESPACE" port-forward "svc/$service_name" "${local_port}:${service_port}" >"$log_file" 2>&1 &
    pid=$!
    PORT_FORWARD_PIDS="$PORT_FORWARD_PIDS $pid"
    echo "$pid"
}

stop_port_forward() {
    local pid="$1"
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    PORT_FORWARD_PIDS=$(printf '%s' "$PORT_FORWARD_PIDS" | sed "s/ $pid//")
}

start_gateway_port_forward() {
    local service_name="${OBAAS_RELEASE}-apisix-gateway"
    local log_file="$TMP_DIR/pf-gateway.log"

    print_step "Starting APISIX gateway port-forward to $service_name on localhost:$LOCAL_PORT..."
    GATEWAY_PORT_FORWARD_PID=$(start_port_forward "$service_name" "$LOCAL_PORT" "80" "$log_file")

    if ! wait_for_url "http://127.0.0.1:${LOCAL_PORT}/.well-known/oauth-authorization-server"; then
        record_failure "gateway" "not reachable; $(tail -n 5 "$log_file" | tr '\n' ' ')"
        return 1
    fi

    GATEWAY_URL="http://127.0.0.1:${LOCAL_PORT}"
    record_pass "gateway" "$GATEWAY_URL reachable"
}

start_auth_port_forward() {
    local log_file="$TMP_DIR/pf-azn-auth.log"

    print_step "Starting azn-server port-forward on localhost:$AUTH_LOCAL_PORT for owner OAuth flow..."
    AZN_PORT_FORWARD_PID=$(start_port_forward "azn-server" "$AUTH_LOCAL_PORT" "8080" "$log_file")

    if ! wait_for_url "http://127.0.0.1:${AUTH_LOCAL_PORT}/login"; then
        record_failure "azn auth port-forward" "not reachable; $(tail -n 5 "$log_file" | tr '\n' ' ')"
        return 1
    fi

    record_pass "azn auth port-forward" "http://127.0.0.1:$AUTH_LOCAL_PORT reachable"
}

# =============================================================================
# Test Groups
# =============================================================================
test_rollouts() {
    print_header "Kubernetes Workload Readiness"

    local service
    for service in $SERVICES; do
        if kubectl -n "$NAMESPACE" rollout status "deploy/$service" --timeout=90s >/dev/null 2>&1; then
            record_pass "rollout/$service" "available"
        else
            record_failure "rollout/$service" "not available"
        fi
    done
}

test_direct_health() {
    print_header "Direct Actuator Health Checks"

    local service
    local port="$SERVICE_BASE_PORT"
    for service in $SERVICES; do
        local log_file="$TMP_DIR/pf-$service.log"
        local pid
        pid=$(start_port_forward "$service" "$port" "8080" "$log_file")

        if wait_for_url "http://127.0.0.1:${port}/actuator/health"; then
            LAST_OUT="$TMP_DIR/health-$service.json"
            local status_code
            status_code=$(request_status "$LAST_OUT" "http://127.0.0.1:${port}/actuator/health")
            if [[ "$status_code" == "200" ]] && jq -e '.status == "UP"' "$LAST_OUT" >/dev/null 2>&1; then
                record_pass "health/$service" "UP"
            else
                record_failure "health/$service" "HTTP $status_code body=$(cat "$LAST_OUT" 2>/dev/null)"
            fi
        else
            record_failure "health/$service" "port-forward or health endpoint not ready; $(tail -n 3 "$log_file" | tr '\n' ' ')"
        fi

        stop_port_forward "$pid"
        ((++port))
    done
}

get_client_secrets() {
    local auth_secret_name="${DB_NAME}-azn-server-auth"

    CLIENT_SECRET=$(kubectl get secret "$auth_secret_name" -n "$NAMESPACE" \
        -o jsonpath='{.data.client-secret}' 2>/dev/null | base64 -d)
    TEST_CLIENT_SECRET=$(kubectl get secret "$auth_secret_name" -n "$NAMESPACE" \
        -o jsonpath='{.data.test-client-secret}' 2>/dev/null | base64 -d)
    ADMIN_PASSWORD=$(kubectl get secret "$auth_secret_name" -n "$NAMESPACE" \
        -o jsonpath='{.data.admin-password}' 2>/dev/null | base64 -d)

    if [[ -n "$CLIENT_SECRET" && -n "$TEST_CLIENT_SECRET" && -n "$ADMIN_PASSWORD" ]]; then
        record_pass "oauth secret" "$auth_secret_name readable"
    else
        record_failure "oauth secret" "missing client-secret, test-client-secret, or admin-password"
        return 1
    fi
}

get_token() {
    local scope="$1"
    local client_id="${2:-$CLIENT_ID}"
    local client_secret="${3:-$CLIENT_SECRET}"

    curl --noproxy '*' -sS -u "${client_id}:${client_secret}" \
        -X POST "${GATEWAY_URL}/oauth2/token" \
        -d grant_type=client_credentials \
        -d "scope=${scope}" | jq -r '.access_token // empty'
}

auth_base_url() {
    printf 'http://127.0.0.1:%s' "$AUTH_LOCAL_PORT"
}

ensure_owner_user() {
    local base
    local create_payload
    local update_payload
    local status_code

    base=$(auth_base_url)
    create_payload=$(jq -n \
        --arg username "$OWNER_USERNAME" \
        --arg password "$OWNER_PASSWORD" \
        --arg email "${OWNER_USERNAME}@example.invalid" \
        '{username:$username,password:$password,roles:"ROLE_USER",email:$email}')

    LAST_OUT="$TMP_DIR/owner-user-create.json"
    status_code=$(request_status "$LAST_OUT" \
        -u "obaas-admin:${ADMIN_PASSWORD}" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$create_payload" \
        "${base}/user/api/v1/createUser")

    if [[ "$status_code" == "201" ]]; then
        record_pass "owner user" "$OWNER_USERNAME created"
        return 0
    fi

    if [[ "$status_code" != "409" ]]; then
        record_failure "owner user" "create returned HTTP $status_code body=$(cat "$LAST_OUT" 2>/dev/null)"
        return 1
    fi

    update_payload=$(jq -n \
        --arg username "$OWNER_USERNAME" \
        --arg password "$OWNER_PASSWORD" \
        '{username:$username,password:$password}')

    LAST_OUT="$TMP_DIR/owner-user-password.json"
    status_code=$(request_status "$LAST_OUT" \
        -u "obaas-admin:${ADMIN_PASSWORD}" \
        -H "Content-Type: application/json" \
        -X PUT \
        -d "$update_payload" \
        "${base}/user/api/v1/updatePassword")

    if [[ "$status_code" == "200" ]]; then
        record_pass "owner user" "$OWNER_USERNAME exists; password reset"
    else
        record_failure "owner user" "password reset returned HTTP $status_code body=$(cat "$LAST_OUT" 2>/dev/null)"
        return 1
    fi
}

pkce_verifier() {
    openssl rand -base64 48 | tr -d '\n' | tr '+/' '-_' | tr -d '='
}

pkce_challenge() {
    local verifier="$1"
    printf '%s' "$verifier" | openssl dgst -sha256 -binary | openssl base64 -A | tr '+/' '-_' | tr -d '='
}

header_location() {
    local headers_file="$1"
    awk 'tolower($1) == "location:" {print $2}' "$headers_file" | tr -d '\r' | tail -1
}

absolute_auth_url() {
    local url="$1"
    local base

    base=$(auth_base_url)
    if [[ "$url" == /* ]]; then
        printf '%s%s' "$base" "$url"
    else
        printf '%s' "$url"
    fi
}

csrf_token_from_html() {
    local html_file="$1"
    grep -o 'name="_csrf"[^>]*value="[^"]*"' "$html_file" \
        | sed -n 's/.*value="\([^"]*\)".*/\1/p' \
        | head -1
}

get_owner_token() {
    local base
    local verifier
    local challenge
    local redirect_uri
    local auth_url
    local cookie_file
    local headers_file
    local body_file
    local status_code
    local csrf
    local location
    local next_url
    local code
    local token_json
    local i

    base=$(auth_base_url)
    verifier=$(pkce_verifier)
    challenge=$(pkce_challenge "$verifier")
    redirect_uri="http://127.0.0.1:8080/login/oauth2/code/${CLIENT_ID}"
    cookie_file="$TMP_DIR/owner-token-cookies.txt"
    headers_file="$TMP_DIR/owner-token-headers.txt"
    body_file="$TMP_DIR/owner-token-body.html"

    auth_url="${base}/oauth2/authorize?response_type=code"
    auth_url+="&client_id=$(url_encode "$CLIENT_ID")"
    auth_url+="&redirect_uri=$(url_encode "$redirect_uri")"
    auth_url+="&scope=$(url_encode "openid cloudbank.read cloudbank.transfer")"
    auth_url+="&code_challenge=$(url_encode "$challenge")"
    auth_url+="&code_challenge_method=S256"
    auth_url+="&state=cloudbank-all-services"

    status_code=$(curl --noproxy '*' -sS -L \
        -c "$cookie_file" \
        -b "$cookie_file" \
        -o "$body_file" \
        -w '%{http_code}' \
        "$auth_url")

    csrf=$(csrf_token_from_html "$body_file")
    if [[ "$status_code" != "200" || -z "$csrf" ]]; then
        record_failure "owner token" "login page HTTP $status_code or CSRF missing"
        return 1
    fi

    status_code=$(curl --noproxy '*' -sS \
        -c "$cookie_file" \
        -b "$cookie_file" \
        -D "$headers_file" \
        -o "$body_file" \
        -w '%{http_code}' \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -X POST \
        --data-urlencode "username=$OWNER_USERNAME" \
        --data-urlencode "password=$OWNER_PASSWORD" \
        --data-urlencode "_csrf=$csrf" \
        "${base}/login")

    location=$(header_location "$headers_file")
    for i in $(seq 1 10); do
        if [[ "$location" == "$redirect_uri"* ]]; then
            break
        fi
        if [[ -z "$location" ]]; then
            break
        fi
        next_url=$(absolute_auth_url "$location")
        status_code=$(curl --noproxy '*' -sS \
            -c "$cookie_file" \
            -b "$cookie_file" \
            -D "$headers_file" \
            -o "$body_file" \
            -w '%{http_code}' \
            "$next_url")
        location=$(header_location "$headers_file")
    done

    if [[ "$location" != "$redirect_uri"* ]]; then
        record_failure "owner token" "authorization redirect missing; last HTTP $status_code location=$location"
        return 1
    fi

    code=$(printf '%s' "$location" | sed -n 's/.*[?&]code=\([^&]*\).*/\1/p')
    if [[ -z "$code" ]]; then
        record_failure "owner token" "authorization code missing"
        return 1
    fi

    token_json=$(curl --noproxy '*' -sS \
        -u "${CLIENT_ID}:${CLIENT_SECRET}" \
        -X POST "${base}/oauth2/token" \
        -d grant_type=authorization_code \
        --data-urlencode "code=$code" \
        --data-urlencode "redirect_uri=$redirect_uri" \
        --data-urlencode "code_verifier=$verifier")

    OWNER_TOKEN=$(printf '%s' "$token_json" | jq -r '.access_token // empty')
    if [[ -n "$OWNER_TOKEN" ]]; then
        record_pass "token/owner user" "$OWNER_USERNAME issued"
    else
        record_failure "token/owner user" "not issued; response=$token_json"
        return 1
    fi
}

test_gateway_and_oauth() {
    print_header "APISIX Gateway And OAuth"

    if [[ -z "$GATEWAY_URL" ]]; then
        start_gateway_port_forward || true
    else
        GATEWAY_URL="${GATEWAY_URL%/}"
        record_pass "gateway" "using $GATEWAY_URL"
    fi

    get_client_secrets || true
    start_auth_port_forward || true
    # --owner-password can still supply a known value for debugging/reuse.
    if [[ -z "$OWNER_PASSWORD" ]]; then
        OWNER_PASSWORD=$(generate_owner_password)
    fi
    ensure_owner_user || true
    get_owner_token || true

    READ_TOKEN=$(get_token "cloudbank.read")
    WRITE_TOKEN=$(get_token "cloudbank.read cloudbank.write")
    TRANSFER_TOKEN=$(get_token "cloudbank.transfer")
    TEST_TOKEN=$(get_token "cloudbank.test" "$TEST_CLIENT_ID" "$TEST_CLIENT_SECRET")

    [[ -n "$READ_TOKEN" ]] && record_pass "token/cloudbank.read" "issued" || record_failure "token/cloudbank.read" "not issued"
    [[ -n "$WRITE_TOKEN" ]] && record_pass "token/cloudbank.write" "issued" || record_failure "token/cloudbank.write" "not issued"
    [[ -n "$TRANSFER_TOKEN" ]] && record_pass "token/cloudbank.transfer" "issued" || record_failure "token/cloudbank.transfer" "not issued"
    [[ -n "$TEST_TOKEN" ]] && record_pass "token/cloudbank.test" "issued" || record_failure "token/cloudbank.test" "not issued"

    local status_code
    LAST_OUT="$TMP_DIR/metadata.json"
    status_code=$(request_status "$LAST_OUT" "${GATEWAY_URL}/.well-known/oauth-authorization-server")
    record_status "azn metadata public" "200" "$status_code"

    LAST_OUT="$TMP_DIR/jwks.json"
    status_code=$(request_status "$LAST_OUT" "${GATEWAY_URL}/oauth2/jwks")
    record_status "azn jwks public" "200" "$status_code"
    if jq -e '.keys[0].kid' "$LAST_OUT" >/dev/null 2>&1; then
        record_pass "azn jwks signing key" "present"
    else
        record_failure "azn jwks signing key" "missing"
    fi

    LAST_OUT="$TMP_DIR/user-api.txt"
    status_code=$(request_status "$LAST_OUT" "${GATEWAY_URL}/user/api/v1/ping")
    record_status "azn user api external block" "404" "$status_code"
}

test_routed_service_apis() {
    print_header "Routed Service API Checks"

    local status_code

    LAST_OUT="$TMP_DIR/creditscore-anon.json"
    status_code=$(request_status "$LAST_OUT" "${GATEWAY_URL}/api/v1/creditscore")
    record_status "creditscore anonymous" "401" "$status_code"

    LAST_OUT="$TMP_DIR/creditscore.json"
    status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${READ_TOKEN}" \
        "${GATEWAY_URL}/api/v1/creditscore")
    record_status "creditscore read" "200" "$status_code"
    if jq -e '."Credit Score"' "$LAST_OUT" >/dev/null 2>&1; then
        record_pass "creditscore payload" "score present"
    else
        record_failure "creditscore payload" "unexpected $(cat "$LAST_OUT" 2>/dev/null)"
    fi

    LAST_OUT="$TMP_DIR/accounts.json"
    status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${OWNER_TOKEN}" \
        "${GATEWAY_URL}/api/v1/accounts")
    record_status "account list" "200" "$status_code"

    local from_account_provided=false
    local to_account_provided=false
    [[ -n "$FROM_ACCOUNT_ID" ]] && from_account_provided=true
    [[ -n "$TO_ACCOUNT_ID" ]] && to_account_provided=true

    if [[ -z "$FROM_ACCOUNT_ID" ]]; then
        FROM_ACCOUNT_ID=$(jq -r '[.[] | select((.accountBalance // 0) > 1) | .accountId][0] // empty' "$LAST_OUT" 2>/dev/null)
    fi
    if [[ -z "$TO_ACCOUNT_ID" ]]; then
        TO_ACCOUNT_ID=$(jq -r --argjson from "${FROM_ACCOUNT_ID:-0}" \
            '[.[] | select(.accountId != $from) | .accountId][0] // empty' "$LAST_OUT" 2>/dev/null)
    fi

    if [[ "$from_account_provided" == true ]] && ! jq -e --arg id "$FROM_ACCOUNT_ID" \
        'any(.[]; (.accountId | tostring) == $id)' "$LAST_OUT" >/dev/null 2>&1; then
        record_failure "from account ownership" "${FROM_ACCOUNT_ID} is not visible to ${OWNER_USERNAME}"
    fi
    if [[ "$to_account_provided" == true ]] && ! jq -e --arg id "$TO_ACCOUNT_ID" \
        'any(.[]; (.accountId | tostring) == $id)' "$LAST_OUT" >/dev/null 2>&1; then
        record_failure "to account ownership" "${TO_ACCOUNT_ID} is not visible to ${OWNER_USERNAME}"
    fi

    local first_customer_id
    first_customer_id=$(jq -r '.[0].accountCustomerId // empty' "$LAST_OUT" 2>/dev/null)

    if [[ -n "$FROM_ACCOUNT_ID" && -n "$TO_ACCOUNT_ID" ]]; then
        record_pass "account discovery" "from=$FROM_ACCOUNT_ID to=$TO_ACCOUNT_ID"
    else
        record_failure "account discovery" "could not find two accounts"
    fi

    LAST_OUT="$TMP_DIR/account-detail.json"
    status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${OWNER_TOKEN}" \
        "${GATEWAY_URL}/api/v1/account/${TO_ACCOUNT_ID}")
    record_status "account detail" "200" "$status_code"

    LAST_OUT="$TMP_DIR/account-transactions.json"
    status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${OWNER_TOKEN}" \
        "${GATEWAY_URL}/api/v1/account/${TO_ACCOUNT_ID}/transactions")
    if [[ "$status_code" == "200" || "$status_code" == "204" ]]; then
        record_pass "account transactions" "HTTP $status_code"
    else
        record_failure "account transactions" "HTTP $status_code expected 200 or 204; body=$(cat "$LAST_OUT" 2>/dev/null)"
    fi

    LAST_OUT="$TMP_DIR/account-journal-before.json"
    status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${OWNER_TOKEN}" \
        "${GATEWAY_URL}/api/v1/account/${TO_ACCOUNT_ID}/journal")
    record_status "account journal" "200" "$status_code"

    LAST_OUT="$TMP_DIR/account-internal-block.json"
    status_code=$(request_status "$LAST_OUT" \
        -X POST \
        -H "Authorization: Bearer ${READ_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"journalId\":999999999,\"accountId\":${TO_ACCOUNT_ID},\"journalType\":\"DEPOSIT\",\"journalAmount\":1}" \
        "${GATEWAY_URL}/api/v1/account/journal")
    record_status "account internal journal block" "403" "$status_code"

    LAST_OUT="$TMP_DIR/customers.json"
    status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${OWNER_TOKEN}" \
        "${GATEWAY_URL}/api/v1/customer")
    record_status "customer list" "200" "$status_code"

    local customer_id
    local customer_name
    local customer_email
    customer_id=$(jq -r --arg fallback "$first_customer_id" '.[0].customerId // $fallback // empty' "$LAST_OUT" 2>/dev/null)
    customer_name=$(jq -r '.[0].customerName // empty' "$LAST_OUT" 2>/dev/null)
    customer_email=$(jq -r '.[0].customerEmail // empty' "$LAST_OUT" 2>/dev/null)

    if [[ -n "$customer_id" ]]; then
        LAST_OUT="$TMP_DIR/customer-detail.json"
        status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${OWNER_TOKEN}" \
            "${GATEWAY_URL}/api/v1/customer/${customer_id}")
        record_status "customer detail" "200" "$status_code"
    else
        record_failure "customer detail" "no customer id found"
    fi

    if [[ -n "$customer_name" ]]; then
        LAST_OUT="$TMP_DIR/customer-name.json"
        status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${OWNER_TOKEN}" \
            "${GATEWAY_URL}/api/v1/customer/name/$(url_encode "$customer_name")")
        record_status "customer search name" "200" "$status_code"
    else
        record_failure "customer search name" "no customer name found"
    fi

    if [[ -n "$customer_email" ]]; then
        LAST_OUT="$TMP_DIR/customer-email.json"
        status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${OWNER_TOKEN}" \
            "${GATEWAY_URL}/api/v1/customer/byemail/$(url_encode "$customer_email")")
        record_status "customer search email" "200" "$status_code"
    else
        record_failure "customer search email" "no customer email found"
    fi
}

test_checks_workflow() {
    print_header "Testrunner And Checks Async Workflow"

    if [[ "$READ_ONLY" == true ]]; then
        print_warning "Read-only mode: skipping testrunner/checks mutating workflow"
        return 0
    fi

    local status_code
    local check_amount=$(( (RANDOM % 7000) + 2000 ))

    LAST_OUT="$TMP_DIR/testrunner-deposit-read.json"
    status_code=$(request_status "$LAST_OUT" \
        -X POST \
        -H "Authorization: Bearer ${READ_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"accountId\":${TO_ACCOUNT_ID},\"amount\":${check_amount}}" \
        "${GATEWAY_URL}/api/v1/testrunner/deposit")
    record_status "testrunner deposit read blocked" "403" "$status_code"

    LAST_OUT="$TMP_DIR/testrunner-deposit.json"
    status_code=$(request_status "$LAST_OUT" \
        -X POST \
        -H "Authorization: Bearer ${TEST_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"accountId\":${TO_ACCOUNT_ID},\"amount\":${check_amount}}" \
        "${GATEWAY_URL}/api/v1/testrunner/deposit")
    record_status "testrunner deposit test" "201" "$status_code"

    local journal_id=""
    local i
    for i in $(seq 1 30); do
        curl --noproxy '*' -sS -H "Authorization: Bearer ${OWNER_TOKEN}" \
            "${GATEWAY_URL}/api/v1/account/${TO_ACCOUNT_ID}/journal" >"$TMP_DIR/journal-poll.json"
        journal_id=$(jq -r --argjson amt "$check_amount" \
            '[.[] | select(.journalAmount == $amt and .journalType == "PENDING") | .journalId] | max // empty' \
            "$TMP_DIR/journal-poll.json" 2>/dev/null)
        [[ -n "$journal_id" ]] && break
        sleep 1
    done

    if [[ -n "$journal_id" ]]; then
        record_pass "checks deposit consumer" "pending journal=$journal_id amount=$check_amount"
    else
        record_failure "checks deposit consumer" "pending journal not found for amount=$check_amount"
        return 0
    fi

    LAST_OUT="$TMP_DIR/testrunner-clear.json"
    status_code=$(request_status "$LAST_OUT" \
        -X POST \
        -H "Authorization: Bearer ${TEST_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"journalId\":${journal_id}}" \
        "${GATEWAY_URL}/api/v1/testrunner/clear")
    record_status "testrunner clear test" "201" "$status_code"

    local cleared=""
    for i in $(seq 1 30); do
        curl --noproxy '*' -sS -H "Authorization: Bearer ${OWNER_TOKEN}" \
            "${GATEWAY_URL}/api/v1/account/${TO_ACCOUNT_ID}/journal" >"$TMP_DIR/journal-clear-poll.json"
        cleared=$(jq -r --argjson jid "$journal_id" \
            '.[] | select(.journalId == $jid and .journalType == "DEPOSIT") | .journalId' \
            "$TMP_DIR/journal-clear-poll.json" 2>/dev/null | head -1)
        [[ -n "$cleared" ]] && break
        sleep 1
    done

    if [[ -n "$cleared" ]]; then
        record_pass "checks clearance consumer" "journal=$journal_id cleared"
    else
        record_failure "checks clearance consumer" "journal=$journal_id not cleared"
    fi
}

test_transfer_workflow() {
    print_header "Transfer LRA Workflow"

    if [[ "$READ_ONLY" == true ]]; then
        print_warning "Read-only mode: skipping transfer mutating workflow"
        return 0
    fi

    local status_code
    local from_before
    local to_before
    local from_after
    local to_after

    LAST_OUT="$TMP_DIR/transfer-before-from.json"
    status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${OWNER_TOKEN}" \
        "${GATEWAY_URL}/api/v1/account/${FROM_ACCOUNT_ID}")
    from_before=$(jq -r '.accountBalance // empty' "$LAST_OUT" 2>/dev/null)

    LAST_OUT="$TMP_DIR/transfer-before-to.json"
    status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${OWNER_TOKEN}" \
        "${GATEWAY_URL}/api/v1/account/${TO_ACCOUNT_ID}")
    to_before=$(jq -r '.accountBalance // empty' "$LAST_OUT" 2>/dev/null)

    LAST_OUT="$TMP_DIR/transfer.json"
    status_code=$(request_status "$LAST_OUT" \
        -X POST \
        -H "Authorization: Bearer ${OWNER_TOKEN}" \
        "${GATEWAY_URL}/transfer?fromAccount=${FROM_ACCOUNT_ID}&toAccount=${TO_ACCOUNT_ID}&amount=1")
    record_status "transfer request" "200" "$status_code"

    if grep -q "withdraw succeeded deposit succeeded" "$LAST_OUT"; then
        record_pass "transfer response" "$(cat "$LAST_OUT")"
    else
        record_failure "transfer response" "unexpected $(cat "$LAST_OUT" 2>/dev/null)"
    fi

    sleep 2

    LAST_OUT="$TMP_DIR/transfer-after-from.json"
    status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${OWNER_TOKEN}" \
        "${GATEWAY_URL}/api/v1/account/${FROM_ACCOUNT_ID}")
    from_after=$(jq -r '.accountBalance // empty' "$LAST_OUT" 2>/dev/null)

    LAST_OUT="$TMP_DIR/transfer-after-to.json"
    status_code=$(request_status "$LAST_OUT" -H "Authorization: Bearer ${OWNER_TOKEN}" \
        "${GATEWAY_URL}/api/v1/account/${TO_ACCOUNT_ID}")
    to_after=$(jq -r '.accountBalance // empty' "$LAST_OUT" 2>/dev/null)

    if [[ -n "$from_before" && -n "$from_after" && "$from_after" == "$((from_before - 1))" ]]; then
        record_pass "transfer source balance" "$from_before -> $from_after"
    else
        record_failure "transfer source balance" "$from_before -> $from_after expected $((from_before - 1))"
    fi

    if [[ -n "$to_before" && -n "$to_after" && "$to_after" == "$((to_before + 1))" ]]; then
        record_pass "transfer target balance" "$to_before -> $to_after"
    else
        record_failure "transfer target balance" "$to_before -> $to_after expected $((to_before + 1))"
    fi
}

test_recent_logs() {
    print_header "Recent Checks And Transfer Log Evidence"

    if [[ "$READ_ONLY" == true ]]; then
        print_warning "Read-only mode: skipping mutating workflow log evidence checks"
        return 0
    fi

    kubectl -n "$NAMESPACE" logs svc/checks --tail=80 >"$TMP_DIR/checks.log" 2>/dev/null || true
    if grep -q "Received deposit" "$TMP_DIR/checks.log"; then
        record_pass "checks logs deposit" "seen"
    else
        record_failure "checks logs deposit" "not seen"
    fi

    if grep -q "Received clearance" "$TMP_DIR/checks.log"; then
        record_pass "checks logs clearance" "seen"
    else
        record_failure "checks logs clearance" "not seen"
    fi

    kubectl -n "$NAMESPACE" logs svc/transfer --tail=80 >"$TMP_DIR/transfer.log" 2>/dev/null || true
    if grep -q "withdraw succeeded deposit succeeded" "$TMP_DIR/transfer.log"; then
        record_pass "transfer logs" "success path seen"
    else
        record_failure "transfer logs" "success path not seen"
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    print_header "CloudBank v5 All Services Test"

    parse_args "$@"

    if [[ -z "$NAMESPACE" || -z "$DB_NAME" ]]; then
        echo "Please provide the following configuration values."
        echo ""
        prompt_value NAMESPACE "Kubernetes namespace" "obaas"
        prompt_value DB_NAME "Database name" "helmtest"
    fi

    TMP_DIR=$(mktemp -d /tmp/cloudbank-all-services.XXXXXX)

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

    set +e
    test_rollouts
    test_direct_health
    test_gateway_and_oauth
    test_routed_service_apis
    test_checks_workflow
    test_transfer_workflow
    test_recent_logs
    set -e

    print_header "Summary"
    print_info "PASS=$PASS_COUNT FAIL=$FAILURES"
    if [[ "$FAILURES" -eq 0 ]]; then
        print_success "All CloudBank service tests passed"
    else
        print_error "CloudBank service tests failed: $FAILURES failure(s)"
        exit 1
    fi
}

main "$@"
