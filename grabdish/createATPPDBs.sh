#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo ________________________________________
echo creating ATP PDBs ...
echo ________________________________________

export WORKINGDIR=workingdir
echo WORKINGDIR = $WORKINGDIR

export MSDATAWORKSHOP_COMPARTMENT_ID=$(cat $WORKINGDIR/msdataworkshopcompartmentid.txt)
echo console created compartment ...
echo MSDATAWORKSHOP_COMPARTMENT_ID... $MSDATAWORKSHOP_COMPARTMENT_ID

if [[ $1 == "" ]]
then
  echo Required arguments not provided
  echo Required arguments are MSDATAWORKSHOP_ADMIN_PW_SECRET_OCID and FRONTEND_AUTH_PW_SECRET_OCID
  echo Usage example :  ./createATPPDBs.sh ocid1.vaultsecret.oc1.phx.DBADMINSECRETOCIDd3ejhlewv3wieyd5q ocid1.vaultsecret.oc1.phx.FRONTENDAUTHSECRETOCIDd3ejhlewv3wieyd5q
  exit
fi

if [[ $2 == "" ]]
then
  echo Required arguments not provided
  echo Required arguments are MSDATAWORKSHOP_ADMIN_PW_SECRET_OCID and FRONTEND_AUTH_PW_SECRET_OCID
  echo Usage example :  ./createATPPDBs.sh ocid1.vaultsecret.oc1.phx.DBADMINSECRETOCIDd3ejhlewv3wieyd5q ocid1.vaultsecret.oc1.phx.FRONTENDAUTHSECRETOCIDd3ejhlewv3wieyd5q
  exit
fi
echo $1 > $WORKINGDIR/msdataworkshopvaultsecretocid.txt

PASSWORD=`oci secrets secret-bundle get --secret-id $1 --query "data.\"secret-bundle-content\".content" --raw-output | base64 --decode`
umask 177
cat >pw <<!
{ "adminPassword": "$PASSWORD" }
!
echo create order PDB...
oci db autonomous-database create --compartment-id $MSDATAWORKSHOP_COMPARTMENT_ID --cpu-core-count 1 --data-storage-size-in-tbs 1 --db-name ORDERDB --display-name ORDERDB --from-json file://pw | jq --raw-output '.data | .["id"] '> $WORKINGDIR/msdataworkshoporderdbid.txt
echo create inventory PDB...
oci db autonomous-database create --compartment-id $MSDATAWORKSHOP_COMPARTMENT_ID --cpu-core-count 1 --data-storage-size-in-tbs 1 --db-name INVENTORYDB --display-name INVENTORYDB --from-json file://pw | jq --raw-output '.data | .["id"] '> $WORKINGDIR/msdataworkshopinventorydbid.txt
rm pw
echo create frontendadmin auth secret...
AUTHPASSWORD=`oci secrets secret-bundle get --secret-id $2 --query "data.\"secret-bundle-content\".content" --raw-output`
kubectl create -n msdataworkshop -f - <<!
{
   "apiVersion": "v1",
   "kind": "Secret",
   "metadata": {
      "name": "frontendadmin"
   },
   "data": {
      "password": "${AUTHPASSWORD}"
   }
}
!
