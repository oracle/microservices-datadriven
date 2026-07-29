#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${MOCK_STATE_DIR:?MOCK_STATE_DIR is required}"
SCENARIO="${MOCK_SCENARIO:-success}"
last_argument="${!#}"
printf '%s\n' "$*" >>"${STATE_DIR}/kubectl.log"

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

if [[ "$1" == "config" && "$2" == "current-context" ]]; then
  echo "mock-oke"
  exit 0
fi

if [[ "$1" == "apply" && "$2" == "-f" ]]; then
  echo "customresourcedefinition configured"
  exit 0
fi

if [[ "$1" == "get" && "$2" == "crd" ]]; then
  exit 0
fi

if [[ "$1" == "wait" && "$2" == "--for=condition=Established" ]]; then
  exit 0
fi

if [[ "$1" == "get" && "$2" == "volumesnapshotclass.snapshot.storage.k8s.io" ]]; then
  [[ -f "${STATE_DIR}/class.yaml" ]] || exit 1
  case "${last_argument}" in
    *'{.driver}'*) echo "blockvolume.csi.oraclecloud.com" ;;
    *'{.deletionPolicy}'*) echo "Retain" ;;
    *'{.parameters.backupType}'*) echo "full" ;;
  esac
  exit 0
fi

if [[ "$1" == "create" && "$2" == "-f" && "$3" == "-" ]]; then
  tee "${STATE_DIR}/class.yaml" >/dev/null
  echo "volumesnapshotclass.snapshot.storage.k8s.io/obaas-oci-bv-snapshot created"
  exit 0
fi

if [[ "$1" == "get" && "$2" == "pods" ]]; then
  selector="$(argument_after -l "$@")"
  case "${selector}" in
    *app.kubernetes.io/name=signoz*) echo "signoz-db" ;;
    *app.kubernetes.io/name=clickhouse*) echo "clickhouse-data" ;;
    *app.kubernetes.io/name=zookeeper*) echo "zookeeper-data" ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if [[ "$1" == "get" && "$2" == "pvc" ]]; then
  pvc="$3"
  case "${last_argument}" in
    *'{.status.phase}'*) echo "Bound" ;;
    *'{.spec.storageClassName}'*) echo "oci-bv" ;;
    *'{.spec.volumeName}'*) echo "pv-${pvc}" ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if [[ "$1" == "get" && "$2" == "storageclass" ]]; then
  echo "blockvolume.csi.oraclecloud.com"
  exit 0
fi

if [[ "$1" == "get" && "$2" == "pv" ]]; then
  case "${last_argument}" in
    *'{.spec.csi.driver}'*)
      [[ "${SCENARIO}" == "wrong-driver" ]] && echo "other.csi.example.com" || echo "blockvolume.csi.oraclecloud.com"
      ;;
    *'{.spec.csi.volumeHandle}'*) echo "ocid1.volume.oc1.iad.mock" ;;
    *) exit 1 ;;
  esac
  exit 0
fi

echo "Unexpected mock kubectl invocation: $*" >&2
exit 1
