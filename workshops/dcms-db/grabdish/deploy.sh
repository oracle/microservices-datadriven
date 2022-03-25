#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

# Parameters:
_language=${1-plsql}      # plsql(default) / js

# Make sure this is executed and not sourced
if (return 0 2>/dev/null) ; then
  echo "ERROR: Usage './deploy.sh plsql/js'"
  exit 1
fi

# Source the helper functions
source $DCMS_APP_CODE/source.env

# Collect DB password
DB_PASSWORD=""
collect_adbs_db_password

# Set DB admin password
set_adbs_admin_password "$(state_get DB_OCID)"

# DB Setup
grabdish_db_setup $(state_get DB_ALIAS) $(state_get QUEUE_TYPE)

# Deploy Order Service
deploy_service order $(state_get DB_ALIAS) ${_language}

# Deploy inventory Service
deploy_service inventory $(state_get DB_ALIAS) ${_language}

# Collect UI password
UI_PASSWORD=""
collect_ui_password

# Setup ORDS
setup_ords $(state_get ORDS_ADDRESS) $(state_get SSH_PRIVATE_KEY_FILE) $(state_get DB_ALIAS) $(state_get TNS_ADMIN_ZIP_FILE)
