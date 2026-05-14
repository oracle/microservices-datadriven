#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

# Print CLI usage. Kept in the script so --help stays accurate as options evolve.
usage() {
  cat >&2 <<'USAGE'
Usage:
  ./get-adb-ocid.sh -r <region> (-c <compartment-name> | --compartment-ocid <ocid>) -dbname <adb-display-name> [options]

Required:
  -r, --region <region>              OCI region, for example us-sanjose-1
  -dbname, --dbname <name>           Autonomous Database display name

Compartment:
  -c, --compartment <name>           Compartment name to resolve
      --compartment-ocid <ocid>      Compartment OCID to use directly

Options:
      --profile <profile>            OCI CLI profile to use
      --verbose                      Print lookup details to stderr
  -h, --help                         Show this help

Examples:
  ./get-adb-ocid.sh -r us-sanjose-1 -c andytael -dbname helmtest
  ./get-adb-ocid.sh -r us-sanjose-1 --compartment-ocid ocid1.compartment... -dbname helmtest
  ./get-adb-ocid.sh -r us-sanjose-1 -c andytael -dbname helmtest --profile myprofile

Notes:
  The script only returns AVAILABLE Autonomous Databases.
  Database display-name matching is case-insensitive.
  The script fails if zero or multiple matches are found.
USAGE
}

usage_error() {
  echo "ERROR: $*" >&2
  usage
  exit 2
}

log_verbose() {
  if [[ "$VERBOSE" == "true" ]]; then
    echo "$*" >&2
  fi
}

# Reject missing flag values early; this avoids treating the next option as a value.
require_value() {
  local option="$1"
  local value="${2:-}"

  if [[ -z "$value" || "$value" == -* ]]; then
    usage_error "missing value for $option"
  fi
}

# Count only real result rows; OCI/JMESPath queries may return an empty string.
non_empty_line_count() {
  sed '/^[[:space:]]*$/d' | wc -l | tr -d ' '
}

# Centralize OCI invocation so --profile is applied consistently when provided.
run_oci() {
  if [[ -n "$PROFILE" ]]; then
    oci --profile "$PROFILE" "$@"
  else
    oci "$@"
  fi
}

REGION=""
COMPARTMENT_NAME=""
COMPARTMENT_OCID=""
ADB_NAME=""
PROFILE=""
VERBOSE="false"

# Parse named options instead of relying on positional arguments.
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--region)
      require_value "$1" "${2:-}"
      REGION="$2"
      shift 2
      ;;
    -c|--compartment)
      require_value "$1" "${2:-}"
      COMPARTMENT_NAME="$2"
      shift 2
      ;;
    --compartment-ocid)
      require_value "$1" "${2:-}"
      COMPARTMENT_OCID="$2"
      shift 2
      ;;
    -dbname|--dbname)
      require_value "$1" "${2:-}"
      ADB_NAME="$2"
      shift 2
      ;;
    --profile)
      require_value "$1" "${2:-}"
      PROFILE="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage_error "unknown argument: $1"
      ;;
  esac
done

# Fail fast if the OCI CLI is not installed or not available on PATH.
if ! command -v oci >/dev/null 2>&1; then
  echo "ERROR: oci CLI not found" >&2
  exit 127
fi

if [[ -z "$REGION" || -z "$ADB_NAME" ]]; then
  usage_error "-r and -dbname are required"
fi

if [[ -n "$COMPARTMENT_NAME" && -n "$COMPARTMENT_OCID" ]]; then
  usage_error "use either -c/--compartment or --compartment-ocid, not both"
fi

if [[ -z "$COMPARTMENT_NAME" && -z "$COMPARTMENT_OCID" ]]; then
  usage_error "one of -c/--compartment or --compartment-ocid is required"
fi

# Resolve a compartment name to an OCID unless the caller already supplied one.
if [[ -n "$PROFILE" ]]; then
  log_verbose "Using OCI profile: $PROFILE"
fi

log_verbose "Using region: $REGION"

if [[ -z "$COMPARTMENT_OCID" ]]; then
  log_verbose "Resolving active compartment named: $COMPARTMENT_NAME"

  COMPARTMENT_MATCHES="$(
    run_oci iam compartment list \
      --region "$REGION" \
      --compartment-id-in-subtree true \
      --access-level ANY \
      --lifecycle-state ACTIVE \
      --name "$COMPARTMENT_NAME" \
      --all \
      --query 'join(`\n`, data[?name == `'"$COMPARTMENT_NAME"'`].[join(` | `, [name, id])][] )' \
      --raw-output
  )"

  COMPARTMENT_COUNT="$(printf '%s\n' "$COMPARTMENT_MATCHES" | non_empty_line_count)"

  if [[ "$COMPARTMENT_COUNT" -ne 1 ]]; then
    echo "ERROR: expected exactly 1 active compartment named '$COMPARTMENT_NAME', found $COMPARTMENT_COUNT" >&2
    if [[ "$COMPARTMENT_COUNT" -gt 0 ]]; then
      echo "Matching compartments:" >&2
      printf '%s\n' "$COMPARTMENT_MATCHES" >&2
    fi
    exit 1
  fi

  COMPARTMENT_OCID="$(printf '%s\n' "$COMPARTMENT_MATCHES" | sed '/^[[:space:]]*$/d' | awk -F '|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')"
  log_verbose "Resolved compartment OCID: $COMPARTMENT_OCID"
else
  log_verbose "Using provided compartment OCID: $COMPARTMENT_OCID"
fi

# Search only AVAILABLE ADBs; terminated databases can otherwise create false duplicates.
log_verbose "Searching for AVAILABLE Autonomous Database display name: $ADB_NAME"

ADB_MATCHES="$(
  run_oci db autonomous-database list \
    --region "$REGION" \
    --compartment-id "$COMPARTMENT_OCID" \
    --display-name "$ADB_NAME" \
    --lifecycle-state AVAILABLE \
    --all \
    --query 'join(`\n`, data[].[join(` | `, ["display-name", "lifecycle-state", id])][] )' \
    --raw-output
)"

# OCI display-name filtering is case-insensitive in practice, so normalize locally too.
ADB_MATCHES="$(
  printf '%s\n' "$ADB_MATCHES" |
    awk -F '|' -v target="$ADB_NAME" '
      function trim(value) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        return value
      }
      trim($1) != "" && tolower(trim($1)) == tolower(target)
    '
)"

ADB_COUNT="$(printf '%s\n' "$ADB_MATCHES" | non_empty_line_count)"

# Refuse ambiguous or missing results instead of guessing which database the caller meant.
if [[ "$ADB_COUNT" -ne 1 ]]; then
  echo "ERROR: expected exactly 1 AVAILABLE Autonomous Database named '$ADB_NAME' in compartment '$COMPARTMENT_OCID', found $ADB_COUNT" >&2
  if [[ "$ADB_COUNT" -gt 0 ]]; then
    echo "Matching Autonomous Databases:" >&2
    printf '%s\n' "$ADB_MATCHES" >&2
  fi
  exit 1
fi

ADB_OCID="$(printf '%s\n' "$ADB_MATCHES" | sed '/^[[:space:]]*$/d' | awk -F '|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3}')"

# Keep stdout machine-readable: emit only the final OCID.
log_verbose "Resolved Autonomous Database OCID: $ADB_OCID"
printf '%s\n' "$ADB_OCID"
