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

# Source the setup functions
source $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/setup_functions.env

deploy_mservice ${DCMS_APP_CODE} 'order'     ${_order_lang}     $(state_get QUEUE_TYPE) $(state_get DB_ALIAS)
deploy_mservice ${DCMS_APP_CODE} 'inventory' ${_inventory_lang} $(state_get QUEUE_TYPE) $(state_get DB_ALIAS)
