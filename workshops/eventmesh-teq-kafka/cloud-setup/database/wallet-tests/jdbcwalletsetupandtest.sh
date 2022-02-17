#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

DB_OCID="ocid1.autonomousdatabase.oc1.iad.anuwcljtq33dybyahx3kglpzqb5iye6dnruuekq4ecim6rjwbwfmu4xh6wyq";

db_name="lab8022";
DB_ALIAS="${db_name}_tp"

#TNS_ADMIN is the wallet location
TNS_ADMIN=${PWD}/wallet
echo TNS_ADMIN is $TNS_ADMIN

WALLET_PASSWORD="Welcome12345"

# Database Credentials
DB_USER=LAB8022_USER
DB_PASSWORD="Welcome#1@Oracle"

# FROM HERE DOWN CAN BE USED AS IS (TEST JUST NEEDS APPROPRIATE/RELATIVE CP)

echo Get Wallet
mkdir -p "$TNS_ADMIN"
cd "$TNS_ADMIN"
umask 177
echo '{"password": "'"$WALLET_PASSWORD"'"}' > temp_params
umask 22

# --generate-type [text]
#   Shared Exadata infrastructure usage: * SINGLE - used to generate a wallet for a single database

# --password [text]
#   The password to encrypt the keys inside the wallet. The password must be at least 8 characters long and must include
#   at least 1 letter and either 1 numeric character or 1 special character.

oci db autonomous-database generate-wallet --autonomous-database-id "$DB_OCID" --generate-type 'SINGLE' --file 'wallet.zip' --from-json "file://temp_params"

#rm temp_params
unzip -oq wallet.zip

echo Add credential
SQLCL=$(dirname $(which sql))/../lib
CLASSPATH=${SQLCL}/oraclepki.jar:${SQLCL}/osdt_core.jar:${SQLCL}/osdt_cert.jar

java -Doracle.pki.debug=true -classpath "${CLASSPATH}" oracle.security.pki.OracleSecretStoreTextUI -nologo -wrl "$TNS_ADMIN" -createCredential "${DB_ALIAS}" $DB_USER <<!
$DB_PASSWORD
$DB_PASSWORD
$WALLET_PASSWORD
!



