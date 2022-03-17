#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

# Make sure this is executed and not sourced
if (return 0 2>/dev/null) ; then
  echo "ERROR: Usage './lockdown.sh'"
  exit 1
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
  echo "ERROR: Setup status $DCMS_STATUS.  Not ready for lockdown."
  exit 1
fi


# Collect DB password
if ! is_secret_set DB_PASSWORD; then
  echo
  echo 'Database passwords must be 12 to 30 characters and contain at least one uppercase letter,'
  echo 'one lowercase letter, and one number. The password cannot contain the double quote (")'
  echo 'character or the word "admin".'
  echo

  while true; do
    if test -z "${TEST_DB_PASSWORD-}"; then
      read -s -r -p "Enter the password to be used for the order and inventory databases: " PW
    else
      PW="${TEST_DB_PASSWORD-}"
    fi
    if [[ ${#PW} -ge 12 && ${#PW} -le 30 && "$PW" =~ [A-Z] && "$PW" =~ [a-z] && "$PW" =~ [0-9] && "$PW" != *admin* && "$PW" != *'"'* ]]; then
      echo
      break
    else
      echo "Invalid Password, please retry"
    fi
  done
  set_secret DB_PASSWORD $PW
  state_set DB_PASSWORD_SECRET "DB_PASSWORD"
fi

# Collect UI password
echo
echo 'UI passwords must be 8 to 30 characters'
echo

while true; do
  if test -z "${TEST_UI_PASSWORD-}"; then
    read -s -r -p "Enter the password to be used for accessing the UI: " PW
  else
    PW="${TEST_UI_PASSWORD-}"
  fi
  if [[ ${#PW} -ge 8 && ${#PW} -le 30 ]]; then
    echo
    break
  else
    echo "Invalid Password, please retry"
  fi
done

ssh -o StrictHostKeyChecking=false -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) <<!
sudo su oracle
cd /opt/oracle/ords
java -jar ords.war user grabdish order_user inventory_user <<EOF
$PW
$PW
EOF
exit
sudo su root
systemctl restart ords
!
