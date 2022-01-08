#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


#echo ____________________________________________________
export orderdb_tptnsentry=$(grep -i "^${ORDER_PDB_NAME}_tp " ../wallet/tnsnames.ora)
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
export inventorydb_tptnsentry=$(grep -i "^${INVENTORY_PDB_NAME}_tp " ../wallet/tnsnames.ora)
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



echo setting values in atpaqadmin-deployment-${CURRENTTIME}.yaml ...

sed -i "s|%orderhostname%|${orderhostname}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml
sed -i "s|%orderport%|${orderport}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml
sed -i "s|%orderservice_name%|${orderservice_name}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml
sed -i "s|%orderssl_server_cert_dn%|${orderssl_server_cert_dn}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml

sed -i "s|%inventoryhostname%|${inventoryhostname}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml
sed -i "s|%inventoryport%|${inventoryport}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml
sed -i "s|%inventoryservice_name%|${inventoryservice_name}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml
sed -i "s|%inventoryssl_server_cert_dn%|${inventoryssl_server_cert_dn}|g" atpaqadmin-deployment-${CURRENTTIME}.yaml

