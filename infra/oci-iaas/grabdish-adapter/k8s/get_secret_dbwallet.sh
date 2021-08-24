# Create Inventory ATP Bindings



`kubectl get secret db-wallet-secret -n msdataworkshop --template={{.data.tnsnames.ora}} | base64 --decode`


#while ! state_done DB_WALLET_SECRET; do
  if kubectl apply -f - -n msdataworkshop; then
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
  sqlnet.ora: $(base64 -w0  $TNS_ADMIN_LOC/sqlnet.ora)
  tnsnames.ora: $(base64  -w0  $TNS_ADMIN_LOC/tnsnames.ora )
  truststore.jks: $(echo Dummy_data | base64)
kind: Secret
metadata:
  name: db-wallet-secret
!
  cd $GRABDISH_HOME
#done
