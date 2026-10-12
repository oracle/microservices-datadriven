#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/.

# The Oracle image sources startup hooks. Use a subshell to keep setup state local.
(
    set -euo pipefail
    rm -f /tmp/lab-schema-ready
    export ADMIN_DB_USERNAME=sys
    export ADMIN_DB_PASSWORD="${ORACLE_PWD}"
    export ADMIN_DB_CONNECT=localhost:1521/FREEPDB1
    export ADMIN_DB_ROLE=sysdba
    bash /opt/oracle/lab/scripts/setup-lab.sh --if-needed
    touch /tmp/lab-schema-ready
)
