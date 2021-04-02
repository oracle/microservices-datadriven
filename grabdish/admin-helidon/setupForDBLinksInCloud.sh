#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# get the order and inventory connection info again - we just need wallet for band tnsnames
#echo list existing buckets...
#oci os bucket list --compartment-id $OCI_COMPARTMENT_ID

echo create msdataworkshop bucket ...ignore BucketAlreadyExists exception if this is not the first time running the script...
oci os bucket create --name msdataworkshop --compartment-id $OCI_COMPARTMENT_ID

#echo list existing buckets again...
#oci os bucket list --compartment-id $OCI_COMPARTMENT_ID

echo delete cwallet.sso in bucket ...ignore ObjectNotFound exception if this is the first time running the script...
# Will be prompted "Are you sure you want to delete this resource? [y/N]"

echo put cwallet.sso in bucket ...select "y" when asked to overwrite
oci os object put --bucket-name msdataworkshop --file $MSDATAWORKSHOP_LOCATION/atp-secrets-setup/wallet/cwallet.sso

echo create link to cwallet.sso in objectstorage, save, export, and echo value..
oci os preauth-request create --access-type ObjectRead --bucket-name msdataworkshop --name msdataworkshopwallet --time-expires 2021-12-21 --object-name cwallet.sso | jq --raw-output '.data | .["access-uri"] ' > preauthlink.txt
export cwalletobjecturi=$(cat preauthlink.txt)
export cwalletobjecturi=https://objectstorage.${OCI_REGION}.oraclecloud.com${cwalletobjecturi}
echo updating admin-helidon-deployment-${CURRENTTIME}.yaml with cwalletobjecturi $cwalletobjecturi
sed -i "s|%cwalletobjecturi%|${cwalletobjecturi}|g" admin-helidon-deployment-${CURRENTTIME}.yaml


echo cwalletobjecturi is created and added to admin-helidon-deployment-${CURRENTTIME}.yaml
echo adding other values in admin-helidon-deployment-${CURRENTTIME}.yaml as parsed from tnsnames.ora s

#echo ____________________________________________________
export orderdb_tptnsentry=$(grep -i "^${ORDER_PDB_NAME}_tp " $MSDATAWORKSHOP_LOCATION/atp-secrets-setup/wallet/tnsnames.ora)
#echo $ORDER_PDB_NAME tp entry... $orderdb_tptnsentry
echo ____________________________________________________
# for each variable, string off begin (based on identifier)
echo orderhostname...
export b="(host="
export orderhostname=$(echo ${orderdb_tptnsentry/*$b/$b})
export c="))(connect_data="
export orderhostname=$(echo ${orderhostname/$c*/$c})
export orderhostname=${orderhostname#"$b"}
export orderhostname=${orderhostname%"$c"}
echo $orderhostname
echo
echo orderport...
export b="(port="
export orderport=$(echo ${orderdb_tptnsentry/*$b/$b})
export c=")(host"
export orderport=$(echo ${orderport/$c*/$c})
export orderport=${orderport#"$b"}
export orderport=${orderport%"$c"}
echo $orderport
echo
echo orderservice_name...
export b="(service_name="
export orderservice_name=$(echo ${orderdb_tptnsentry/*$b/$b})
export c="))(security"
export orderservice_name=$(echo ${orderservice_name/$c*/$c})
export orderservice_name=${orderservice_name#"$b"}
export orderservice_name=${orderservice_name%"$c"}
echo $orderservice_name
echo
echo orderssl_server_cert_dn...
export b="(ssl_server_cert_dn=\""
export orderssl_server_cert_dn=$(echo ${orderdb_tptnsentry/*$b/$b})
export c="\")))"
export orderssl_server_cert_dn=$(echo ${orderssl_server_cert_dn/$c*/$c})
export orderssl_server_cert_dn=${orderssl_server_cert_dn#"$b"}
export orderssl_server_cert_dn=${orderssl_server_cert_dn%"$c"}
echo $orderssl_server_cert_dn


#echo ____________________________________________________
export inventorydb_tptnsentry=$(grep -i "^${INVENTORY_PDB_NAME}_tp " $MSDATAWORKSHOP_LOCATION/atp-secrets-setup/wallet/tnsnames.ora)
#echo $INVENTORY_PDB_NAME tp entry... $inventorydb_tptnsentry
echo ____________________________________________________
# for each variable, string off begin (based on identifier)
echo inventoryhostname...
export b="(host="
export inventoryhostname=$(echo ${inventorydb_tptnsentry/*$b/$b})
export c="))(connect_data="
export inventoryhostname=$(echo ${inventoryhostname/$c*/$c})
export inventoryhostname=${inventoryhostname#"$b"}
export inventoryhostname=${inventoryhostname%"$c"}
echo $inventoryhostname
echo
echo inventoryport...
export b="(port="
export inventoryport=$(echo ${inventorydb_tptnsentry/*$b/$b})
export c=")(host"
export inventoryport=$(echo ${inventoryport/$c*/$c})
export inventoryport=${inventoryport#"$b"}
export inventoryport=${inventoryport%"$c"}
echo $inventoryport
echo
echo inventoryservice_name...
export b="(service_name="
export inventoryservice_name=$(echo ${inventorydb_tptnsentry/*$b/$b})
export c="))(security"
export inventoryservice_name=$(echo ${inventoryservice_name/$c*/$c})
export inventoryservice_name=${inventoryservice_name#"$b"}
export inventoryservice_name=${inventoryservice_name%"$c"}
echo $inventoryservice_name
echo
echo inventoryssl_server_cert_dn...
export b="(ssl_server_cert_dn=\""
export inventoryssl_server_cert_dn=$(echo ${inventorydb_tptnsentry/*$b/$b})
export c="\")))"
export inventoryssl_server_cert_dn=$(echo ${inventoryssl_server_cert_dn/$c*/$c})
export inventoryssl_server_cert_dn=${inventoryssl_server_cert_dn#"$b"}
export inventoryssl_server_cert_dn=${inventoryssl_server_cert_dn%"$c"}
echo $inventoryssl_server_cert_dn



echo setting values in admin-helidon-deployment-${CURRENTTIME}.yaml ...

sed -i "s|%orderhostname%|${orderhostname}|g" admin-helidon-deployment-${CURRENTTIME}.yaml
sed -i "s|%orderport%|${orderport}|g" admin-helidon-deployment-${CURRENTTIME}.yaml
sed -i "s|%orderservice_name%|${orderservice_name}|g" admin-helidon-deployment-${CURRENTTIME}.yaml
sed -i "s|%orderssl_server_cert_dn%|${orderssl_server_cert_dn}|g" admin-helidon-deployment-${CURRENTTIME}.yaml

sed -i "s|%inventoryhostname%|${inventoryhostname}|g" admin-helidon-deployment-${CURRENTTIME}.yaml
sed -i "s|%inventoryport%|${inventoryport}|g" admin-helidon-deployment-${CURRENTTIME}.yaml
sed -i "s|%inventoryservice_name%|${inventoryservice_name}|g" admin-helidon-deployment-${CURRENTTIME}.yaml
sed -i "s|%inventoryssl_server_cert_dn%|${inventoryssl_server_cert_dn}|g" admin-helidon-deployment-${CURRENTTIME}.yaml

