#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

# Parameters:
_language=$1      # plsql / js

# Make sure this is executed and not sourced
if (return 0 2>/dev/null) ; then
  echo "ERROR: Usage './switch.sh plsql/js'"
  exit 1
fi

# Source the helper functions
source $DCMS_APP_CODE/source.env

# Deploy Order Service
deploy_service order $(state_get DB_ALIAS) ${_language}

# Deploy inventory Service
deploy_service inventory $(state_get DB_ALIAS) ${_language}
