#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

scenario="${MOCK_SCENARIO:-success}"
output_dir="${MOCK_OUTPUT_DIR:?MOCK_OUTPUT_DIR is required}"
args="$*"

if [[ "${args}" == "get secret obaas-signoz-upgrade-0-134-0-stage1 -n obaas" ]]; then
  [[ "${scenario}" == "marker-exists" ]] && exit 0
  exit 1
fi

if [[ "${args}" == *"get volumesnapshot.snapshot.storage.k8s.io"*"-o name"* ]]; then
  printf '%s\n' volumesnapshot.snapshot.storage.k8s.io/snap-signoz \
    volumesnapshot.snapshot.storage.k8s.io/snap-clickhouse \
    volumesnapshot.snapshot.storage.k8s.io/snap-zookeeper
  exit 0
fi

if [[ "${args}" == *"get pods"*"claimName"* ]]; then
  case "${args}" in
    *"app.kubernetes.io/name=signoz"*) echo signoz-pvc ;;
    *"app.kubernetes.io/name=clickhouse"*) echo clickhouse-pvc ;;
    *"app.kubernetes.io/name=zookeeper"*) echo zookeeper-pvc ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if [[ "$1 $2" == "get pvc" ]]; then
  echo "uid-$3"
  exit 0
fi

if [[ "$1" == "get" && "$2" == volumesnapshot.snapshot.storage.k8s.io/* ]]; then
  snapshot="${2##*/}"
  case "${args}" in
    *source-pvc-uid*) echo "uid-${snapshot#snap-}-pvc" ;;
    *source-pvc*) echo "${snapshot#snap-}-pvc" ;;
    *readyToUse*)
      if [[ "${scenario}" == "snapshot-not-ready" && "${snapshot}" == "snap-clickhouse" ]]; then
        echo false
      else
        echo true
      fi
      ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if [[ "${args}" == *"get pods"*"items[0].metadata.name"* ]]; then
  echo chi-obaas-clickhouse-cluster-0-0-0
  exit 0
fi

if [[ "$1 $2" == "wait pod" ]]; then
  exit 0
fi

if [[ "$1 $2" == "get pod" && "${args}" == *"containers"*"image"* ]]; then
  if [[ "${scenario}" == "wrong-clickhouse" ]]; then
    echo clickhouse/clickhouse-server:25.5.6
  else
    echo clickhouse/clickhouse-server:25.12.5
  fi
  exit 0
fi

if [[ "${args}" == *"get clickhouseinstallations.clickhouse.altinity.com -n"* ]]; then
  echo obaas-clickhouse-cluster
  exit 0
fi

if [[ "${args}" == *"get clickhouseinstallation.clickhouse.altinity.com obaas-clickhouse-cluster"* ]]; then
  echo test-password
  exit 0
fi

if [[ "$1" == "exec" ]]; then
  case "${args}" in
    *"SELECT version()"*) echo 25.12.5.1 ;;
    *"SELECT toString(sum(rows))"*) echo 12345 ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if [[ "$1 $2 $3" == "create -f -" ]]; then
  [[ "${scenario}" == "create-fails" ]] && exit 1
  cat >"${output_dir}/marker.yaml"
  exit 0
fi

echo "Unexpected kubectl command: $*" >&2
exit 1
