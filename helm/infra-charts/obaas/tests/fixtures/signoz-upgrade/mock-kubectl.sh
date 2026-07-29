#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${MOCK_SCENARIO:-success}"
OUTPUT_DIR="${MOCK_OUTPUT_DIR:?MOCK_OUTPUT_DIR is required}"

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

last_argument="${!#}"

if [[ "$1" == "delete" && "$2" == "secret" ]]; then
  exit 0
fi

if [[ "$1" == "api-resources" ]]; then
  echo "volumesnapshots.snapshot.storage.k8s.io"
  echo "volumesnapshotclasses.snapshot.storage.k8s.io"
  if [[ "${SCENARIO}" != "missing-crd" ]]; then
    echo "volumesnapshotcontents.snapshot.storage.k8s.io"
  fi
  exit 0
fi

if [[ "$1" == "get" && "$2" == "pods" ]]; then
  selector="$(argument_after -l "$@")"
  case "${selector}" in
    *app.kubernetes.io/name=signoz*) echo "signoz-db-obaas-signoz-0" ;;
    *app.kubernetes.io/name=clickhouse*) echo "data-volumeclaim-template-chi-0-0-0" ;;
    *app.kubernetes.io/name=zookeeper*)
      [[ "${SCENARIO}" == "missing-pvc" ]] || echo "data-obaas-zookeeper-0"
      ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if [[ "$1" == "get" && "$2" == "pvc" ]]; then
  pvc="$3"
  case "${last_argument}" in
    *status.phase*)
      [[ "${SCENARIO}" == "unbound-pvc" && "${pvc}" == signoz-* ]] && echo "Pending" || echo "Bound"
      ;;
    *metadata.uid*) echo "uid-${pvc}" ;;
    *spec.volumeName*) echo "pv-${pvc}" ;;
    *spec.storageClassName*)
      if [[ "${SCENARIO}" == "mapped-classes" ]]; then
        [[ "${pvc}" == signoz-* ]] && echo "fast-sc" || echo "block-sc"
      else
        echo "shared-sc"
      fi
      ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if [[ "$1" == "get" && "$2" == "storageclass" ]]; then
  case "$3" in
    shared-sc) echo "csi.example.com" ;;
    fast-sc) echo "fast.csi.example.com" ;;
    block-sc) echo "block.csi.example.com" ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if [[ "$1" == "get" && "$2" == "pv" ]]; then
  pv="$3"
  if [[ "${last_argument}" == *'{.spec.csi.driver}'* ]]; then
    if [[ "${SCENARIO}" == "non-csi-pv" ]]; then
      exit 0
    elif [[ "${SCENARIO}" == "mismatched-pv-driver" ]]; then
      echo "other.csi.example.com"
    elif [[ "${pv}" == *signoz-* && "${SCENARIO}" == "mapped-classes" ]]; then
      echo "fast.csi.example.com"
    elif [[ "${SCENARIO}" == "mapped-classes" ]]; then
      echo "block.csi.example.com"
    else
      echo "csi.example.com"
    fi
  fi
  exit 0
fi

if [[ "$1" == "get" && "$2" == "volumesnapshotclasses.snapshot.storage.k8s.io" && "$3" == "-o" ]]; then
  [[ "${SCENARIO}" == "missing-class" ]] && exit 0
  echo "volumesnapshotclass.snapshot.storage.k8s.io/default-snap"
  if [[ "${SCENARIO}" == "multiple-defaults" ]]; then
    echo "volumesnapshotclass.snapshot.storage.k8s.io/second-default-snap"
  fi
  exit 0
fi

if [[ "$1" == "get" && "$2" == volumesnapshotclass.snapshot.storage.k8s.io/* ]]; then
  class="${2##*/}"
  case "${last_argument}" in
    *'{.driver}'*)
      case "${class}" in
        default-snap|second-default-snap) echo "csi.example.com" ;;
        *) exit 1 ;;
      esac
      ;;
    *is-default-class*) echo "true" ;;
    *) exit 1 ;;
  esac
  exit 0
fi

if [[ "$1" == "get" && "$2" == "volumesnapshotclass.snapshot.storage.k8s.io" ]]; then
  class="$3"
  [[ "${SCENARIO}" == "missing-explicit-class" ]] && exit 1
  if [[ "${last_argument}" == *'{.driver}'* ]]; then
    case "${class}" in
      fast-snap) echo "fast.csi.example.com" ;;
      block-snap) echo "block.csi.example.com" ;;
      wrong-snap) echo "other.csi.example.com" ;;
      default-snap) echo "csi.example.com" ;;
      *) exit 1 ;;
    esac
  fi
  exit 0
fi

if [[ "$1" == "create" && "$2" == "-f" && "$3" == "-" ]]; then
  counter_file="${OUTPUT_DIR}/count"
  counter=0
  [[ ! -f "${counter_file}" ]] || counter="$(<"${counter_file}")"
  counter=$((counter + 1))
  echo "${counter}" >"${counter_file}"
  tee "${OUTPUT_DIR}/snapshot-${counter}.yaml" >/dev/null
  echo "volumesnapshot.snapshot.storage.k8s.io/mock-${counter} created"
  exit 0
fi

if [[ "$1" == "wait" ]]; then
  [[ "${SCENARIO}" == "timeout" ]] && exit 1
  echo "volumesnapshot.snapshot.storage.k8s.io snapshots ready"
  exit 0
fi

if [[ "$1" == "get" && "$2" == "volumesnapshot.snapshot.storage.k8s.io" ]]; then
  echo "NAME READYTOUSE"
  echo "mock true"
  exit 0
fi

echo "Unexpected mock kubectl invocation: $*" >&2
exit 1
