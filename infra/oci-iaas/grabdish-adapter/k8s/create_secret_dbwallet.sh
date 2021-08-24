#/bin/bash
# Fail on error
set -e

# Create Inventory and Order PDBs Bindings

TNS_ADMIN_LOC=${TNS_ADMIN}

  if kubectl apply -f - -n msdataworkshop; then
    state_set_done DB_WALLET_SECRET
  else
    echo "Error: Failure to create db-wallet-secret. ..."
  fi <<!
apiVersion: v1
data:
  README: $(echo Dummy_data | base64)
  cwallet.sso: $(echo Dummy_data | base64)
  ewallet.p12: $(echo Dummy_data | base64)
  keystore.jks: $(echo Dummy_data | base64)
  ojdbc.properties: $(echo Dummy_data | base64)
  sqlnet.ora: $(base64 -w0  ${TNS_ADMIN_LOC}/sqlnet.ora)
  tnsnames.ora: $(base64  -w0  ${TNS_ADMIN_LOC}/tnsnames.ora )
  truststore.jks: $(echo Dummy_data | base64)
kind: Secret
metadata:
  name: db-wallet-secret
!
