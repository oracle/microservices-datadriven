#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Get Order DB OCID
while ! state_done TRAVELAGENCYDB_OCID; do
  TRAVELAGENCYDB_OCID=`oci db autonomous-database list --compartment-id "$(cat state/COMPARTMENT_OCID)" --query 'join('"' '"',data[?"display-name"=='"'TRAVELAGENCYDB'"'].id)' --raw-output`
  if [[ "$TRAVELAGENCYDB_OCID" =~ ocid1.autonomousdatabase* ]]; then
    state_set TRAVELAGENCYDB_OCID "$TRAVELAGENCYDB_OCID"
  else
    echo "ERROR: Incorrect Order DB OCID: $TRAVELAGENCYDB_OCID"
    exit
  fi
done

# Get Wallet
while ! state_done WALLET_GET; do
  cd $TRAVELBOOKING_HOME
  mkdir wallet
  cd wallet
  oci db autonomous-database generate-wallet --autonomous-database-id "$(state_get TRAVELAGENCYDB_OCID)" --file 'wallet.zip' --password 'Welcome1' --generate-type 'ALL'
  unzip wallet.zip
  cd $TRAVELBOOKING_HOME
  state_set_done WALLET_GET
done
