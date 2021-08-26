#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Dependencies:
#   kubectl (configured)
#   GRABDISH_HOME (set)
#
# INPUTS:
#   Parameters:
#     $1  Home directory (to store state, inputs and outputs)
#
# input.env
#   ORDERDB_TNS_ADMIN
#
# OUTPUTS:
#   output.env
#     <empty indicates done>


# Fail on error
set -e


# Check the home folder
MY_HOME="$1"
if ! test -d "$MY_HOME"; then
  echo "ERROR: The home folder does not exist"
  exit
fi


# Check home is set
if test -z "$GRABDISH_HOME"; then
  echo "ERROR: This script requires GRABDISH_HOME to be set"
  exit
fi


# Check if we are already done
if test -f $MY_HOME/output.env; then
  exit
fi


# Create db-wallet-secret
cd $ORDERDB_TNS_ADMIN
cat - >sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="/msdataworkshop/creds")))
SSL_SERVER_DN_MATCH=yes
!

kubectl create -f - -n msdataworkshop <<!
apiVersion: v1
data:
  README: $(base64 -w0 README)
  cwallet.sso: $(base64 -w0 cwallet.sso)
  ewallet.p12: $(base64 -w0 ewallet.p12)
  keystore.jks: $(base64 -w0 keystore.jks)
  ojdbc.properties: $(base64 -w0 ojdbc.properties)
  sqlnet.ora: $(base64 -w0 sqlnet.ora)
  tnsnames.ora: $(base64 -w0 tnsnames.ora)
  truststore.jks: $(base64 -w0 truststore.jks)
kind: Secret
metadata:
  name: db-wallet-secret
!


touch $MY_HOME/output.env