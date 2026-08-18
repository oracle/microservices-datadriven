#!/usr/bin/env bash
# Temporary migration helper: turn on the OTel Java agent's Micrometer bridge
# (otel.micrometer.enabled) on every already-deployed obaas-sample-app release,
# without needing to re-supply each release's original --set flags.
# Safe to delete once all services have been upgraded.
set -euo pipefail

export KUBECONFIG="${KUBECONFIG:-/Users/atael/.kube/obaas-test}"
NAMESPACE="obaas"
CHART="$(cd "$(dirname "${BASH_SOURCE[0]}")/../helm/app-charts/obaas-sample-app" && pwd)"

SERVICES=$(helm -n "$NAMESPACE" list --filter '^(account|azn-server|checks|creditscore|customer|testrunner|transfer)$' -o json \
  | python3 -c 'import json,sys; print("\n".join(r["name"] for r in json.load(sys.stdin)))')

if [[ -z "$SERVICES" ]]; then
  echo "No matching obaas-sample-app releases found in namespace $NAMESPACE" >&2
  exit 1
fi

for svc in $SERVICES; do
  echo "==> Enabling Micrometer bridge for $svc"
  helm upgrade "$svc" "$CHART" --reuse-values --set otel.micrometer.enabled=true -n "$NAMESPACE"
done

echo "Done. Waiting for rollouts..."
for svc in $SERVICES; do
  kubectl -n "$NAMESPACE" rollout status deployment/"$svc" --timeout=120s
done
