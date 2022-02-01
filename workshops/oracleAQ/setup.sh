#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 
# Fail on error or undefined variable
#set -eu
 
comp_name="oracleAQ";
db_name="aqdatabase";
export WORKFLOW_HOME=${HOME}/${comp_name};
display_name=${db_name}
export TNS_ADMIN=$WORKFLOW_HOME/wallet
USER_DEFINED_WALLET=${TNS_ADMIN}/user_defined_wallet
DB_USER1=admin
DB_USER2=dbuser
TNS_WALLET_STR="(MY_WALLET_DIRECTORY="$TNS_ADMIN")"

#get user's OCID # read user's OCID:  #echo "Enter OCID of root compartment:" ; read -s rootCompOCID; export rootCompOCID                          
   # fetch user's OCID
rootCompOCID=$(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --raw-output --query "data[?contains(\"id\",'tenancy')].id | [0]")

#Create compartment
oci iam compartment create --name ${comp_name} -c ${rootCompOCID} --description "Oracle Advanced Queue workflow" --wait-for-state ACTIVE
ocid_comp=$(oci iam compartment list --all | jq -r ".data[] | select(.name == \"${comp_name}\") | .id")

#Get the database password
echo "Enter Database Password :" ;
echo "NOTE: Password must contain:"
echo "* 12 to 30 characters"
echo "* at least one uppercase letter"
echo "* at least one lowercase letter"
echo "* at least one number"
echo "* The password cannot contain the double quote character or the username 'admin' ";
while true; do
    read -s -r -p "Enter the password to be used for the database admin user: " db_pwd
    if [[ ${#db_pwd} -ge 12 && ${#db_pwd} -le 30 && "$db_pwd" =~ [A-Z] && "$db_pwd" =~ [a-z] && "$db_pwd" =~ [0-9] && "$db_pwd" != *admin* && "$db_pwd" != *'"'* ]]; then
        echo
        break
    else
        echo "Invalid Password, please retry"
    fi
done
umask 177 
DB_PASSWORD="$db_pwd"
WALLET_PASSWORD='Pwd'`awk 'BEGIN { srand(); print int(1 + rand() * 100000000)}'`
umask 22


# Create ATP- #21c always free
umask 177
echo '{"adminPassword": "'"$DB_PASSWORD"'"}' > temp_params
umask 22
oci db autonomous-database create -c ${ocid_comp} --db-name ${db_name} --display-name ${db_name} --db-workload OLTP --is-free-tier true --cpu-core-count 1 --data-storage-size-in-tbs 1 --db-version "21c" --wait-for-state AVAILABLE --wait-interval-seconds 5 --from-json "file://temp_params"
rm temp_params;

# Get connection string
db_conn=$(oci db autonomous-database list -c ${ocid_comp} --query "data [?\"db-name\"=='${db_name}'] | [0].\"connection-strings\".low" --raw-output)
DB_OCID=$(oci db autonomous-database list -c ${ocid_comp} --query "data [?\"db-name\"=='${db_name}'] | [0].id" --raw-output)

# Generating wallet
mkdir -p $TNS_ADMIN
cd $TNS_ADMIN
umask 177
echo '{"password": "'"$DB_PASSWORD"'"}' > temp_params
umask 22
oci db autonomous-database generate-wallet --autonomous-database-id "$DB_OCID" --file 'wallet.zip' --from-json "file://temp_params"
rm temp_params
unzip -oq wallet.zip
#sed -i "s|?|$WORKFLOW_HOME|" sqlnet.ora
 
# Configure the sqlnet.ora
cd $TNS_ADMIN
cat >sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$USER_DEFINED_WALLET")))
SQLNET.WALLET_OVERRIDE = TRUE
SSL_SERVER_DN_MATCH = yes
!


# Get the DB Alias
# This also validates the DB OCID
DB_ALIAS=`oci db autonomous-database get --autonomous-database-id "$DB_OCID" --query 'data."connection-strings".profiles[?"consumer-group"=='"'TP'"']."display-name" | [0]' --raw-output`
echo "Found TNS Alias: $DB_ALIAS"
 

mkdir -p $TNS_ADMIN 
cd $TNS_ADMIN
TNS_ADMIN=$PWD

rm -rf $USER_DEFINED_WALLET
mkdir -p $USER_DEFINED_WALLET 

# Add the admin credential to the wallet
# set classpath for mkstore - align this to your local SQLcl installation
SQLCL=$(dirname $(which sql))/../lib
CLASSPATH=${SQLCL}/oraclepki.jar:${SQLCL}/osdt_core.jar:${SQLCL}/osdt_cert.jar

# Create New User Defined Wallet to store DB Credentials
java -classpath ${CLASSPATH} oracle.security.pki.OracleSecretStoreTextUI -nologo -wrl "$USER_DEFINED_WALLET" -create >/dev/null <<!
$WALLET_PASSWORD
$WALLET_PASSWORD
!

# Add User1 Credentials to the newly created User Defined Wallet
java -classpath ${CLASSPATH} oracle.security.pki.OracleSecretStoreTextUI -nologo -wrl "$USER_DEFINED_WALLET" -createCredential "${DB_ALIAS}_${DB_USER1}" $DB_USER1 >/dev/null <<!
$DB_PASSWORD
$DB_PASSWORD
$WALLET_PASSWORD
!

# Add User2 Credentials to the newly created User Defined Wallet
java -classpath ${CLASSPATH} oracle.security.pki.OracleSecretStoreTextUI -nologo -wrl "$USER_DEFINED_WALLET" -createCredential "${DB_ALIAS}_${DB_USER2}" $DB_USER2 >/dev/null <<!
$DB_PASSWORD
$DB_PASSWORD
$WALLET_PASSWORD
!

# ADD TNS Aliases to the TNSNAMES.ORA

tns_alias=$(grep "$DB_ALIAS " $TNS_ADMIN/tnsnames.ora)
tns_alias=${tns_alias/security=/security= $TNS_WALLET_STR}
tns_alias1=${tns_alias/$DB_ALIAS /${DB_ALIAS}_${DB_USER1} }
tns_alias2=${tns_alias/$DB_ALIAS /${DB_ALIAS}_${DB_USER2} }

 
echo $tns_alias1 >> $TNS_ADMIN/tnsnames.ora
echo $tns_alias2 >> $TNS_ADMIN/tnsnames.ora

# Print names of the newly created TNS Aliases
echo "Added TNS Alias: ${DB_ALIAS}_${DB_USER1}"
echo "Added TNS Alias: ${DB_ALIAS}_${DB_USER2}"

sqlplus /@aqdatabase_high_admin <<!
SET VERIFY OFF;
CREATE USER dbuser IDENTIFIED BY $DB_PASSWORD ;

GRANT execute on DBMS_AQ TO dbuser;
GRANT CREATE SESSION TO dbuser;
GRANT RESOURCE TO dbuser;
GRANT CONNECT TO dbuser;
GRANT EXECUTE ANY PROCEDURE TO dbuser;
GRANT aq_user_role TO dbuser;
GRANT EXECUTE ON dbms_aqadm TO dbuser;
GRANT EXECUTE ON dbms_aq TO dbuser ;
GRANT EXECUTE ON dbms_aqin TO dbuser;
GRANT UNLIMITED TABLESPACE TO dbuser;
GRANT EXECUTE ON DBMS_CLOUD_ADMIN TO dbuser;
GRANT pdb_dba TO dbuser;
GRANT EXECUTE ON DBMS_CLOUD TO dbuser;
GRANT CREATE DATABASE LINK TO dbuser;
GRANT EXECUTE ON sys.dbms_aqadm TO dbuser;
GRANT EXECUTE ON sys.dbms_aq TO dbuser;
EXIT;
!

sqlplus /@aqdatabase_high_dbuser <<!
Show users;
/
!

# Java setup
cd $WORKFLOW_HOME/aqJava;
mvn clean install
cd target
killall java
nohup java -jar aqJava-0.0.1-SNAPSHOT.jar &

cd $WORKFLOW_HOME;

echo "WORKFLOW_HOME     : " $WORKFLOW_HOME;

echo "Compartment Name  : " ${comp_name}
echo "Compartment OCID  : " ${ocid_comp}

echo "Database Name     : " ${db_name}
echo "ATP Database OCID : " ${DB_OCID}

echo "-------------------------------"
echo "        SETUP COMPLETED        "
echo "------------------------------"
