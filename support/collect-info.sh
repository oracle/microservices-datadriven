#!/usr/bin/env bash
#
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Collects diagnostic information from a Kubernetes cluster for Oracle support.
#
# Outputs:
#   collect-info.zip      - archive containing the collected diagnostics
#
# Secret handling: Secrets are listed with Kubernetes Table output only. Secret
# values are not written to the bundle. The remaining output, especially pod
# logs and ConfigMaps, may still contain sensitive information.

set -o errexit
set -o nounset
set -o pipefail

OUTPUT_FILE="collect-info.zip"
ASSUME_YES=false

usage() {
  echo "Usage: $0 [--yes] [--output FILE]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes)
      ASSUME_YES=true
      ;;
    -o|--output)
      [[ $# -ge 2 ]] || { echo "Error: missing value for --output." >&2; exit 2; }
      OUTPUT_FILE="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

echo ''
echo 'Oracle Backend for Microservices and AI'
echo '---------------------------------------'
echo ''
echo 'This script will collect information that could help Oracle diagnose and fix issues with your environment.'
echo 'You should generally only run this script if you have been asked to by Oracle.'
echo ''
echo 'WARNING'
echo ''
echo "This script generates ${OUTPUT_FILE}. It is possible, and likely, that this file may contain private or sensitive information."
echo 'You MUST review the contents of the generated file BEFORE providing it to Oracle or anyone else.'
echo ''

if [[ "$ASSUME_YES" != true ]]; then
  if [[ ! -t 0 ]]; then
    echo 'Error: non-interactive use requires --yes.' >&2
    exit 2
  fi

  read -r -n 1 -p 'Do you want to continue? (y/n) ' || exit 1
  echo
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo ''

# Verify required tools are available before doing any work.
for cmd in kubectl zip; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required but not found in PATH." >&2
    exit 1
  fi
done

umask 077
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/collect-info.XXXXXX")"
ARCHIVE_TMP=""
ERRORS_FILE="$WORK_DIR/collection-errors.log"
: > "$ERRORS_FILE"

cleanup() {
  rm -rf "$WORK_DIR"
  if [[ -n "$ARCHIVE_TMP" ]]; then
    rm -f "$ARCHIVE_TMP"
  fi
}
trap cleanup EXIT

record_failure() {
  printf '%s\n' "$1" >> "$ERRORS_FILE"
}

# Capture each command independently so a missing permission or optional API
# does not discard the diagnostics collected successfully before it.
capture() {
  local label="$1"
  local destination="$2"
  local rc
  shift 2

  if "$@" >"$WORK_DIR/$destination" 2>"$WORK_DIR/$destination.stderr"; then
    rm -f "$WORK_DIR/$destination.stderr"
  else
    rc=$?
    record_failure "$label failed with exit code $rc"
  fi
  return 0
}

CONTEXT="$(kubectl config current-context 2>/dev/null || true)"
if [[ -z "$CONTEXT" ]]; then
  CONTEXT='unknown'
fi

{
  printf 'collector_started_utc: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf 'kubectl_context: %s\n' "$CONTEXT"
  printf 'output_file: %s\n' "$OUTPUT_FILE"
} > "$WORK_DIR/collection-metadata.txt"

# Verify the cluster is reachable and credentials are valid.
echo 'Checking cluster connectivity...'
if ! kubectl cluster-info \
    >"$WORK_DIR/cluster-info.txt" \
    2>"$WORK_DIR/cluster-info.stderr"; then
  echo 'Error: unable to connect to the Kubernetes cluster. Check your KUBECONFIG and cluster status.' >&2
  sed -n '1,20p' "$WORK_DIR/cluster-info.stderr" >&2
  exit 1
fi
rm -f "$WORK_DIR/cluster-info.stderr"

echo '[1/8] Collecting Kubernetes and API metadata...'
capture 'Kubernetes version' version.yaml kubectl version -o yaml
capture 'API resource inventory' api-resources.txt kubectl api-resources --verbs=list -o wide
capture 'Namespaces' namespaces.yaml kubectl get namespaces -o yaml
capture 'Nodes' nodes.yaml kubectl get nodes -o yaml

echo '[2/8] Collecting workloads and services...'
capture 'resource inventory' resource-inventory.txt \
  kubectl get all -A \
  -o custom-columns='NAMESPACE:.metadata.namespace,KIND:.kind,NAME:.metadata.name' \
  --no-headers=true
capture 'workloads and services' resources.yaml kubectl get all -A -o yaml
capture 'ServiceAccounts' serviceaccounts.yaml kubectl get serviceaccounts -A -o yaml
capture 'Endpoints' endpoints.yaml kubectl get endpoints -A -o yaml
capture 'EndpointSlices' endpointslices.yaml kubectl get endpointslices -A -o yaml

echo '[3/8] Collecting custom resources and configuration...'
capture 'CustomResourceDefinitions' crds.yaml kubectl get crd -o yaml
capture 'ConfigMaps' configmaps.yaml kubectl get configmaps -A -o yaml
capture 'IngressClasses' ingressclasses.yaml kubectl get ingressclasses -o yaml
capture 'Ingresses' ingresses.yaml kubectl get ingresses -A -o yaml
capture 'GatewayClasses' gatewayclasses.yaml kubectl get gatewayclasses -o yaml
capture 'Gateways' gateways.yaml kubectl get gateways -A -o yaml
capture 'HTTPRoutes' httproutes.yaml kubectl get httproutes -A -o yaml

echo '[4/8] Collecting storage and policy resources...'
capture 'PersistentVolumeClaims' persistent-volume-claims.yaml \
  kubectl get persistentvolumeclaims -A -o yaml
capture 'PersistentVolumes' persistent-volumes.yaml kubectl get persistentvolumes -o yaml
capture 'StorageClasses' storage-classes.yaml kubectl get storageclasses -o yaml
capture 'CSIDrivers' csi-drivers.yaml kubectl get csidrivers -o yaml
capture 'NetworkPolicies' networkpolicies.yaml kubectl get networkpolicies -A -o yaml
capture 'Roles and RoleBindings' rbac.yaml kubectl get roles,rolebindings -A -o yaml
capture 'ClusterRoles and ClusterRoleBindings' cluster-rbac.yaml \
  kubectl get clusterroles,clusterrolebindings -o yaml

echo '[5/8] Collecting event and Secret metadata...'
capture 'core Events' events.yaml kubectl get events -A -o yaml
capture 'events.k8s.io Events' events-v1.yaml kubectl get events.events.k8s.io -A -o yaml
capture 'Secret metadata' secret-metadata.txt kubectl get secrets -A --show-labels

echo '[6/8] Dumping cluster info and pod logs (this may take several minutes)...'
capture 'cluster info dump' cluster-info-dump.stdout \
  kubectl cluster-info dump -A --output-directory="$WORK_DIR/cluster-info-dump"

echo '[7/8] Collecting Helm metadata when available...'
if command -v helm >/dev/null 2>&1; then
  capture 'Helm releases' helm-releases.yaml helm list -A -o yaml
  capture 'Helm version' helm-version.txt helm version --short
else
  printf 'helm is not installed or not available in PATH\n' > "$WORK_DIR/helm-version.txt"
fi

if [[ -s "$ERRORS_FILE" ]]; then
  printf 'collection_status: completed_with_errors\n' >> "$WORK_DIR/collection-metadata.txt"
  echo 'Collection completed with one or more command errors; see collection-errors.log.' >&2
else
  printf 'collection_status: completed_without_command_errors\n' >> "$WORK_DIR/collection-metadata.txt"
fi

echo '[8/8] Creating archive...'
if [[ "$OUTPUT_FILE" = /* ]]; then
  OUTPUT_PATH="$OUTPUT_FILE"
else
  OUTPUT_PATH="$(pwd)/$OUTPUT_FILE"
fi

OUTPUT_DIR="$(dirname "$OUTPUT_PATH")"
if [[ ! -d "$OUTPUT_DIR" || ! -w "$OUTPUT_DIR" ]]; then
  echo "Error: output directory is not writable: $OUTPUT_DIR" >&2
  exit 1
fi

# Create the archive beside the requested output and replace the old bundle
# only after collection and archive validation succeed.
ARCHIVE_TMP="$(mktemp "$OUTPUT_DIR/.collect-info.XXXXXX")"
rm -f "$ARCHIVE_TMP"

if ! (cd "$WORK_DIR" && zip -rq "$ARCHIVE_TMP" .); then
  echo 'Error: failed to create the support archive.' >&2
  exit 1
fi

if command -v unzip >/dev/null 2>&1; then
  if ! unzip -tq "$ARCHIVE_TMP"; then
    echo 'Error: support archive validation failed.' >&2
    exit 1
  fi
else
  if ! zip -T "$ARCHIVE_TMP"; then
    echo 'Error: support archive validation failed.' >&2
    exit 1
  fi
fi

mv -f "$ARCHIVE_TMP" "$OUTPUT_PATH"
ARCHIVE_TMP=""
chmod 600 "$OUTPUT_PATH"

echo ''
echo 'Data collection complete. Please review the output before sharing.'
echo "Output written to: $OUTPUT_PATH"
