#/bin/bash

# Fail on error
set -e
# NOT IN USE -- SHOULD BE DELETED

# Create Inventory ATP Bindings
while ! state_done DB_WALLET_SECRET; do
  if kubectl create -f - -n msdataworkshop; then
    state_set_done DB_WALLET_SECRET
  else
    echo "Error: Failure to create db-wallet-secret.  Retrying..."
    sleep 5
  fi <<!
apiVersion: v1
data:
  README: $(echo Dummy_data | base64)
  cwallet.sso: $(echo Dummy_data | base64)
  ewallet.p12: $(echo Dummy_data | base64)
  keystore.jks: $(echo Dummy_data | base64)
  ojdbc.properties: $(echo Dummy_data | base64)
  sqlnet.ora: $(echo Dummy_data | base64)
  tnsnames.ora: $(echo Dummy_data | base64)
  truststore.jks: $(echo Dummy_data | base64)
kind: Secret
metadata:
  name: db-wallet-secret
!
  cd $GRABDISH_HOME
done
