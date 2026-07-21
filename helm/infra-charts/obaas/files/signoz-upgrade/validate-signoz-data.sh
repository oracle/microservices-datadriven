#!/bin/sh
set -eu
SIGNOZ_URL="${SIGNOZ_URL:?}"
COLLECTOR_URL="${COLLECTOR_URL:?}"
CLICKHOUSE_URL="${CLICKHOUSE_URL:?}"
CLICKHOUSE_PASSWORD="${CLICKHOUSE_PASSWORD:?}"
BASELINE_ROWS="${BASELINE_ROWS:?}"

query_rows() {
  curl -fsS -u "admin:${CLICKHOUSE_PASSWORD}" --data-binary \
    "SELECT toString(sum(rows)) FROM system.parts WHERE active AND startsWith(database, 'signoz_')" \
    "${CLICKHOUSE_URL}/"
}

curl -fsS "${SIGNOZ_URL}/api/v1/health" >/dev/null
current_rows="$(query_rows)"
case "${current_rows}" in ''|*[!0-9]*) echo "Invalid ClickHouse row count" >&2; exit 1 ;; esac
[ "${current_rows}" -ge "${BASELINE_ROWS}" ] || { echo "Historical telemetry row count decreased" >&2; exit 1; }

trace_id="$(date +%s)000000000000000000000000"
trace_id="$(printf '%.32s' "${trace_id}")"
start_time="$(date +%s)000000000"
end_time=$((start_time + 1000000))
before="${current_rows}"
curl -fsS -H 'Content-Type: application/json' -X POST "${COLLECTOR_URL}/v1/traces" -d "{\"resourceSpans\":[{\"resource\":{\"attributes\":[{\"key\":\"service.name\",\"value\":{\"stringValue\":\"obaas-phase5-validation\"}}]},\"scopeSpans\":[{\"spans\":[{\"traceId\":\"${trace_id}\",\"spanId\":\"0123456789abcdef\",\"name\":\"phase5-validation\",\"kind\":1,\"startTimeUnixNano\":\"${start_time}\",\"endTimeUnixNano\":\"${end_time}\"}]}]}]}"

attempt=0
while [ "${attempt}" -lt 30 ]; do
  after="$(query_rows)"
  [ "${after}" -gt "${before}" ] && { echo "Historical telemetry and new ingestion validated."; exit 0; }
  attempt=$((attempt + 1))
  sleep 2
done
echo "New telemetry was not observed in ClickHouse" >&2
exit 1
