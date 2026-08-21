#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

SCENARIO="${MOCK_SCENARIO:-success}"
OUTPUT_DIR="${MOCK_OUTPUT_DIR:?MOCK_OUTPUT_DIR is required}"
last_argument="${!#}"

if [[ "$1" == "wait" ]]; then
  [[ "${SCENARIO}" == "pods-not-ready" ]] && exit 1
  exit 0
fi

if [[ "$1" == "get" && "$2" == "pods" ]]; then
  if [[ "${last_argument}" == *'items[0].metadata.name'* ]]; then
    echo "clickhouse-0-0-0"
  else
    args="$*"
    case "${args}" in
      *app.kubernetes.io/name=signoz*) echo "signoz-db-obaas-0" ;;
      *app.kubernetes.io/name=clickhouse*) echo "data-volumeclaim-template-chi-0-0-0" ;;
      *app.kubernetes.io/name=zookeeper*) echo "data-obaas-zookeeper-0" ;;
      *) exit 1 ;;
    esac
  fi
  exit 0
fi

if [[ "$1" == "get" && "$2" == "pod" ]]; then
  if [[ "${SCENARIO}" == "wrong-image" ]]; then
    echo "docker.io/clickhouse/clickhouse-server:25.5.6"
  elif [[ "${SCENARIO}" == "delayed-rollout" && ! -f "${OUTPUT_DIR}/old-image-observed" ]]; then
    touch "${OUTPUT_DIR}/old-image-observed"
    echo "docker.io/clickhouse/clickhouse-server:25.5.6"
  else
    echo "docker.io/clickhouse/clickhouse-server:25.12.5"
  fi
  exit 0
fi

if [[ "$1" == "get" && "$2" == "clickhouseinstallations.clickhouse.altinity.com" ]]; then
  echo "obaas-clickhouse"
  exit 0
fi

if [[ "$1" == "get" && "$2" == "clickhouseinstallation.clickhouse.altinity.com" ]]; then
  echo "mock-password"
  exit 0
fi

if [[ "$1" == "exec" ]]; then
  if [[ "${SCENARIO}" == "query-failed" ]]; then
    echo "clickhouse-client query failed" >&2
    exit 1
  fi
  if [[ "$*" == *'system.parts'* ]]; then
    echo "100"
  else
    [[ "${SCENARIO}" == "wrong-version" ]] && echo "25.11.1.1" || echo "25.12.5.44"
  fi
  exit 0
fi

if [[ "$1" == "get" && "$2" == "volumesnapshot.snapshot.storage.k8s.io" ]]; then
  echo "volumesnapshot.snapshot.storage.k8s.io/clickhouse-snapshot"
  echo "volumesnapshot.snapshot.storage.k8s.io/signoz-snapshot"
  echo "volumesnapshot.snapshot.storage.k8s.io/zookeeper-snapshot"
  exit 0
fi

if [[ "$1" == "get" && "$2" == volumesnapshot.snapshot.storage.k8s.io/* ]]; then
  snapshot="${2##*/}"
  case "${last_argument}" in
    *source-pvc-uid*)
      if [[ "${SCENARIO}" == "stale-pvc-uid" && "${snapshot}" == "signoz-snapshot" ]]; then
        echo "stale-uid"
      else
        case "${snapshot}" in
          clickhouse-snapshot) echo "uid-data-volumeclaim-template-chi-0-0-0" ;;
          signoz-snapshot) echo "uid-signoz-db-obaas-0" ;;
          zookeeper-snapshot) echo "uid-data-obaas-zookeeper-0" ;;
        esac
      fi
      ;;
    *source-pvc*)
      case "${snapshot}" in
        clickhouse-snapshot) echo "data-volumeclaim-template-chi-0-0-0" ;;
        signoz-snapshot) echo "signoz-db-obaas-0" ;;
        zookeeper-snapshot) echo "data-obaas-zookeeper-0" ;;
      esac
      ;;
    *readyToUse*)
      [[ "${SCENARIO}" == "snapshot-not-ready" && "${snapshot}" == "clickhouse-snapshot" ]] && echo "false" || echo "true"
      ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if [[ "$1" == "get" && "$2" == "pvc" ]]; then
  echo "uid-$3"
  exit 0
fi

if [[ "$1" == "apply" && "$2" == "-f" && "$3" == "-" ]]; then
  if [[ "${SCENARIO}" == "marker-write-failed" ]]; then
    echo "kubectl failed to write marker" >&2
    exit 1
  fi
  tee "${OUTPUT_DIR}/marker.yaml" >/dev/null
  exit 0
fi

echo "Unexpected mock kubectl invocation: $*" >&2
exit 1
