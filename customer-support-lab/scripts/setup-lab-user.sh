#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/setup-lab-user.sh [--dry-run]

Requires:
  APP_DB_USERNAME     Application schema username to create
  APP_DB_PASSWORD     Application schema password to set
  ADMIN_DB_USERNAME   Admin database username (e.g. admin, sys)
  ADMIN_DB_PASSWORD   Admin database password
  ADMIN_DB_CONNECT    Database connect descriptor (e.g. localhost:1521/freepdb1)

Optional:
  ADMIN_DB_ROLE       Database role to connect as (e.g. sysdba). Required when
                      using sys on a local/Docker database where system lacks
                      WITH GRANT OPTION on SYS-owned objects.

Example:
  export APP_DB_USERNAME=lab_user
  export APP_DB_PASSWORD='choose-a-strong-password'
  export ADMIN_DB_USERNAME=admin
  export ADMIN_DB_PASSWORD='admin-password'
  export ADMIN_DB_CONNECT=localhost:1521/freepdb1
  scripts/setup-lab-user.sh

  # Docker / local Oracle (requires sysdba for gv$ grants):
  export ADMIN_DB_USERNAME=sys
  export ADMIN_DB_ROLE=sysdba
  scripts/setup-lab-user.sh
EOF
}

dry_run=false
if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=true
  shift
fi

if [[ $# -ne 0 ]]; then
  usage >&2
  exit 1
fi

missing=()
for var in APP_DB_USERNAME APP_DB_PASSWORD ADMIN_DB_USERNAME ADMIN_DB_PASSWORD ADMIN_DB_CONNECT; do
  [[ -z "${!var:-}" ]] && missing+=("${var}")
done
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Missing required environment variable(s): ${missing[*]}" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
user_sql="${repo_root}/src/test/resources/user.sql"

if [[ "${dry_run}" == "true" ]]; then
  if command -v sql >/dev/null 2>&1; then
    sql_runner="sql"
  elif command -v sqlplus >/dev/null 2>&1; then
    sql_runner="sqlplus"
  else
    sql_runner="sql or sqlplus"
  fi
  cat <<EOF
Dry run: would execute ${user_sql} with ${sql_runner}
Admin connect: ${ADMIN_DB_USERNAME}@${ADMIN_DB_CONNECT}${ADMIN_DB_ROLE:+ as ${ADMIN_DB_ROLE}}
Admin password: [redacted]
App username: ${APP_DB_USERNAME}
App password: [redacted]
EOF
  exit 0
fi

if command -v sql >/dev/null 2>&1; then
  sql_runner="sql"
elif command -v sqlplus >/dev/null 2>&1; then
  sql_runner="sqlplus"
else
  echo "Neither sql nor sqlplus is available on PATH." >&2
  exit 1
fi

# Credentials are passed via stdin, not as CLI arguments, so they do not
# appear in the process listing or shell history.
"${sql_runner}" /nolog <<EOF
connect ${ADMIN_DB_USERNAME}/${ADMIN_DB_PASSWORD}@${ADMIN_DB_CONNECT}${ADMIN_DB_ROLE:+ as ${ADMIN_DB_ROLE}}
define app_username=${APP_DB_USERNAME}
define app_password=${APP_DB_PASSWORD}
@${user_sql}
exit
EOF
