#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
  exit 1
fi


export GRABDISH_LOG


# Base 64 encoder
function base64-encode() {
  # Encode base64 file named $1 with no wrapping on any supported platform
  if ! test -f $1; then
    echo ""
  elif test `uname` == Darwin; then
    base64 -b 0 $1
  else
    base64 -w0 $1
  fi
}


TEMP_OUTPUT=$MY_STATE/temp_output.env
rm -f $TEMP_OUTPUT

# Create db-wallet-secret for each database
for db in order_db inventory_db; do
  db_upper=`echo $db | tr '[:lower:]' '[:upper:]'`
  db_dash=`echo $db | tr '_' '-'`
  TNS_ADMIN_VARIABLE="${db_upper}_TNS_ADMIN"
  TNS_ADMIN=${!TNS_ADMIN_VARIABLE}
  if ! test -d $TNS_ADMIN; then
    # If the folder does not exist then don't create a secret
    echo "${db_upper}_WALLET_SECRET=NA" >> $TEMP_OUTPUT
    continue
  fi
  TNS_ADMIN_COPY=$MY_STATE/${db}_tns_admin
  rm -rf $TNS_ADMIN_COPY
  mkdir $TNS_ADMIN_COPY
  cd $TNS_ADMIN_COPY
  cp ${!TNS_ADMIN_VARIABLE}/* .
  cat - >sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="/msdataworkshop/creds")))
SSL_SERVER_DN_MATCH=yes
!

  kubectl create -f - -n msdataworkshop <<!
apiVersion: v1
data:
  README: $(base64-encode README)
  cwallet.sso: $(base64-encode cwallet.sso)
  ewallet.p12: $(base64-encode ewallet.p12)
  keystore.jks: $(base64-encode keystore.jks)
  ojdbc.properties: $(base64-encode ojdbc.properties)
  sqlnet.ora: $(base64-encode sqlnet.ora)
  tnsnames.ora: $(base64-encode tnsnames.ora)
  truststore.jks: $(base64-encode truststore.jks)
kind: Secret
metadata:
  name: ${db_dash}-tns-admin-secret
!
  echo "${db_upper}_TNS_ADMIN_SECRET='${db_dash}-tns-admin-secret'" >> $TEMP_OUTPUT
done


mv $TEMP_OUTPUT $OUTPUT_FILE