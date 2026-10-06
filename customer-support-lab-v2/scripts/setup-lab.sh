#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/setup-lab.sh [--dry-run]

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

SQL client input limits:
  Usernames use letters, digits, and underscore, starting with a letter.
  Passwords use letters, digits, . _ ! # % + or -.
  ADMIN_DB_ROLE, when set, must be sysdba.

Example:
  export APP_DB_USERNAME=lab_user
  export APP_DB_PASSWORD='choose-a-strong-password'
  export ADMIN_DB_USERNAME=admin
  export ADMIN_DB_PASSWORD='admin-password'
  export ADMIN_DB_CONNECT=localhost:1521/freepdb1
  scripts/setup-lab.sh

  # Docker / local Oracle (requires sysdba for gv$ grants):
  export ADMIN_DB_USERNAME=sys
  export ADMIN_DB_ROLE=sysdba
  scripts/setup-lab.sh
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

# This small setup uses SQLcl/SQL*Plus substitution for CREATE USER and
# CONNECT. Reject characters those clients can interpret as SQL or commands.
identifier_pattern='^[A-Za-z][A-Za-z0-9_]*$'
password_pattern='^[A-Za-z0-9_.!#%+-]+$'
connect_pattern='^[A-Za-z0-9_.:/(),=-]+$'
for var in APP_DB_USERNAME ADMIN_DB_USERNAME; do
  if [[ ! "${!var}" =~ ${identifier_pattern} ]]; then
    echo "${var} must be a simple unquoted Oracle username (letters, digits, underscore)." >&2
    exit 1
  fi
done
for var in APP_DB_PASSWORD ADMIN_DB_PASSWORD; do
  if [[ ! "${!var}" =~ ${password_pattern} ]]; then
    echo "${var} contains a character this SQL client setup cannot safely pass; use letters, digits, . _ ! # % + or -." >&2
    exit 1
  fi
done
if [[ ! "${ADMIN_DB_CONNECT}" =~ ${connect_pattern} ]]; then
  echo "ADMIN_DB_CONNECT must be a host:port/service, TNS alias, or simple Oracle connect descriptor." >&2
  exit 1
fi
if [[ -n "${ADMIN_DB_ROLE:-}" && "${ADMIN_DB_ROLE}" != "sysdba" ]]; then
  echo "ADMIN_DB_ROLE may only be sysdba for this lab." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
user_sql="${repo_root}/db/user.sql"
schema_sql="${repo_root}/db/init.sql"

if [[ "${dry_run}" == "true" ]]; then
  if command -v sql >/dev/null 2>&1; then
    sql_runner="sql"
  elif command -v sqlplus >/dev/null 2>&1; then
    sql_runner="sqlplus"
  else
    sql_runner="sql or sqlplus"
  fi
  cat <<EOF
Dry run: would execute ${user_sql} and ${schema_sql} with ${sql_runner}
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
whenever sqlerror exit failure
whenever oserror exit failure
set verify off
connect ${ADMIN_DB_USERNAME}/${ADMIN_DB_PASSWORD}@${ADMIN_DB_CONNECT}${ADMIN_DB_ROLE:+ as ${ADMIN_DB_ROLE}}
define app_username=${APP_DB_USERNAME}
define app_password=${APP_DB_PASSWORD}
@${user_sql}
connect ${APP_DB_USERNAME}/${APP_DB_PASSWORD}@${ADMIN_DB_CONNECT}
@${schema_sql}
exit
EOF
