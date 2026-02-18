#!/bin/bash
# Quick check of all services in a K8s namespace using a temporary curl pod

NS="${1:?Usage: $0 <namespace>}"
POD_NAME="svc-check-$$"

echo "Checking services in namespace: $NS"
echo "========================================"

# Get services and ports
SERVICES=$(kubectl get svc -n "$NS" -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.ports[0].port}{"\n"}{end}')

# Build a script that curls each service
SCRIPT=""
while read -r SVC PORT; do
  [ -z "$SVC" ] && continue
  SCRIPT+="CODE=\$(wget --spider -S -T 3 http://$SVC.$NS.svc.cluster.local:$PORT/ 2>&1 | grep 'HTTP/' | awk '{print \$2}'); printf '%-40s port=%-6s -> HTTP %s\n' '$SVC' '$PORT' \"\${CODE:-000}\";"
done <<< "$SERVICES"

# Run it all in one temporary pod using busybox (widely available)
kubectl run "$POD_NAME" -n "$NS" --rm -it --restart=Never \
  --image=busybox:latest \
  -- sh -c "$SCRIPT"
