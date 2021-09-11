#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#./mkstore -wrl /Users/pparkins/Downloads/Wallet_gdpaulob2o-wpw -createCredential  gdpaulob2o_tp admin "Welcome12345;#"

if kubectl create -f - -n msdataworkshop; then
    state_set_done DB_WALLET_SECRET
else
    echo "Error: Failure to create db-wallet-withpw-secret."
fi <<!
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
  name: db-wallet-withpw-secret
!

