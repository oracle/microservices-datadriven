#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Create Object Store Bucket (Should be replaced by terraform one day)
while ! state_done OBJECT_STORE_BUCKET; do
  oci os bucket create --compartment-id "$(cat state/COMPARTMENT_OCID)" --name "$(state_get RUN_NAME)"
  state_set_done OBJECT_STORE_BUCKET
done


# Get DB Connection Wallet and to Object Store
while ! state_done WALLET_OBJECT_DONE; do
  oci db autonomous-database generate-wallet --autonomous-database-id "$(state_get ORDER_DB_OCID)" --file '-' --password 'Welcome1' --generate-type 'ALL' | oci os object put --bucket-name "$(state_get RUN_NAME)" --name "wallet" --file '-'
  state_set_done WALLET_OBJECT_DONE
done


# Create Authenticated Link to Wallet
while ! state_done WALLET_AUTH_URL; do
  ACCESS_URI=`oci os preauth-request create --object-name 'wallet' --access-type 'ObjectRead' --bucket-name "$(state_get RUN_NAME)" --name 'grabdish' --time-expires $(date '+%Y-%m-%d' --date '+7 days') --query 'data."access-uri"' --raw-output`
  state_set WALLET_AUTH_URL "https://objectstorage.$(state_get REGION).oraclecloud.com${ACCESS_URI}"
done


# DB Setup Done
state_set_done "DB_SETUP_DONE"