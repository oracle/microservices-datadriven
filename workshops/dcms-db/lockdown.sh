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
while true; do
  if test -z "${TEST_DB_PASSWORD-}"; then
    echo
    echo 'Database passwords must be 12 to 30 characters and contain at least one uppercase letter,'
    echo 'one lowercase letter, and one number. The password cannot contain the double quote (")'
    echo 'character or the word "admin".'
    echo

    read -s -r -p "Enter the password to be used for the database: " PW
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


# Set the DB admin password
param_file=temp_params
trap "rm -f -- '$param_file'" EXIT

umask 177
echo '{"adminPassword": "'"$DB_PASSWORD"'"}' > $param_file
umask 22
oci db autonomous-database update --autonomous-database-id "$(state_get DB_OCID)" --from-json "file://$param_file" >/dev/null
rm $param_file

# Update the password of all the other schemas
ssh -o StrictHostKeyChecking=false -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) <<!
sudo su - oracle
cd ~/db/common/apply
export TNS_ADMIN=~/tns_admin

sqlplus /nolog <<EOF
  connect admin/"$DB_PASSWORD"@$(state_get DB_ALIAS)
  ALTER USER AQ IDENTIFIED BY "$DB_PASSWORD";
  ALTER USER ORDERUSER IDENTIFIED BY "$DB_PASSWORD";
  ALTER USER INVENTORYUSER IDENTIFIED BY "$DB_PASSWORD";
  ALTER USER ORDS_PUBLIC_USER_OCI IDENTIFIED BY "$DB_PASSWORD";
  ALTER USER ORDS_PLSQL_GATEWAY_OCI IDENTIFIED BY "$DB_PASSWORD";
EOF
!

# Update the ORDS config
ssh -o StrictHostKeyChecking=false -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) <<!
sudo su - oracle
cd /opt/oracle/ords/config/ords/conf
for conn in apex order inventory; do
  cat >\${conn}_pu.xml <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<entry key="db.username">ORDS_PUBLIC_USER_OCI</entry>
<entry key="db.password">!${DB_PASSWORD}</entry>
<entry key="db.wallet.zip.service">$(state_get DB_ALIAS)</entry>
<entry key="db.wallet.zip"><![CDATA[\$(cat /home/oracle/tns_admin/adb_wallet.zip.b64)]]></entry>
</properties>
EOF
done
!

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
    UI_PASSWORD="$PW"
    break
  else
    echo "Invalid Password, please retry"
  fi
done

# Setup the UI Password
ssh -o StrictHostKeyChecking=false -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) <<!
# Setup the UI Password
sudo su - oracle
cd /opt/oracle/ords
java -jar /opt/oracle/ords/ords.war user grabdish order_user inventory_user <<EOF
$UI_PASSWORD
$UI_PASSWORD
EOF
!

# Restart ORDS
ssh -o StrictHostKeyChecking=false -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) <<!
sudo su - root
systemctl restart ords
!
