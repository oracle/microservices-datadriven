#!/bin/bash
# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

# CloudBank v5 Prerequisites Check Library
# Provides modular prerequisite check functions for CloudBank v5 scripts.
#
# Usage (from other scripts):
#   source "$(dirname "${BASH_SOURCE[0]}")/check_prereqs.sh"
#
# Standalone usage:
#   ./check_prereqs.sh [options]
#
# Options:
#   --all                 Run all prerequisite checks
#   --build               Run build prerequisites (Java, Maven, Docker)
#   --deploy              Run deployment prerequisites (kubectl, Helm, yq)
#   --oci                 Run OCI CLI prerequisites
#   --namespace NS        Check namespace exists
#   --obaas-release REL   Check OBaaS release exists (requires --namespace)
#   --db-name NAME        Check database secrets exist (requires --namespace)
#   -h, --help            Show this help message
#
# Example:
#   ./check_prereqs.sh --build
#   ./check_prereqs.sh --deploy --namespace obaas-dev
#   ./check_prereqs.sh --all --namespace obaas-dev --obaas-release obaas --db-name mydb

# =============================================================================
# Disable OCI CLI Debug Output
# =============================================================================
unset OCI_CLI_DEBUG
export OCI_CLI_DEBUG=""

# =============================================================================
# Color Output (can be overridden by sourcing scripts)
# =============================================================================
if [[ -z "$RED" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
fi

# Print functions (can be overridden by sourcing scripts)
if ! declare -f print_header &>/dev/null; then
    print_header() {
        echo ""
        echo -e "${BLUE}==============================================================================${NC}"
        echo -e "${BLUE}  $1${NC}"
        echo -e "${BLUE}==============================================================================${NC}"
    }
fi

if ! declare -f print_step &>/dev/null; then
    print_step() {
        echo -e "${BLUE}>${NC} $1"
    }
fi

if ! declare -f print_success &>/dev/null; then
    print_success() {
        echo -e "${GREEN}+${NC} $1"
    }
fi

if ! declare -f print_warning &>/dev/null; then
    print_warning() {
        echo -e "${YELLOW}!${NC} $1"
    }
fi

if ! declare -f print_error &>/dev/null; then
    print_error() {
        echo -e "${RED}x${NC} $1"
    }
fi

if ! declare -f print_info &>/dev/null; then
    print_info() {
        echo -e "  $1"
    }
fi

# =============================================================================
# Constants
# =============================================================================
REQUIRED_JAVA_VERSION="21"

# =============================================================================
# Generic Command Check
# =============================================================================
# Check if a command exists and optionally get its version
# Arguments:
#   $1 - command name
#   $2 - display name
#   $3 - "required" or "optional"
# Returns: 0 if found (or optional), 1 if required and not found
prereq_check_command() {
    local command_name="$1"
    local display_name="$2"
    local is_required="$3"

    if command -v "$command_name" &> /dev/null; then
        local tool_version
        case "$command_name" in
            java)
                tool_version=$(java --version 2>&1 | head -1)
                ;;
            mvn)
                tool_version=$(mvn --version 2>&1 | head -1)
                ;;
            kubectl)
                tool_version=$(kubectl version --client -o yaml 2>/dev/null | grep gitVersion | head -1 | awk '{print $2}')
                ;;
            docker)
                tool_version=$(docker --version 2>&1)
                ;;
            helm)
                tool_version=$(helm version --short 2>&1)
                ;;
            oci)
                tool_version=$(oci --version 2>&1)
                ;;
            *)
                tool_version="installed"
                ;;
        esac
        print_success "$display_name: $tool_version"
        return 0
    else
        if [[ "$is_required" == "required" ]]; then
            print_error "$display_name: NOT FOUND (required)"
            return 1
        else
            print_warning "$display_name: NOT FOUND (optional)"
            return 0
        fi
    fi
}

# =============================================================================
# Docker Prerequisites
# =============================================================================
# Check if Docker daemon is running
# Returns: 0 if running, 1 if not
prereq_check_docker() {
    if ! docker ps &> /dev/null; then
        print_error "Docker daemon is not running or not accessible"
        print_info "Ensure Docker/Rancher Desktop is running"
        print_info "If using Rancher Desktop, set: export DOCKER_HOST=unix:///Users/\$USER/.rd/docker.sock"
        return 1
    else
        print_success "Docker daemon is running"
        return 0
    fi
}

# Check Docker registry connectivity and authentication
# Arguments:
#   $1 - registry path (e.g., us-phoenix-1.ocir.io/mytenancy/cloudbank-v5)
# Returns: 0 if authenticated (or user chooses to continue), 1 if not and user declines
prereq_check_registry_connectivity() {
    local registry_path="$1"

    if [[ -z "$registry_path" ]]; then
        print_error "Registry path is required"
        return 1
    fi

    print_step "Checking registry connectivity..."

    # Extract registry host from full path
    local registry_host
    registry_host=$(echo "$registry_path" | cut -d'/' -f1)

    # Try to pull a non-existent image to verify credentials
    local pull_output
    pull_output=$(docker pull "$registry_path/auth-check-nonexistent-image" 2>&1)

    if echo "$pull_output" | grep -qi "not authorized or not found"; then
        print_error "Registry path appears invalid: $registry_path"
        print_info "Check your tenancy namespace and repository path"
        echo ""
        read -p "Continue anyway? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 1
        fi
    elif echo "$pull_output" | grep -qiE "unauthorized|authentication required|403|forbidden"; then
        print_error "Not authenticated to $registry_host"
        echo ""
        print_info "Maven/jkube will push using: $registry_host"
        print_info "You must login to this EXACT hostname:"
        print_info "  docker login $registry_host"
        echo ""
        if [[ "$registry_host" =~ ocir\.io ]]; then
            print_warning "NOTE: OCIR hostname aliases are NOT interchangeable for authentication!"
            print_info "Example: docker login sjc.ocir.io does NOT work for us-sanjose-1.ocir.io"
            print_info "         (Docker/Maven treat these as different registries)"
            echo ""
        fi
        read -p "Continue anyway? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 1
        fi
    else
        print_success "Authenticated to $registry_host"
    fi

    return 0
}

# =============================================================================
# Java Prerequisites
# =============================================================================
# Check Java version and JAVA_HOME
# Returns: 0 if correct version, 1 if not
prereq_check_java() {
    if ! command -v java &> /dev/null; then
        print_error "Java is not installed"
        return 1
    fi

    local detected_java_version
    detected_java_version=$(java -version 2>&1 | head -1 | sed -E 's/.*"([0-9]+).*/\1/')

    if [[ "$detected_java_version" != "$REQUIRED_JAVA_VERSION" ]]; then
        print_error "Java $REQUIRED_JAVA_VERSION is required, but found Java $detected_java_version"
        print_info "Set JAVA_HOME to a Java $REQUIRED_JAVA_VERSION installation:"
        print_info "  export JAVA_HOME=/opt/homebrew/opt/openjdk@$REQUIRED_JAVA_VERSION"
        print_info "  export PATH=\$JAVA_HOME/bin:\$PATH"
        return 1
    fi

    # Verify JAVA_HOME is set (Maven requires it)
    if [[ -z "$JAVA_HOME" ]]; then
        print_warning "Java $REQUIRED_JAVA_VERSION found, but JAVA_HOME is not set"
        print_info "Maven requires JAVA_HOME. Set it with:"
        print_info "  export JAVA_HOME=/opt/homebrew/opt/openjdk@$REQUIRED_JAVA_VERSION"
        return 1
    fi

    # Verify JAVA_HOME points to correct version
    local java_home_version
    java_home_version=$("$JAVA_HOME/bin/java" -version 2>&1 | head -1 | sed -E 's/.*"([0-9]+).*/\1/')
    if [[ "$java_home_version" != "$REQUIRED_JAVA_VERSION" ]]; then
        print_error "JAVA_HOME points to Java $java_home_version, but Java $REQUIRED_JAVA_VERSION is required"
        print_info "Set JAVA_HOME to a Java $REQUIRED_JAVA_VERSION installation:"
        print_info "  export JAVA_HOME=/opt/homebrew/opt/openjdk@$REQUIRED_JAVA_VERSION"
        return 1
    fi

    print_success "Java $REQUIRED_JAVA_VERSION is available (JAVA_HOME=$JAVA_HOME)"
    return 0
}

# =============================================================================
# Maven Prerequisites
# =============================================================================
# Check Maven is available
# Returns: 0 if available, 1 if not
prereq_check_maven() {
    if ! command -v mvn &> /dev/null; then
        print_error "Maven is not installed"
        print_info "Install with: brew install maven"
        return 1
    fi

    print_success "Maven is available"
    return 0
}

# Check project pom.xml exists
# Arguments:
#   $1 - directory path (optional, defaults to script directory)
# Returns: 0 if found, 1 if not
prereq_check_pom() {
    local project_dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

    if [[ ! -f "$project_dir/pom.xml" ]]; then
        print_error "pom.xml not found in $project_dir"
        print_info "Run this script from the cloudbank-v5 directory"
        return 1
    fi

    print_success "Project pom.xml found"
    return 0
}

# =============================================================================
# Kubernetes Prerequisites
# =============================================================================
# Check kubectl connectivity
# Returns: 0 if connected, 1 if not
prereq_check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        return 1
    fi

    if kubectl cluster-info &> /dev/null; then
        local current_context
        current_context=$(kubectl config current-context 2>/dev/null)
        print_success "kubectl connected to cluster: $current_context"
        return 0
    else
        print_error "kubectl cannot connect to cluster"
        return 1
    fi
}

# Check namespace exists
# Arguments:
#   $1 - namespace name
# Returns: 0 if exists, 1 if not
prereq_check_namespace() {
    local namespace="$1"

    if [[ -z "$namespace" ]]; then
        print_error "Namespace is required"
        return 1
    fi

    if kubectl get namespace "$namespace" &> /dev/null; then
        print_success "Namespace '$namespace' exists"
        return 0
    else
        print_error "Namespace '$namespace' does not exist"
        return 1
    fi
}

# Check Helm is available
# Returns: 0 if available, 1 if not
prereq_check_helm() {
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed"
        print_info "Install with: brew install helm"
        return 1
    fi

    print_success "Helm is available"
    return 0
}

# Check Helm chart exists
# Arguments:
#   $1 - chart path
# Returns: 0 if exists, 1 if not
prereq_check_helm_chart() {
    local chart_path="$1"

    if [[ -z "$chart_path" ]]; then
        print_error "Chart path is required"
        return 1
    fi

    if [[ -d "$chart_path" ]]; then
        print_success "Helm chart found at: $chart_path"
        return 0
    else
        print_error "Helm chart not found at: $chart_path"
        return 1
    fi
}


# =============================================================================
# OBaaS Prerequisites
# =============================================================================
# Check OBaaS Helm release exists
# Arguments:
#   $1 - namespace
#   $2 - release name (optional, will auto-detect if not provided)
# Returns: 0 if found, 1 if not
# Sets: PREREQ_OBAAS_RELEASE (detected release name)
prereq_check_obaas_release() {
    local namespace="$1"
    local release_name="$2"

    if [[ -z "$namespace" ]]; then
        print_error "Namespace is required"
        return 1
    fi

    # Get list of helm releases, excluding obaas-sample-app chart deployments
    # (obaas-sample-app are the application services, not the platform)
    local releases
    releases=$(helm list -n "$namespace" 2>/dev/null | grep -v 'obaas-sample-app' | awk 'NR>1 {print $1}' || true)

    local release_count
    if [[ -z "$releases" ]]; then
        release_count=0
    else
        release_count=$(echo "$releases" | wc -l | tr -d ' ')
    fi

    if [[ "$release_count" -eq 0 ]]; then
        print_error "No Helm releases found in namespace '$namespace'"
        print_info "Ensure OBaaS is installed before running this script"
        return 1
    fi

    if [[ -n "$release_name" ]]; then
        # User specified a release - verify it exists
        if helm list -n "$namespace" -q 2>/dev/null | grep -q "^${release_name}$"; then
            print_success "OBaaS release '$release_name' found"
            PREREQ_OBAAS_RELEASE="$release_name"
            return 0
        else
            print_error "Specified release '$release_name' not found in namespace '$namespace'"
            print_info "Available releases:"
            echo "$releases" | while read -r rel; do
                print_info "  - $rel"
            done
            return 1
        fi
    fi

    # Auto-detect - single release
    if [[ "$release_count" -eq 1 ]]; then
        PREREQ_OBAAS_RELEASE="$releases"
        print_success "Auto-detected OBaaS release: $PREREQ_OBAAS_RELEASE"
        return 0
    fi

    # Multiple releases found
    print_warning "Multiple Helm releases found in namespace '$namespace':"
    echo "$releases" | while read -r rel; do
        print_info "  - $rel"
    done
    print_info "Use --obaas-release to specify which one to use"
    return 1
}

# Check OBaaS wallet secret exists
# Arguments:
#   $1 - namespace
#   $2 - OBaaS release name
# Returns: 0 if found, 1 if not
# Sets: PREREQ_WALLET_SECRET (detected secret name)
prereq_check_wallet_secret() {
    local namespace="$1"
    local release_name="$2"

    if [[ -z "$namespace" || -z "$release_name" ]]; then
        print_error "Namespace and release name are required"
        return 1
    fi

    local wallet_secret
    wallet_secret=$(kubectl get secrets -n "$namespace" -o name 2>/dev/null | grep "${release_name}-adb-tns-admin" | head -1 | sed 's|secret/||')

    if [[ -n "$wallet_secret" ]]; then
        print_success "Wallet secret found: $wallet_secret"
        PREREQ_WALLET_SECRET="$wallet_secret"
        return 0
    else
        print_warning "Wallet secret '${release_name}-adb-tns-admin-*' not found"
        return 1
    fi
}

# Check privileged database secret exists
# Arguments:
#   $1 - namespace
#   $2 - database name
# Returns: 0 if found, 1 if not
prereq_check_db_priv_secret() {
    local namespace="$1"
    local db_name="$2"

    if [[ -z "$namespace" || -z "$db_name" ]]; then
        print_error "Namespace and database name are required"
        return 1
    fi

    local secret_name="${db_name}-db-priv-authn"

    if kubectl get secret "$secret_name" -n "$namespace" &> /dev/null; then
        print_success "Secret '$secret_name' exists"
        return 0
    else
        print_error "Secret '$secret_name' not found (required for db-init job and Liquibase)"
        print_info "Verify the database name and ensure the secret exists."
        return 1
    fi
}

# Check application database secrets exist
# Arguments:
#   $1 - namespace
#   $2 - database name
# Returns: 0 if all found, 1 if any missing
prereq_check_db_app_secrets() {
    local namespace="$1"
    local db_name="$2"

    if [[ -z "$namespace" || -z "$db_name" ]]; then
        print_error "Namespace and database name are required"
        return 1
    fi

    local secrets=(
        "${db_name}-account-db-authn"
        "${db_name}-customer-db-authn"
        "${db_name}-transfer-db-authn"
        "${db_name}-creditscore-db-authn"
    )

    local errors=0
    for secret in "${secrets[@]}"; do
        if kubectl get secret "$secret" -n "$namespace" &> /dev/null; then
            print_success "Secret '$secret' exists"
        else
            print_warning "Secret '$secret' not found"
            ((errors++))
        fi
    done

    if [[ $errors -gt 0 ]]; then
        print_info "Create missing secrets with: ./3-k8s_db_secrets.sh -n $namespace -d $db_name"
        return 1
    fi

    return 0
}

# Get database service from privileged secret
# Arguments:
#   $1 - namespace
#   $2 - database name
# Returns: 0 and sets PREREQ_DB_SERVICE, 1 on error
prereq_get_db_service() {
    local namespace="$1"
    local db_name="$2"

    if [[ -z "$namespace" || -z "$db_name" ]]; then
        print_error "Namespace and database name are required"
        return 1
    fi

    local secret_name="${db_name}-db-priv-authn"

    if kubectl get secret "$secret_name" -n "$namespace" &> /dev/null; then
        local service
        service=$(kubectl get secret "$secret_name" -n "$namespace" -o jsonpath='{.data.service}' 2>/dev/null | base64 -d 2>/dev/null)
        if [[ -n "$service" ]]; then
            PREREQ_DB_SERVICE="$service"
            print_success "Database TNS service read from secret: $PREREQ_DB_SERVICE"
            return 0
        fi
    fi

    # Default to {dbname}_tp
    PREREQ_DB_SERVICE="${db_name}_tp"
    print_info "Database TNS service defaulted to: $PREREQ_DB_SERVICE"
    return 0
}

# =============================================================================
# OCI CLI Prerequisites
# =============================================================================
# Check OCI CLI is installed
# Returns: 0 if installed, 1 if not
prereq_check_oci_cli() {
    if ! command -v oci &> /dev/null; then
        print_error "OCI CLI is not installed"
        print_info "Install with: brew install oci-cli"
        print_info "Or visit: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
        return 1
    fi

    print_success "OCI CLI is installed"
    return 0
}

# Check OCI CLI is configured
# Returns: 0 if configured, 1 if not
prereq_check_oci_config() {
    if [[ ! -f "$HOME/.oci/config" ]]; then
        print_error "OCI CLI is not configured"
        print_info "Run: oci setup config"
        return 1
    fi

    print_success "OCI CLI is configured"
    return 0
}

# Check OCI authentication and get namespace/region
# Returns: 0 and sets PREREQ_OCI_NAMESPACE, PREREQ_OCI_REGION, PREREQ_OCI_REGISTRY
# Returns: 1 on authentication failure
prereq_check_oci_auth() {
    print_step "Testing OCI authentication..."

    PREREQ_OCI_NAMESPACE=$(oci os ns get --query 'data' --raw-output 2>/dev/null | grep -v "^DEBUG:")
    if [[ $? -ne 0 ]] || [[ -z "$PREREQ_OCI_NAMESPACE" ]]; then
        print_error "OCI authentication failed"
        print_info "Check your OCI configuration: oci setup config"
        return 1
    fi
    print_success "OCI authentication successful (namespace: $PREREQ_OCI_NAMESPACE)"

    print_step "Getting configured region..."
    # First try to get region from config file
    PREREQ_OCI_REGION=$(grep -E "^\s*region\s*=" "$HOME/.oci/config" | head -1 | cut -d'=' -f2 | tr -d ' ')
    if [[ -z "$PREREQ_OCI_REGION" ]]; then
        # Fallback: try to get home region from OCI API
        PREREQ_OCI_REGION=$(oci iam region-subscription list --query 'data[?"is-home-region"].{region:"region-name"}|[0].region' --raw-output 2>/dev/null | grep -v "^DEBUG:")
    fi
    if [[ -z "$PREREQ_OCI_REGION" ]]; then
        print_error "Could not determine OCI region"
        print_info "Check your OCI configuration: oci setup config"
        return 1
    fi
    print_success "Using region: $PREREQ_OCI_REGION"

    # Build registry URL
    PREREQ_OCI_REGISTRY="${PREREQ_OCI_REGION}.ocir.io/${PREREQ_OCI_NAMESPACE}"
    print_info "Registry: $PREREQ_OCI_REGISTRY"

    return 0
}

# Lookup OCI compartment OCID
# Arguments:
#   $1 - compartment name
# Returns: 0 and sets PREREQ_COMPARTMENT_OCID, 1 if not found
prereq_lookup_compartment() {
    local compartment="$1"

    if [[ -z "$compartment" ]]; then
        print_error "Compartment name is required"
        return 1
    fi

    print_step "Looking up compartment: $compartment"

    PREREQ_COMPARTMENT_OCID=$(oci iam compartment list --all --compartment-id-in-subtree true \
        --query "data[?name=='$compartment'].id | [0]" --raw-output 2>/dev/null | grep -v "^DEBUG:")

    if [[ -z "$PREREQ_COMPARTMENT_OCID" ]] || [[ "$PREREQ_COMPARTMENT_OCID" == "null" ]]; then
        print_error "Compartment '$compartment' not found"
        print_info "List compartments with: oci iam compartment list --all"
        return 1
    fi

    print_success "Found compartment OCID: $PREREQ_COMPARTMENT_OCID"
    return 0
}

# =============================================================================
# Composite Check Functions
# =============================================================================
# Check all build prerequisites (Java, Maven, Docker)
# Returns: 0 if all pass, 1 if any fail
prereq_check_build() {
    print_step "Checking build prerequisites..."

    local errors=0

    prereq_check_docker || ((errors++))
    prereq_check_java || ((errors++))
    prereq_check_maven || ((errors++))
    prereq_check_pom || ((errors++))

    if [[ $errors -gt 0 ]]; then
        return 1
    fi

    return 0
}

# Check all deployment prerequisites (kubectl, Helm)
# Returns: 0 if all pass, 1 if any fail
prereq_check_deploy() {
    print_step "Checking deployment prerequisites..."

    local errors=0

    prereq_check_kubectl || ((errors++))
    prereq_check_helm || ((errors++))

    if [[ $errors -gt 0 ]]; then
        return 1
    fi

    return 0
}

# Check all OCI prerequisites
# Returns: 0 if all pass, 1 if any fail
prereq_check_oci() {
    print_step "Checking OCI prerequisites..."

    local errors=0

    prereq_check_oci_cli || ((errors++))
    prereq_check_oci_config || ((errors++))
    prereq_check_oci_auth || ((errors++))

    if [[ $errors -gt 0 ]]; then
        return 1
    fi

    return 0
}

# Check all prerequisites
# Arguments:
#   $1 - namespace (optional)
#   $2 - OBaaS release name (optional)
#   $3 - database name (optional)
# Returns: 0 if all pass, 1 if any fail
prereq_check_all() {
    local namespace="$1"
    local obaas_release="$2"
    local db_name="$3"

    local errors=0

    print_header "Checking All Prerequisites"

    # Build prerequisites
    echo ""
    prereq_check_build || ((errors++))

    # Deployment prerequisites
    echo ""
    prereq_check_deploy || ((errors++))

    # OCI prerequisites (optional)
    echo ""
    prereq_check_oci_cli && prereq_check_oci_config && prereq_check_oci_auth

    # Namespace-dependent checks
    if [[ -n "$namespace" ]]; then
        echo ""
        prereq_check_namespace "$namespace" || ((errors++))

        if [[ -n "$obaas_release" ]]; then
            prereq_check_obaas_release "$namespace" "$obaas_release" || ((errors++))
        fi

        if [[ -n "$db_name" ]]; then
            prereq_check_db_priv_secret "$namespace" "$db_name" || ((errors++))
        fi
    fi

    echo ""
    if [[ $errors -gt 0 ]]; then
        print_error "Prerequisites check failed with $errors error(s)"
        return 1
    else
        print_success "All prerequisites satisfied!"
        return 0
    fi
}

# =============================================================================
# Standalone Mode
# =============================================================================
check_prereqs_show_help() {
    cat << 'EOF'
CloudBank v5 Prerequisites Check

Checks and validates prerequisites for CloudBank v5 installation.

Usage:
  ./check_prereqs.sh [options]

Options:
  --all                 Run all prerequisite checks (default)
  --build               Run build prerequisites only (Java, Maven, Docker)
  --deploy              Run deployment prerequisites only (kubectl, Helm)
  --oci                 Run OCI CLI prerequisites only
  -n, --namespace NS    Kubernetes namespace (prompted if not provided)
  -o, --obaas-release REL  OBaaS release name (prompted if not provided)
  -d, --db-name NAME    Database name (prompted if not provided)
  -h, --help            Show this help message

Examples:
  ./check_prereqs.sh                                    # Run all checks, prompt for values
  ./check_prereqs.sh -n obaas-dev -o obaas -d mydb      # Run all checks with values
  ./check_prereqs.sh --build                            # Only build prerequisites
  ./check_prereqs.sh --deploy                           # Only deployment prerequisites
  ./check_prereqs.sh --oci                              # Only OCI prerequisites

As a library (source from other scripts):
  source "$(dirname "${BASH_SOURCE[0]}")/check_prereqs.sh"
  prereq_check_java
  prereq_check_docker
  prereq_check_kubectl
EOF
}

check_prereqs_main() {
    local check_all=false
    local check_build=false
    local check_deploy=false
    local check_oci=false
    local namespace=""
    local obaas_release=""
    local db_name=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                check_all=true
                shift
                ;;
            --build)
                check_build=true
                shift
                ;;
            --deploy)
                check_deploy=true
                shift
                ;;
            --oci)
                check_oci=true
                shift
                ;;
            -n|--namespace)
                namespace="$2"
                shift 2
                ;;
            -o|--obaas-release)
                obaas_release="$2"
                shift 2
                ;;
            -d|--db-name)
                db_name="$2"
                shift 2
                ;;
            -h|--help)
                check_prereqs_show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                check_prereqs_show_help
                exit 1
                ;;
        esac
    done

    # Default to --all if no specific check requested
    if [[ "$check_build" != true && "$check_deploy" != true && "$check_oci" != true ]]; then
        check_all=true
    fi

    local errors=0

    if [[ "$check_all" == true ]]; then
        # Prompt for missing values needed for full check
        if [[ -z "$namespace" ]]; then
            read -p "Kubernetes namespace (e.g., obaas-dev): " namespace
            if [[ -z "$namespace" ]]; then
                print_error "Namespace is required"
                exit 1
            fi
        fi

        # Validate namespace before proceeding
        if ! prereq_check_namespace "$namespace"; then
            print_error "Cannot proceed with invalid namespace"
            exit 1
        fi

        # Try to auto-detect OBaaS release from namespace
        if [[ -z "$obaas_release" ]]; then
            local releases
            releases=$(helm list -n "$namespace" -q 2>/dev/null | grep -E '^obaas|eureka|oracle-backend' || true)
            if [[ -z "$releases" ]]; then
                releases=$(helm list -n "$namespace" -q 2>/dev/null || true)
            fi

            local release_count
            if [[ -z "$releases" ]]; then
                release_count=0
            else
                release_count=$(echo "$releases" | wc -l | tr -d ' ')
            fi

            if [[ "$release_count" -eq 1 ]]; then
                obaas_release="$releases"
                print_success "Auto-detected OBaaS release: $obaas_release"
            elif [[ "$release_count" -gt 1 ]]; then
                print_warning "Multiple Helm releases found in namespace '$namespace':"
                echo "$releases" | while read -r rel; do
                    print_info "  - $rel"
                done
                read -p "OBaaS release name: " obaas_release
                if [[ -z "$obaas_release" ]]; then
                    print_error "OBaaS release name is required"
                    exit 1
                fi
            else
                read -p "OBaaS release name (e.g., obaas): " obaas_release
                if [[ -z "$obaas_release" ]]; then
                    print_error "OBaaS release name is required"
                    exit 1
                fi
            fi
        fi

        if [[ -z "$db_name" ]]; then
            read -p "Database name (e.g., mydb): " db_name
            if [[ -z "$db_name" ]]; then
                print_error "Database name is required"
                exit 1
            fi
        fi

        prereq_check_all "$namespace" "$obaas_release" "$db_name" || ((errors++))
    else
        if [[ "$check_build" == true ]]; then
            print_header "Build Prerequisites"
            prereq_check_build || ((errors++))
        fi

        if [[ "$check_deploy" == true ]]; then
            print_header "Deployment Prerequisites"
            prereq_check_deploy || ((errors++))
        fi

        if [[ "$check_oci" == true ]]; then
            print_header "OCI Prerequisites"
            prereq_check_oci || ((errors++))
        fi
    fi

    echo ""
    if [[ $errors -gt 0 ]]; then
        print_error "Prerequisites check failed"
        exit 1
    else
        print_success "Prerequisites check passed"
        exit 0
    fi
}

# Run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_prereqs_main "$@"
fi
