#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# INPUTS:
#
# OUTPUTS:
# tns_names folder containing the wallet


# Fail on error
set -e


# Check the home folder
MY_HOME="$1"
if ! test -d "$MY_HOME"; then
  echo "ERROR: The home folder does not exist"
  exit 1
fi


# Source output.env
if test -f $MY_HOME/output.env; then
  source "$MY_HOME"/output.env
else
  echo "ERROR: Cannot get wallet as setup has not completed"
  exit 1
fi


# Get the wallet and other TNS info
TNS_ADMIN=$MY_HOME/tns_admin
mkdir -p $TNS_ADMIN
rm -rf $TNS_ADMIN/*
cd $TNS_ADMIN
echo "DB OCID is $DB_OCID"
oci db autonomous-database generate-wallet --autonomous-database-id "$DB_OCID" --file 'wallet.zip' --password 'Welcome1' --generate-type 'ALL'
unzip wallet.zip

DB_ALIAS=${DB_NAME}_tp


cat >$MY_HOME/output.env <<!
  DB_OCID='$DB_OCID'
  DB_NAME=$DB_NAME
  DISPLAY_NAME=$DISPLAY_NAME
  DB_ALIAS=$DB_ALIAS
  TNS_ADMIN=$TNS_ADMIN
!