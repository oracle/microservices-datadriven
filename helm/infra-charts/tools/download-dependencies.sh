#!/usr/bin/env bash
# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

# =============================================================================
# OBaaS Helm Dependencies Download Script
# =============================================================================
# Downloads all Helm chart dependencies for obaas and obaas-prereqs charts.
#
# Usage:
#   ./download-dependencies.sh
#
# =============================================================================

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELM_DIR="$(dirname "$SCRIPT_DIR")"

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
# Prerequisites
# -----------------------------------------------------------------------------
if ! command -v helm &> /dev/null; then
    log error "helm is not installed or not in PATH"
    echo "Install helm: https://helm.sh/docs/intro/install/" >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
log none "=============================================="
log none "OBaaS Helm Dependencies Download"
log none "=============================================="
echo

# Update obaas-prereqs dependencies
log info "Updating obaas-prereqs dependencies..."
if helm dependency update "${HELM_DIR}/obaas-prereqs"; then
    log success "obaas-prereqs dependencies updated"
else
    log error "Failed to update obaas-prereqs dependencies"
    exit 1
fi

echo

# Update obaas dependencies
log info "Updating obaas dependencies..."
if helm dependency update "${HELM_DIR}/obaas"; then
    log success "obaas dependencies updated"
else
    log error "Failed to update obaas dependencies"
    exit 1
fi

echo
log none "=============================================="
log success "All dependencies downloaded successfully!"
log none "=============================================="