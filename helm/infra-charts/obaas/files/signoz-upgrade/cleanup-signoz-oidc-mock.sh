#!/bin/sh
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -eu

KUBECTL="${KUBECTL:-kubectl}"
NAMESPACE="${NAMESPACE:?NAMESPACE is required}"
STATEFULSET_NAME="${STATEFULSET_NAME:?STATEFULSET_NAME is required}"
OIDC_MOCK_HOOK_NAME="${OIDC_MOCK_HOOK_NAME:?OIDC_MOCK_HOOK_NAME is required}"

kube() { "${KUBECTL}" "$@"; }
fail() { echo "ERROR: SigNoz OIDC mock cleanup failed: $*" >&2; exit 1; }

oidc_mock_state() {
  kube get statefulset "${STATEFULSET_NAME}" -n "${NAMESPACE}" \
    -o jsonpath='{.spec.template.spec.hostAliases[*].hostnames[*]}{"|"}{.spec.template.spec.containers[*].name}{"|"}{.spec.template.spec.containers[?(@.name=="signoz")].env[*].name}{"|"}{.spec.template.spec.containers[?(@.name=="signoz")].volumeMounts[*].name}{"|"}{.spec.template.spec.volumes[*].name}'
}

if kube get statefulset "${STATEFULSET_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; then
  current_state="$(oidc_mock_state)"
  case "${current_state}" in
    *accounts.google.com*|*oidc-mock*|*SSL_CERT_FILE*|*mock-config*|*cert-vol*)
      kube patch statefulset "${STATEFULSET_NAME}" -n "${NAMESPACE}" --type strategic -p \
        '{"spec":{"template":{"spec":{"hostAliases":null,"containers":[{"name":"oidc-mock","$patch":"delete"},{"name":"signoz","env":[{"name":"SSL_CERT_FILE","$patch":"delete"}],"volumeMounts":[{"name":"cert-vol","$patch":"delete"}]}],"volumes":[{"name":"mock-config","$patch":"delete"},{"name":"cert-vol","$patch":"delete"}]}}}}'
      ;;
  esac

  remaining_state="$(oidc_mock_state)"
  case "${remaining_state}" in
    *accounts.google.com*|*oidc-mock*|*SSL_CERT_FILE*|*mock-config*|*cert-vol*)
      fail "StatefulSet '${STATEFULSET_NAME}' still contains the obsolete OIDC mock configuration"
      ;;
  esac
fi

kube delete configmap signoz-oidc-mock -n "${NAMESPACE}" --ignore-not-found=true
kube delete secret mock-google-cert -n "${NAMESPACE}" --ignore-not-found=true
kube delete job "${OIDC_MOCK_HOOK_NAME}" -n "${NAMESPACE}" --ignore-not-found=true
kube delete role "${OIDC_MOCK_HOOK_NAME}" -n "${NAMESPACE}" --ignore-not-found=true
kube delete rolebinding "${OIDC_MOCK_HOOK_NAME}" -n "${NAMESPACE}" --ignore-not-found=true
kube delete serviceaccount "${OIDC_MOCK_HOOK_NAME}" -n "${NAMESPACE}" --ignore-not-found=true

for resource in \
  "configmap/signoz-oidc-mock" \
  "secret/mock-google-cert" \
  "job/${OIDC_MOCK_HOOK_NAME}" \
  "role/${OIDC_MOCK_HOOK_NAME}" \
  "rolebinding/${OIDC_MOCK_HOOK_NAME}" \
  "serviceaccount/${OIDC_MOCK_HOOK_NAME}"
do
  if kube get "${resource}" -n "${NAMESPACE}" >/dev/null 2>&1; then
    fail "obsolete resource '${resource}' still exists"
  fi
done

echo "Obsolete SigNoz OIDC mock resources and StatefulSet settings are absent."
