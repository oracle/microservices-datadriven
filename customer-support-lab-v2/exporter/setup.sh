#!/bin/bash
# Idempotent, additive monitoring setup for both fresh and existing lab databases.
set -euo pipefail
[[ ${APP_DB_USERNAME} =~ ^[A-Za-z][A-Za-z0-9_]*$ ]] || {
  echo 'APP_DB_USERNAME must be a simple Oracle identifier.' >&2; exit 1;
}
[[ ${METRICS_DB_PASSWORD} =~ ^[A-Za-z0-9_.!#%+-]+$ ]] || {
  echo 'METRICS_DB_PASSWORD must use letters, digits, or . _ ! # % + -.' >&2; exit 1;
}
sqlplus -L -s /nolog <<SQL
whenever sqlerror exit failure
whenever oserror exit failure
set echo off verify off feedback off heading off
connect sys/"${ORACLE_PWD}"@//oracle-free:1521/FREE as sysdba
@/exporter/setup.sql "${APP_DB_USERNAME^^}" "${METRICS_DB_PASSWORD}"
exit
SQL
