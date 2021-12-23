#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# get the travelagency and participant connection info again - we just need wallet for band tnsnames
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
echo updating atpaqadmin-deployment-${CURRENTTIME}.yaml with cwalletobjecturi $cwalletobjecturi
sed -i "s|%cwalletobjecturi%|${cwalletobjecturi}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml


echo cwalletobjecturi is created and added to atpaqadmin-deployment-${CURRENTTIME}.yaml
echo adding other values in atpaqadmin-deployment-${CURRENTTIME}.yaml as parsed from tnsnames.ora s

#echo ____________________________________________________
export travelagencydb_tptnsentry=$(grep -i "^${ORDER_PDB_NAME}_tp " $MSDATAWORKSHOP_LOCATION/atp-secrets-setup/wallet/tnsnames.ora)
#echo $ORDER_PDB_NAME tp entry... $travelagencydb_tptnsentry
echo ____________________________________________________
# for each variable, string off begin (based on identifier)
echo travelagencyhostname...
export b="(host="
export travelagencyhostname=$(echo ${travelagencydb_tptnsentry/*$b/$b})
export c="))(connect_data="
export travelagencyhostname=$(echo ${travelagencyhostname/$c*/$c})
export travelagencyhostname=${travelagencyhostname#"$b"}
export travelagencyhostname=${travelagencyhostname%"$c"}
echo $travelagencyhostname
echo
echo travelagencyport...
export b="(port="
export travelagencyport=$(echo ${travelagencydb_tptnsentry/*$b/$b})
export c=")(host"
export travelagencyport=$(echo ${travelagencyport/$c*/$c})
export travelagencyport=${travelagencyport#"$b"}
export travelagencyport=${travelagencyport%"$c"}
echo $travelagencyport
echo
echo travelagencyservice_name...
export b="(service_name="
export travelagencyservice_name=$(echo ${travelagencydb_tptnsentry/*$b/$b})
export c="))(security"
export travelagencyservice_name=$(echo ${travelagencyservice_name/$c*/$c})
export travelagencyservice_name=${travelagencyservice_name#"$b"}
export travelagencyservice_name=${travelagencyservice_name%"$c"}
echo $travelagencyservice_name
echo
echo travelagencyssl_server_cert_dn...
export b="(ssl_server_cert_dn=\""
export travelagencyssl_server_cert_dn=$(echo ${travelagencydb_tptnsentry/*$b/$b})
export c="\")))"
export travelagencyssl_server_cert_dn=$(echo ${travelagencyssl_server_cert_dn/$c*/$c})
export travelagencyssl_server_cert_dn=${travelagencyssl_server_cert_dn#"$b"}
export travelagencyssl_server_cert_dn=${travelagencyssl_server_cert_dn%"$c"}
echo $travelagencyssl_server_cert_dn


#echo ____________________________________________________
export participantdb_tptnsentry=$(grep -i "^${INVENTORY_PDB_NAME}_tp " $MSDATAWORKSHOP_LOCATION/atp-secrets-setup/wallet/tnsnames.ora)
#echo $INVENTORY_PDB_NAME tp entry... $participantdb_tptnsentry
echo ____________________________________________________
# for each variable, string off begin (based on identifier)
echo participanthostname...
export b="(host="
export participanthostname=$(echo ${participantdb_tptnsentry/*$b/$b})
export c="))(connect_data="
export participanthostname=$(echo ${participanthostname/$c*/$c})
export participanthostname=${participanthostname#"$b"}
export participanthostname=${participanthostname%"$c"}
echo $participanthostname
echo
echo participantport...
export b="(port="
export participantport=$(echo ${participantdb_tptnsentry/*$b/$b})
export c=")(host"
export participantport=$(echo ${participantport/$c*/$c})
export participantport=${participantport#"$b"}
export participantport=${participantport%"$c"}
echo $participantport
echo
echo participantservice_name...
export b="(service_name="
export participantservice_name=$(echo ${participantdb_tptnsentry/*$b/$b})
export c="))(security"
export participantservice_name=$(echo ${participantservice_name/$c*/$c})
export participantservice_name=${participantservice_name#"$b"}
export participantservice_name=${participantservice_name%"$c"}
echo $participantservice_name
echo
echo participantssl_server_cert_dn...
export b="(ssl_server_cert_dn=\""
export participantssl_server_cert_dn=$(echo ${participantdb_tptnsentry/*$b/$b})
export c="\")))"
export participantssl_server_cert_dn=$(echo ${participantssl_server_cert_dn/$c*/$c})
export participantssl_server_cert_dn=${participantssl_server_cert_dn#"$b"}
export participantssl_server_cert_dn=${participantssl_server_cert_dn%"$c"}
echo $participantssl_server_cert_dn



echo setting values in atpaqadmin-deployment-${CURRENTTIME}.yaml ...

sed -i "s|%travelagencyhostname%|${travelagencyhostname}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml
sed -i "s|%travelagencyport%|${travelagencyport}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml
sed -i "s|%travelagencyservice_name%|${travelagencyservice_name}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml
sed -i "s|%travelagencyssl_server_cert_dn%|${travelagencyssl_server_cert_dn}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml

sed -i "s|%participanthostname%|${participanthostname}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml
sed -i "s|%participantport%|${participantport}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml
sed -i "s|%participantservice_name%|${participantservice_name}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml
sed -i "s|%participantssl_server_cert_dn%|${participantssl_server_cert_dn}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml

