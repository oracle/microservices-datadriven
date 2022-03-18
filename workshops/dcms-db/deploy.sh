#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

# Make sure this is executed and not sourced
if (return 0 2>/dev/null) ; then
  echo "ERROR: Usage './deploy.sh plsql|js'"
  exit 1
fi

if test "$1" == 'plsql'; then
  inv_svc=inventory-db-plsql.sql
  ord_svc=order-db-plsql.sql
elif test "$1" == 'js'; then
  inv_svc=inventory-db-js-wrapper.sql
  ord_svc=order-db-js-wrapper.sql
else
  echo "ERROR: Usage './deploy.sh plsql|js'"
fi

# Environment must be setup before running this script
if test -z "$DCMS_STATE"; then
  echo "ERROR: Workshop environment not setup"
  exit 1
fi

# Get the setup status
if ! DCMS_STATUS=$(provisioning-get-status $DCMS_STATE); then
  echo "ERROR: Unable to get workshop provisioning status"
  exit 1
fi

if test "$DCMS_STATUS" != 'applied'; then
  echo "ERROR: Setup status $DCMS_STATUS.  Not ready for deploy."
  exit 1
fi

# Collect DB password
while true; do
  if test -z "${TEST_DB_PASSWORD-}"; then
    read -s -r -p "Enter the database password: " PW
  else
    PW="${TEST_DB_PASSWORD-}"
  fi
  if [[ ${#PW} -ge 12 && ${#PW} -le 30 && "$PW" =~ [A-Z] && "$PW" =~ [a-z] && "$PW" =~ [0-9] && "$PW" != *admin* && "$PW" != *'"'* ]]; then
    echo
    DB_PASSWORD="$PW"
    break
  else
    echo "Invalid Password, please retry"
  fi
done

ssh -o StrictHostKeyChecking=false -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) <<!
sudo su - oracle
cd ~/db/common/apply

# Execute the sql scripts
export TNS_ADMIN=~/tns_admin

sqlplus /nolog <<EOF
connect inventoryuser/'${DB_PASSWORD}'@$(state_get DB_ALIAS)
@inventory-db-undeploy.sql
@${inv_svc}
@inventory-db-deploy.sql
EOF

sqlplus /nolog <<EOF
connect orderuser/'${DB_PASSWORD}'@$(state_get DB_ALIAS)
@order-db-undeploy.sql
@${ord_svc}
@order-db-deploy.sql
EOF
!
