#!/bin/bash
# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

# CloudBank v5 Database Secrets Script
# Creates Kubernetes secrets with database credentials for CloudBank microservices.
#
# Usage:
#   ./3-k8s_db_secrets.sh [options]
#
# Options:
#   -n, --namespace NAMESPACE    Kubernetes namespace (e.g., obaas-dev)
#   -d, --db-name DB_NAME        Database name (e.g., mydb)
#   -s, --priv-secret SECRET     Privileged secret name (default: {dbname}-db-priv-authn)
#   --delete                     Delete existing secrets before creating
#   --dry-run                    Show what would be created without creating
#   -h, --help                   Show this help message
#
# Prerequisites:
#   The privileged secret {dbname}-db-priv-authn (or custom name via -s) must exist with keys:
#     - username: Admin username (e.g., admin)
#     - password: Admin password
#     - service:  TNS service name (e.g., mydb_tp)
#
# Secret naming convention:
#   {dbname}-{service}-db-authn  - Application database credentials (per service)
#   {dbname}-db-priv-authn       - Privileged credentials (must exist)
#
# Example:
#   ./3-k8s_db_secrets.sh -n obaas-dev -d mydb

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
DB_NAME=""
DB_SERVICE=""
PRIV_SECRET=""
DELETE_EXISTING=false
DRY_RUN=false

# Service accounts to create
# Format: "name:description"
declare -a SERVICE_ACCOUNT_LIST=(
    "account:account, checks, testrunner"
    "customer:customer"
    "transfer:transfer"
    "creditscore:creditscore"
)

# =============================================================================
# Password Generation
# =============================================================================
generate_oracle_password() {
    # Oracle password requirements:
    # - 12-30 characters (we'll use 20)
    # - At least two uppercase letters
    # - At least two lowercase letters
    # - At least two digits
    # - At least two special characters from: # _
    # - Cannot start with a digit or special character
    # - Cannot contain the username

    local password_length=20
    local generated_password=""

    # Character sets
    local upper_chars="ABCDEFGHJKLMNPQRSTUVWXYZ"      # Excluded I, O (look like 1, 0)
    local lower_chars="abcdefghjkmnpqrstuvwxyz"       # Excluded i, l, o (look like 1, 0)
    local digit_chars="23456789"                     # Excluded 0, 1 (look like O, l)
    local special_chars="#_"                          # Oracle-safe special chars ($ can cause shell issues)
    local all_chars="${upper_chars}${lower_chars}${digit_chars}${special_chars}"

    # Start with an uppercase letter (Oracle requirement: can't start with digit/special)
    generated_password+="${upper_chars:RANDOM % ${#upper_chars}:1}"

    # Ensure we have at least 2 of each required type
    generated_password+="${upper_chars:RANDOM % ${#upper_chars}:1}"
    generated_password+="${lower_chars:RANDOM % ${#lower_chars}:1}"
    generated_password+="${lower_chars:RANDOM % ${#lower_chars}:1}"
    generated_password+="${digit_chars:RANDOM % ${#digit_chars}:1}"
    generated_password+="${digit_chars:RANDOM % ${#digit_chars}:1}"
    generated_password+="${special_chars:RANDOM % ${#special_chars}:1}"
    generated_password+="${special_chars:RANDOM % ${#special_chars}:1}"

    # Fill remaining length with random characters from all sets
    for ((index=8; index<password_length; index++)); do
        generated_password+="${all_chars:RANDOM % ${#all_chars}:1}"
    done

    # Shuffle positions 2-end using Fisher-Yates (keep first char as uppercase)
    local first_char="${generated_password:0:1}"
    local rest_chars="${generated_password:1}"
    local shuffled_password=""
    local rest_length=${#rest_chars}

    # Convert rest to array for shuffling
    local -a char_array=()
    for ((index=0; index<rest_length; index++)); do
        char_array+=("${rest_chars:index:1}")
    done

    # Fisher-Yates shuffle
    for ((index=rest_length-1; index>0; index--)); do
        local random_index=$((RANDOM % (index + 1)))
        local temp_char="${char_array[index]}"
        char_array[index]="${char_array[random_index]}"
        char_array[random_index]="$temp_char"
    done

    # Reconstruct password
    shuffled_password="${first_char}"
    for char in "${char_array[@]}"; do
        shuffled_password+="$char"
    done

    echo "$shuffled_password"
}

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
            -d|--db-name)
                DB_NAME="$2"
                shift 2
                ;;
            -s|--priv-secret)
                PRIV_SECRET="$2"
                shift 2
                ;;
            --delete)
                DELETE_EXISTING=true
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
CloudBank v5 Database Secrets Script

Creates Kubernetes secrets with database credentials for CloudBank microservices.
Passwords are auto-generated to meet Oracle database requirements.

Usage:
  ./3-k8s_db_secrets.sh [options]

Options:
  -n, --namespace NAMESPACE    Kubernetes namespace (required, e.g., obaas-dev)
  -d, --db-name DB_NAME        Database name (required, e.g., mydb)
  -s, --priv-secret SECRET     Privileged secret name (default: {dbname}-db-priv-authn)
  --delete                     Delete existing secrets before creating
  --dry-run                    Show what would be created without creating
  -h, --help                   Show this help message

Prerequisites:
  The privileged secret {dbname}-db-priv-authn (or custom name via -s) must already exist with keys:
    - username: Admin username (e.g., admin)
    - password: Admin password
    - service:  TNS service name (e.g., mydb_tp)

  This secret is typically created during OBaaS setup or manually:
    kubectl -n NAMESPACE create secret generic {dbname}-db-priv-authn \
      --from-literal=username=admin \
      --from-literal=password=YOUR_ADMIN_PASSWORD \
      --from-literal=service=mydb_tp

Secrets created:
  {dbname}-account-db-authn     - account, checks, testrunner
  {dbname}-customer-db-authn    - customer
  {dbname}-transfer-db-authn    - transfer
  {dbname}-creditscore-db-authn - creditscore

Example:
  ./3-k8s_db_secrets.sh -n obaas-dev -d mydb
  ./3-k8s_db_secrets.sh -n obaas-dev -d mydb -s my-custom-secret
  ./3-k8s_db_secrets.sh -n obaas-dev -d mydb --delete
  ./3-k8s_db_secrets.sh -n obaas-dev -d mydb --dry-run
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

    # Skip if already provided via CLI
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
    print_step "Checking prerequisites..."

    # Check kubectl and cluster connection
    if ! prereq_check_kubectl; then
        return 1
    fi

    # Check namespace exists
    if ! prereq_check_namespace "$NAMESPACE"; then
        return 1
    fi

    # Check privileged secret exists
    if ! prereq_check_db_priv_secret "$NAMESPACE" "$DB_NAME" "$PRIV_SECRET"; then
        return 1
    fi

    # Get DB_SERVICE from the secret
    if ! prereq_get_db_service "$NAMESPACE" "$DB_NAME" "$PRIV_SECRET"; then
        return 1
    fi
    DB_SERVICE="$PREREQ_DB_SERVICE"

    return 0
}

validate_inputs() {
    local errors=0

    if [[ -z "$NAMESPACE" ]]; then
        print_error "Namespace is required (-n/--namespace)"
        ((errors++))
    fi

    if [[ -z "$DB_NAME" ]]; then
        print_error "Database name is required (-d/--db-name)"
        ((errors++))
    fi

    if [[ $errors -gt 0 ]]; then
        echo ""
        show_help
        return 1
    fi

    return 0
}

# =============================================================================
# Secret Management
# =============================================================================
delete_secret() {
    local secret_name="$1"

    if kubectl get secret "$secret_name" -n "$NAMESPACE" &> /dev/null; then
        if [[ "$DRY_RUN" == true ]]; then
            print_info "Would delete: $secret_name"
        else
            kubectl delete secret "$secret_name" -n "$NAMESPACE" &> /dev/null
            print_warning "Deleted existing secret: $secret_name"
        fi
    fi
}

create_secret() {
    local secret_name="$1"
    local username="$2"
    local password="$3"
    local description="$4"

    # Oracle usernames must be uppercase (unless quoted, which we avoid)
    local upper_username
    upper_username=$(echo "$username" | tr '[:lower:]' '[:upper:]')

    if [[ "$DRY_RUN" == true ]]; then
        print_success "Would create: $secret_name"
        print_info "  username: $upper_username"
        print_info "  password: $password"
        print_info "  service:  $DB_SERVICE"
        print_info "  used by:  $description"
        return 0
    fi

    # Check if secret already exists
    if kubectl get secret "$secret_name" -n "$NAMESPACE" &> /dev/null; then
        if [[ "$DELETE_EXISTING" == true ]]; then
            delete_secret "$secret_name"
        else
            print_warning "Secret '$secret_name' already exists (use --delete to replace)"
            return 0
        fi
    fi

    kubectl -n "$NAMESPACE" create secret generic "$secret_name" \
        --from-literal=username="$upper_username" \
        --from-literal=password="$password" \
        --from-literal=service="$DB_SERVICE" \
        &> /dev/null

    print_success "Created: $secret_name ($description)"
}

# =============================================================================
# Main
# =============================================================================
main() {
    print_header "CloudBank v5 Database Secrets"

    # Parse command line arguments
    parse_args "$@"

    # Prompt for missing required values
    if [[ -z "$NAMESPACE" ]] || [[ -z "$DB_NAME" ]]; then
        echo "Please provide the following configuration values."
        echo ""
        prompt_value NAMESPACE "Kubernetes namespace" "obaas-dev"
        prompt_value DB_NAME "Database name" "mydb"
    fi

    # Validate inputs
    if ! validate_inputs; then
        exit 1
    fi

    # Check prerequisites (connects to cluster, reads DB_SERVICE from priv-authn secret)
    if ! check_prerequisites; then
        exit 1
    fi

    # Show configuration
    print_header "Configuration"
    echo "  Namespace:    $NAMESPACE"
    echo "  Database:     $DB_NAME"
    echo "  Priv Secret:  ${PRIV_SECRET:-${DB_NAME}-db-priv-authn}"
    echo "  TNS Service:  $DB_SERVICE"
    echo "  Dry Run:      $DRY_RUN"
    echo "  Delete First: $DELETE_EXISTING"

    # Generate passwords and create secrets
    print_header "Generating Passwords"
    print_step "Generating Oracle-compatible passwords..."

    # Store passwords in parallel arrays (Bash 3 compatible)
    local -a password_names=()
    local -a password_values=()
    local -a password_descriptions=()

    for account_info in "${SERVICE_ACCOUNT_LIST[@]}"; do
        local account_name="${account_info%%:*}"
        local account_description="${account_info#*:}"
        local generated_password
        generated_password=$(generate_oracle_password)
        password_names+=("$account_name")
        password_values+=("$generated_password")
        password_descriptions+=("$account_description")
        print_success "Generated password for: $account_name"
    done

    # Create secrets
    print_header "Creating Secrets"

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "DRY RUN MODE - No secrets will be created"
        echo ""
    fi

    # Create service account secrets
    local index
    for ((index=0; index<${#password_names[@]}; index++)); do
        local name="${password_names[$index]}"
        local password="${password_values[$index]}"
        local description="${password_descriptions[$index]}"
        local secret_name="${DB_NAME}-${name}-db-authn"
        create_secret "$secret_name" "$name" "$password" "$description"
    done

    # Summary
    print_header "Summary"

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "DRY RUN - No changes were made"
        echo ""
        echo "Run without --dry-run to create secrets."
    else
        print_success "All secrets created successfully!"
        echo ""
        echo "Verify with:"
        echo "  kubectl get secrets -n $NAMESPACE | grep -E '${DB_NAME}.*db-authn'"
        echo ""
        echo "View a secret's keys (not values):"
        echo "  kubectl describe secret ${DB_NAME}-account-db-authn -n $NAMESPACE"
    fi

    # Print password summary (useful for reference)
    print_header "Generated Credentials"
    print_info "Retrieve later: kubectl get secret SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.password}' | base64 -d"
    echo ""
    printf "  %-35s %-15s %s\n" "SECRET" "USERNAME" "PASSWORD"
    printf "  %-35s %-15s %s\n" "-----------------------------------" "---------------" "--------------------"
    for ((index=0; index<${#password_names[@]}; index++)); do
        local name="${password_names[$index]}"
        local password="${password_values[$index]}"
        printf "  %-35s %-15s %s\n" "${DB_NAME}-${name}-db-authn" "$name" "$password"
    done
    echo ""
    echo "Next step:"
    echo "  Deploys all CloudBank microservices: ./4-deploy_all_services.sh -n <namespace> -d <dbname> -p <prefix>"
}

# Run main function
main "$@"
