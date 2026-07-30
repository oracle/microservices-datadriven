#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="${CHART_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
DASHBOARD_DIR="${CHART_DIR}/dashboards"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

queries="${TMP}/promql-queries.txt"
: >"${queries}"

while IFS= read -r -d '' dashboard; do
  jq empty "${dashboard}" >/dev/null
  jq -r '
    .. | objects | .promql? // empty | .[]? |
    select((.disabled // false) == false) |
    .query? // empty |
    select(length > 0)
  ' "${dashboard}" >>"${queries}"
done < <(find "${DASHBOARD_DIR}" -type f -name '*.json' -print0)

# SigNoZ 0.134.0 anchors PromQL regex matchers. Require every regex matcher to
# make its intent explicit: a dashboard variable, an explicit anchor, or a
# leading .* for substring matching.
unsafe="${TMP}/unsafe-regex.txt"
perl -ne '
  while (/(?:=~|!~)\s*"([^"]*)"/g) {
    $pattern = $1;
    next if $pattern =~ /^(?:\$|\^|\.\*)/;
    print "$pattern\n";
  }
' "${queries}" >"${unsafe}"

if [ -s "${unsafe}" ]; then
  echo "PromQL regex matchers with ambiguous pre-0.134.0 substring semantics:" >&2
  sort -u "${unsafe}" >&2
  exit 1
fi

actuator_count="$(
  grep -Fo 'uri !~ ".*actuator.*"' "${queries}" | wc -l | tr -d ' '
)"
[ "${actuator_count}" = "3" ] || {
  echo "Expected three Spring Boot actuator substring exclusions; found ${actuator_count}" >&2
  exit 1
}

# Prometheus-scraped Helidon metrics use the Kubernetes discovery label
# `kubernetes_namespace`. A legacy `namespace` matcher appears to work with an
# ALL (`.*`) selection because it also matches a missing label, but dependent
# variables return no values.
for dashboard in \
  "${DASHBOARD_DIR}/2/helidon_main_dashboard.json" \
  "${DASHBOARD_DIR}/2/helidon_mp_details.json" \
  "${DASHBOARD_DIR}/2/helidon_jvm_details.json" \
  "${DASHBOARD_DIR}/2/helidon_se_details.json"; do
  if grep -Fq "JSONExtractString(labels, 'namespace')" "${dashboard}"; then
    echo "Legacy Helidon namespace variable query in ${dashboard}" >&2
    exit 1
  fi
  if jq -r '.. | objects | .promql? // empty | .[]? | .query? // empty' \
    "${dashboard}" | grep -Eq '(^|[,{[:space:]])namespace=~'; then
    echo "Legacy Helidon PromQL namespace matcher in ${dashboard}" >&2
    exit 1
  fi
  grep -Fq "JSONExtractString(labels, 'kubernetes_namespace')" "${dashboard}" || {
    echo "Missing Helidon Kubernetes namespace variable query in ${dashboard}" >&2
    exit 1
  }
  jq -r '.. | objects | .promql? // empty | .[]? | .query? // empty' \
    "${dashboard}" | grep -Fq 'kubernetes_namespace=~' || {
    echo "Missing Helidon Kubernetes namespace PromQL matcher in ${dashboard}" >&2
    exit 1
  }
done

# The JVM details request-rate panel must report a per-second rate. `increase`
# returns the total requests in the lookback window and must not be labeled RPS.
jvm_dashboard="${CHART_DIR}/dashboards/2/helidon_jvm_details.json"
grep -Fq 'sum(rate(requests_count_total{kubernetes_namespace=~\"$namespace\", mp_app=~\"$app_name\"}[1m]))' \
  "${jvm_dashboard}" || {
  echo "Helidon JVM Requests Per Second panel does not use rate()" >&2
  exit 1
}

if grep -Fq 'sum(increase(requests_count_total{kubernetes_namespace=~\"$namespace\", mp_app=~\"$app_name\"}' \
  "${jvm_dashboard}"; then
  echo "Helidon JVM Requests Per Second panel still uses increase()" >&2
  exit 1
fi

echo "SigNoZ PromQL anchored-regex compatibility test passed"
