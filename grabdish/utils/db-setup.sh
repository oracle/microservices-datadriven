#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Create Object Store Bucket (Should be replaced by terraform one day)
while ! state_done OBJECT_STORE_BUCKET; do
  oci os bucket create --compartment-id "$(state_get COMPARTMENT_OCID)" --name "$(state_get RUN_NAME)"
  state_set_done OBJECT_STORE_BUCKET
done


# Get DB Connection Wallet and to Object Store
while ! state_done WALLET_ZIP_OBJECT; do
  oci db autonomous-database generate-wallet --autonomous-database-id "$(state_get ORDER_DB_OCID)" --file '-' --password 'Welcome1' --generate-type 'ALL' | oci os object put --bucket-name "$(state_get RUN_NAME)" --name "wallet.zip" --file '-'
  state_set_done WALLET_ZIP_OBJECT
done


# Create Authenticated Link to Wallet
while ! state_done WALLET_ZIP_AUTH_URL; do
  ACCESS_URI=`oci os preauth-request create --object-name 'wallet.zip' --access-type 'ObjectRead' --bucket-name "$(state_get RUN_NAME)" --name 'grabdish' --time-expires $(date '+%Y-%m-%d' --date '+7 days') --query 'data."access-uri"' --raw-output`
  state_set WALLET_ZIP_AUTH_URL "https://objectstorage.$(state_get REGION).oraclecloud.com${ACCESS_URI}"
done


# Get DB Connection Wallet and to Object Store
while ! state_done CWALLET_SSO_OBJECT; do
  cd $GRABDISH_HOME
  mkdir wallet
  cd wallet
  curl -sL "$(state_get WALLET_ZIP_AUTH_URL)" --output wallet.zip ; unzip wallet.zip ; rm wallet.zip
  cat cwallet.sso | oci os object put --bucket-name "$(state_get RUN_NAME)" --name "cwallet.sso" --file '-'
  rm -rf wallet
  state_set_done CWALLET_SSO_OBJECT
done


# Create Authenticated Link to Wallet
while ! state_done CWALLET_SSO_AUTH_URL; do
  ACCESS_URI=`oci os preauth-request create --object-name 'cwallet.sso' --access-type 'ObjectRead' --bucket-name "$(state_get RUN_NAME)" --name 'grabdish' --time-expires $(date '+%Y-%m-%d' --date '+7 days') --query 'data."access-uri"' --raw-output`
  state_set CWALLET_SSO_AUTH_URL "https://objectstorage.$(state_get REGION).oraclecloud.com${ACCESS_URI}"
done


# Create ATP Bindings
while ! state_done ATP_BINDINGS; do
  while ! state_done OKE_NAMESPACE; do
    echo "Waiting for OKE_NAMESPACE"
    sleep 5
  done
  cd $GRABDISH_HOME/atp-secrets-setup
  ./deleteAll.sh
  ./createAll.sh "$(state_get WALLET_ZIP_AUTH_URL)"
  state_set_done ATP_BINDINGS
done


# DB Setup Done
state_set_done "DB_SETUP"