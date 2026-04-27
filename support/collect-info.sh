#!/bin/bash
#
# Collects diagnostic information from a Kubernetes cluster for Oracle support.
#
# Outputs:
#   collect-info.zip      - archive containing all-resources.yaml and cluster-info-dump/
#
# Secret handling: only Secret metadata (name, namespace, type, creation timestamp,
# labels) is collected — .data and .stringData are never requested or written to disk.
# The remaining output may still contain sensitive information, so review before sharing.

echo ''
echo 'Oracle Backend for Spring Boot and Microservices'
echo '------------------------------------------------'
echo ''
echo 'This script will collect information that could help Oracle diagnose and fix issues with your environment.  You should'
echo 'generally only run this script if you have been asked to by Oracle.'
echo ''
echo 'WARNING'
echo ''
echo 'This script generates a file named `collect-info.zip`. It is possible, and likely, that this file may contain private or sensitive'
echo 'information. You MUST review the contents of the generated file BEFORE providing it to Oracle or anyone else.'
echo ''

read -p "Do you want to continue? (y/n) " -n 1 -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 
fi

echo ''

# Verify required tools are available before doing any work
for cmd in kubectl jq zip; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not found in PATH." >&2
    exit 1
  fi
done

# Verify the cluster is reachable and credentials are valid
echo 'Checking cluster connectivity...'
if ! kubectl cluster-info &>/dev/null; then
  echo "Error: Unable to connect to the Kubernetes cluster. Check your KUBECONFIG and cluster status." >&2
  exit 1
fi

# Remove intermediate files on exit, whether the script succeeds or fails
trap 'rm -rf all-resources.yaml cluster-info-dump' EXIT

# Collect names and kinds of all resources across all namespaces
echo '[1/6] Collecting resources...'
kubectl get all -A -o custom-columns="KIND:.kind,NAME:.metadata.name" --no-headers=true > all-resources.yaml \
  || { echo "Error: Failed to collect cluster resources." >&2; exit 1; }

# Append the full YAML definition of each Custom Resource Definition
echo '[2/6] Collecting custom resource definitions...'
kubectl get crd -o yaml >> all-resources.yaml \
  || { echo "Error: Failed to collect custom resource definitions." >&2; exit 1; }

# Append secret metadata only — .data and .stringData are never fetched
echo '[3/6] Collecting secret metadata...'
kubectl get secrets -A -o json \
  | jq '[.items[] | {name: .metadata.name, namespace: .metadata.namespace, type: .type, creationTimestamp: .metadata.creationTimestamp, labels: .metadata.labels}]' \
  >> all-resources.yaml \
  || { echo "Error: Failed to collect secret metadata." >&2; exit 1; }

# Append client and server version for diagnosing version mismatch issues
echo '[4/6] Collecting version info...'
kubectl version -o yaml >> all-resources.yaml \
  || { echo "Error: Failed to collect version info." >&2; exit 1; }

# Dump nodes, pods, logs, and events across all namespaces into structured files
echo '[5/6] Dumping cluster info (this may take several minutes)...'
kubectl cluster-info dump -A --output-directory=cluster-info-dump > /dev/null 2>&1 \
  || { echo "Error: Failed to dump cluster info. Check that you have cluster-wide read permissions." >&2; exit 1; }

echo '[6/6] Creating archive...'
rm -f collect-info.zip
zip -r collect-info.zip all-resources.yaml cluster-info-dump > /dev/null \
  || { echo "Error: Failed to create collect-info.zip." >&2; exit 1; }

echo ''
echo 'Data collection complete.  Please review the output before sharing.'
echo "Output written to: $(pwd)/collect-info.zip"
