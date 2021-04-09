#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if [[ $1 == "" ]]
then
  echo MSDATAWORKSHOP_DB_WALLET_OBJECTSTORAGE_LINK not provided
  echo Required arguments is MSDATAWORKSHOP_DB_WALLET_OBJECTSTORAGE_LINK.
  echo Usage example :  ./createAll.sh https://objectstorage.us-phoenix-1.oraclecloud.com/p/asdf/n/asdf/b/msdataworkshop/o/Wallet_ORDERDB.zip
  exit
fi

#source ../msdataworkshop.properties
export SCRIPT_DIR=$(dirname $0)
export CURRENTTIME=$( date '+%F_%H:%M:%S' )
echo CURRENTTIME is $CURRENTTIME  ...this will be appended to generated yamls
mkdir generated-yaml

echo "get regional wallet for order and inventory pdbs..."
mkdir wallet
cd wallet
curl -sL $1 --output wallet.zip ; unzip wallet.zip ; rm wallet.zip
echo "export orderpdb values for contents of wallet zip..."
export orderpdb_cwallet_sso=$(cat cwallet.sso | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export orderpdb_ewallet_p12=$(cat ewallet.p12 | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export orderpdb_keystore_jks=$(cat keystore.jks | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export orderpdb_ojdbc_properties=$(cat ojdbc.properties | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export orderpdb_README=$(cat README | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export orderpdb_sqlnet_ora=$(cat sqlnet.ora | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export orderpdb_tnsnames_ora=$(cat tnsnames.ora | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export orderpdb_truststore_jks=$(cat truststore.jks | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
echo "export inventorypdb values for contents of wallet zip..."
export inventorypdb_cwallet_sso=$(cat cwallet.sso | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export inventorypdb_ewallet_p12=$(cat ewallet.p12 | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export inventorypdb_keystore_jks=$(cat keystore.jks | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export inventorypdb_ojdbc_properties=$(cat ojdbc.properties | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export inventorypdb_README=$(cat README | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export inventorypdb_sqlnet_ora=$(cat sqlnet.ora | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export inventorypdb_tnsnames_ora=$(cat tnsnames.ora | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')
export inventorypdb_truststore_jks=$(cat truststore.jks | base64 | tr -d '\n\r' | base64 | tr -d '\n\r')

cd ../
echo "replace values in order yaml files (files are suffixed with ${CURRENTTIME})..."
eval "cat <<EOF
$(<$SCRIPT_DIR/atp-binding-order.yaml)
EOF" > $SCRIPT_DIR/generated-yaml/atp-binding-order-${CURRENTTIME}.yaml
echo "creating order binding..."
kubectl create -f generated-yaml/atp-binding-order-${CURRENTTIME}.yaml -n msdataworkshop
echo "replace values in inventory yaml files (files are suffixed with ${CURRENTTIME})..."
eval "cat <<EOF
$(<$SCRIPT_DIR/atp-binding-inventory.yaml)
EOF" > $SCRIPT_DIR/generated-yaml/atp-binding-inventory-${CURRENTTIME}.yaml
echo "creating inventory binding..."
kubectl create -f generated-yaml/atp-binding-inventory-${CURRENTTIME}.yaml -n msdataworkshop
