#!/bin/sh
set -eu
KUBECTL="${KUBECTL:-kubectl}"
NAMESPACE="${NAMESPACE:?}"
RELEASE_NAME="${RELEASE_NAME:?}"
TIMEOUT="${VALIDATION_TIMEOUT:?}"
SIGNOZ_VERSION="${SIGNOZ_VERSION:?}"
COLLECTOR_VERSION="${COLLECTOR_VERSION:?}"
kube() { "${KUBECTL}" "$@"; }
fail() { echo "ERROR: Stage 2 validation failed: $*" >&2; exit 1; }

kube wait job/signoz-telemetrystore-migrator -n "${NAMESPACE}" --for=condition=Complete --timeout="${TIMEOUT}" || fail "telemetry migrations did not complete"
kube wait job/${RELEASE_NAME}-signoz-setup -n "${NAMESPACE}" --for=condition=Complete --timeout="${TIMEOUT}" || fail "SigNoz login/dashboard setup did not complete"
kube wait pod -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/component=signoz" --for=condition=Ready --timeout="${TIMEOUT}" || fail "SigNoz is not Ready"
kube wait pod -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/component=otel-collector" --for=condition=Ready --timeout="${TIMEOUT}" || fail "collector is not Ready"

signoz_image="$(kube get pods -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/component=signoz" -o jsonpath='{.items[0].spec.containers[?(@.name=="signoz")].image}')"
collector_image="$(kube get pods -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME},app.kubernetes.io/component=otel-collector" -o jsonpath='{.items[0].spec.containers[?(@.name=="collector")].image}')"
case "${signoz_image}" in *:"${SIGNOZ_VERSION}"|*:"${SIGNOZ_VERSION}"@sha256:*) ;; *) fail "unexpected SigNoz image '${signoz_image}'" ;; esac
case "${collector_image}" in *:"${COLLECTOR_VERSION}"|*:"${COLLECTOR_VERSION}"@sha256:*) ;; *) fail "unexpected collector image '${collector_image}'" ;; esac
echo "SigNoz and collector versions, migrations, login, and dashboards validated."
