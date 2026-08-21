#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

SCENARIO="${MOCK_SCENARIO:-success}"
last_argument="${!#}"

argument_after() {
  local wanted="$1"
  shift
  while [[ "$#" -gt 1 ]]; do
    if [[ "$1" == "${wanted}" ]]; then
      echo "$2"
      return 0
    fi
    shift
  done
  return 1
}

if [[ "$1" == "get" && "$2" == "secret" && "$3" == "-n" ]]; then
  [[ "${SCENARIO}" == "missing-marker" ]] && exit 0
  echo "obaas-signoz-upgrade-marker"
  exit 0
fi

if [[ "$1" == "get" && "$2" == "secret" && "$3" == "obaas-signoz-upgrade-marker" ]]; then
  case "$*" in
    *'index .data "stage"'*) echo "stage1" ;;
    *'index .data "status"'*) echo "complete" ;;
    *'index .data "releaseName"'*) echo "obaas" ;;
    *'index .data "namespace"'*) echo "obaas" ;;
    *'index .data "clickhouseVersion"'*) echo "25.12.5.1" ;;
    *'index .data "snapshots"'*)
      printf 'signoz\tsignoz-db\tuid-signoz\tsnap-signoz\n'
      printf 'clickhouse\tclickhouse-data\tuid-clickhouse\tsnap-clickhouse\n'
      printf 'zookeeper\tzookeeper-data\tuid-zookeeper\tsnap-zookeeper\n'
      ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if [[ "$1" == "get" && "$2" == "pvc" ]]; then
  case "$3" in
    signoz-db) echo "uid-signoz" ;;
    clickhouse-data) echo "uid-clickhouse" ;;
    zookeeper-data) echo "uid-zookeeper" ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if [[ "$1" == "get" && "$2" == "volumesnapshot.snapshot.storage.k8s.io" ]]; then
  [[ "${SCENARIO}" == "snapshot-not-ready" && "$3" == "snap-clickhouse" ]] && echo "false" || echo "true"
  exit 0
fi

if [[ "$1" == "wait" ]]; then
  [[ "${SCENARIO}" == "stage2-not-ready" && "$2" == "job/signoz-telemetrystore-migrator" ]] && exit 1
  exit 0
fi

if [[ "$1" == "get" && "$2" == "pods" ]]; then
  selector="$(argument_after -l "$@")"
  case "${selector}" in
    *app.kubernetes.io/name=clickhouse*) echo "docker.io/clickhouse/clickhouse-server:25.12.5" ;;
    *app.kubernetes.io/component=signoz*) echo "docker.io/signoz/signoz:v0.134.0" ;;
    *app.kubernetes.io/component=otel-collector*) echo "docker.io/signoz/signoz-otel-collector:v0.144.6" ;;
    *) exit 1 ;;
  esac
  exit 0
fi

echo "Unexpected mock kubectl invocation: $*" >&2
exit 1
