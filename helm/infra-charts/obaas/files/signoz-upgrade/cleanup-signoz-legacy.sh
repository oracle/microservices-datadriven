#!/bin/sh
set -eu

KUBECTL="${KUBECTL:-kubectl}"
NAMESPACE="${NAMESPACE:?NAMESPACE is required}"
STATEFULSET_NAME="${STATEFULSET_NAME:?STATEFULSET_NAME is required}"
LEGACY_HOOK_NAME="${LEGACY_HOOK_NAME:?LEGACY_HOOK_NAME is required}"

kube() { "${KUBECTL}" "$@"; }
fail() { echo "ERROR: SigNoz legacy cleanup failed: $*" >&2; exit 1; }

legacy_state() {
  kube get statefulset "${STATEFULSET_NAME}" -n "${NAMESPACE}" \
    -o jsonpath='{.spec.template.spec.hostAliases[*].hostnames[*]}{"|"}{.spec.template.spec.containers[*].name}{"|"}{.spec.template.spec.containers[?(@.name=="signoz")].env[*].name}{"|"}{.spec.template.spec.containers[?(@.name=="signoz")].volumeMounts[*].name}{"|"}{.spec.template.spec.volumes[*].name}'
}

if kube get statefulset "${STATEFULSET_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; then
  current_state="$(legacy_state)"
  case "${current_state}" in
    *accounts.google.com*|*oidc-mock*|*SSL_CERT_FILE*|*mock-config*|*cert-vol*)
      kube patch statefulset "${STATEFULSET_NAME}" -n "${NAMESPACE}" --type strategic -p \
        '{"spec":{"template":{"spec":{"hostAliases":null,"containers":[{"name":"oidc-mock","$patch":"delete"},{"name":"signoz","env":[{"name":"SSL_CERT_FILE","$patch":"delete"}],"volumeMounts":[{"name":"cert-vol","$patch":"delete"}]}],"volumes":[{"name":"mock-config","$patch":"delete"},{"name":"cert-vol","$patch":"delete"}]}}}}'
      ;;
  esac

  remaining_state="$(legacy_state)"
  case "${remaining_state}" in
    *accounts.google.com*|*oidc-mock*|*SSL_CERT_FILE*|*mock-config*|*cert-vol*)
      fail "StatefulSet '${STATEFULSET_NAME}' still contains the obsolete OIDC mock configuration"
      ;;
  esac
fi

kube delete configmap signoz-oidc-mock -n "${NAMESPACE}" --ignore-not-found=true
kube delete secret mock-google-cert -n "${NAMESPACE}" --ignore-not-found=true
kube delete job "${LEGACY_HOOK_NAME}" -n "${NAMESPACE}" --ignore-not-found=true
kube delete role "${LEGACY_HOOK_NAME}" -n "${NAMESPACE}" --ignore-not-found=true
kube delete rolebinding "${LEGACY_HOOK_NAME}" -n "${NAMESPACE}" --ignore-not-found=true
kube delete serviceaccount "${LEGACY_HOOK_NAME}" -n "${NAMESPACE}" --ignore-not-found=true

for resource in \
  "configmap/signoz-oidc-mock" \
  "secret/mock-google-cert" \
  "job/${LEGACY_HOOK_NAME}" \
  "role/${LEGACY_HOOK_NAME}" \
  "rolebinding/${LEGACY_HOOK_NAME}" \
  "serviceaccount/${LEGACY_HOOK_NAME}"
do
  if kube get "${resource}" -n "${NAMESPACE}" >/dev/null 2>&1; then
    fail "obsolete resource '${resource}' still exists"
  fi
done

echo "Obsolete SigNoz OIDC mock resources and StatefulSet settings are absent."
