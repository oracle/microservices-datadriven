#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

# Parameters:
_order_lang=$1      # plsql / js
_inventory_lang=$2  # plsql / js

# Make sure this is executed and not sourced
if (return 0 2>/dev/null) ; then
  echo "ERROR: Usage './switch.sh plsql/js plsql/js'"
  exit 1
fi

if ! state_done DEPLOYED; then
  echo "ERROR: Grabdish must be deployed before switch can be run"
  exit 1
fi

# Source the setup functions
source $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/setup_functions.env

# Explain what is happening
echo
echo "To switch to a different implementation we need to collect the DB password,"
echo "and replace the service implementations in the database."
echo
echo "The log file is $DCMS_LOG_DIR/config.log"
echo

# Collect DB password
echo "The DB password is required to update the services deployed in the database"
echo
DB_PASSWORD=""
collect_db_password
echo

# Order
if test "${_order_lang}" == "plsql"; then
  l='PL/SQL'
else
  l='JavaScript'
fi
echo
echo "Deploying the Order microservice with language $l ..."
deploy_mservice ${DCMS_APP_CODE} 'order'     ${_order_lang}     $(state_get QUEUE_TYPE) $(state_get DB_ALIAS) >>$DCMS_LOG_DIR/config.log 2>&1
state_set ORDER_LANG "$l"

# Inventory
if test "${_inventory_lang}" == "plsql"; then
  l='PL/SQL'
else
  l='JavaScript'
fi
echo
echo "Deploying the Inventory microservice with language $l ..."
deploy_mservice ${DCMS_APP_CODE} 'inventory' ${_inventory_lang} $(state_get QUEUE_TYPE) $(state_get DB_ALIAS) >>$DCMS_LOG_DIR/config.log 2>&1
state_set INVENTORY_LANG "$l"
