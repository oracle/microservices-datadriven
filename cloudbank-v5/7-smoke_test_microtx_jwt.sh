#!/bin/bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

# Validates azn-server JWT authentication to the MicroTx Workflow API and
# records evidence that the workflow server can retrieve azn-server JWKS.

set -euo pipefail

NAMESPACE="obaas"
AZN_PORT="18080"
WORKFLOW_PORT="19010"
CLIENT_ID="microtx-workflow-client"
CLIENT_SECRET_KEY="microtx-client-secret"
WORKFLOW_PATH="/workflow-server/api/metadata/workflow"

usage() {
    cat <<'EOF'
MicroTx JWT smoke test

Usage:
  ./7-smoke_test_microtx_jwt.sh [-n namespace] [--azn-port port] [--workflow-port port]
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--namespace) NAMESPACE="$2"; shift 2 ;;
        --azn-port) AZN_PORT="$2"; shift 2 ;;
        --workflow-port) WORKFLOW_PORT="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

AZN_PF_PID=""
WORKFLOW_PF_PID=""
cleanup() {
    [[ -n "$AZN_PF_PID" ]] && kill "$AZN_PF_PID" 2>/dev/null || true
    [[ -n "$WORKFLOW_PF_PID" ]] && kill "$WORKFLOW_PF_PID" 2>/dev/null || true
}
trap cleanup EXIT

kubectl port-forward -n "$NAMESPACE" svc/azn-server "${AZN_PORT}:8080" >/tmp/microtx-jwt-azn-port-forward.log 2>&1 &
AZN_PF_PID=$!
kubectl port-forward -n "$NAMESPACE" svc/obaas-otmm-workflow-server "${WORKFLOW_PORT}:9010" \
    >/tmp/microtx-jwt-workflow-port-forward.log 2>&1 &
WORKFLOW_PF_PID=$!

for attempt in {1..30}; do
    if curl --noproxy '*' --silent --fail "http://127.0.0.1:${AZN_PORT}/actuator/health" >/dev/null \
        && curl --noproxy '*' --silent --fail "http://127.0.0.1:${WORKFLOW_PORT}/workflow-server/health" >/dev/null; then
        break
    fi
    sleep 2
done

CLIENT_SECRET=$(kubectl get secret obaas-azn-server-auth -n "$NAMESPACE" \
    -o "jsonpath={.data.${CLIENT_SECRET_KEY}}" | base64 -d)
curl --noproxy '*' --silent --show-error --fail \
    -u "${CLIENT_ID}:${CLIENT_SECRET}" \
    -d grant_type=client_credentials \
    -d scope=microtx.workflow \
    "http://127.0.0.1:${AZN_PORT}/oauth2/token" >/tmp/microtx-jwt-token.json

TOKEN=$(jq -r .access_token /tmp/microtx-jwt-token.json)
test -n "$TOKEN" -a "$TOKEN" != null

echo "JWT claims:"
printf '%s' "$TOKEN" | awk -F. '{print $2}' | base64 -d 2>/dev/null \
    | jq '{iss,aud,scope,roles}'

echo "JWKS:"
curl --noproxy '*' --silent --show-error --fail \
    "http://127.0.0.1:${AZN_PORT}/oauth2/jwks" | jq '{keyCount:(.keys|length),kids:[.keys[].kid]}'

NO_TOKEN_STATUS=$(curl --noproxy '*' --silent --output /tmp/microtx-jwt-no-token.json \
    --write-out '%{http_code}' "http://127.0.0.1:${WORKFLOW_PORT}${WORKFLOW_PATH}")
TOKEN_STATUS=$(curl --noproxy '*' --silent --output /tmp/microtx-jwt-with-token.json \
    --write-out '%{http_code}' -H "Authorization: Bearer ${TOKEN}" \
    "http://127.0.0.1:${WORKFLOW_PORT}${WORKFLOW_PATH}")

echo "Workflow API without JWT: HTTP ${NO_TOKEN_STATUS}"
echo "Workflow API with azn-server JWT: HTTP ${TOKEN_STATUS}"
[[ "$NO_TOKEN_STATUS" == "401" ]]
[[ "$TOKEN_STATUS" == "200" ]]

AZN_POD=$(kubectl get pod -n "$NAMESPACE" -l app.kubernetes.io/name=azn-server \
    -o jsonpath='{.items[0].metadata.name}')
echo "JWKS callback evidence:"
kubectl exec -n "$NAMESPACE" "$AZN_POD" -- sh -c \
    'tail -200 /tmp/tomcat.8080.*/logs/access_log.*' \
    | grep 'GET /oauth2/jwks HTTP/1.1" 200' | tail -5

echo "MicroTx JWT smoke test passed."
