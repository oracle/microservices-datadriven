#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

COMPARTMENT="oracleAQ"
DB_NAME="aqdatabase"
export PLSQL_DB_USER1="admin"
export JAVA_DB_USER="javaUser"

#set all language paths
export ORACLEAQ_HOME=${HOME}/${COMPARTMENT}

export ORACLEAQ_PLSQL_AQ=${ORACLEAQ_HOME}/qPlsql/aq
export ORACLEAQ_PLSQL_TxEventQ=${ORACLEAQ_HOME}/qPlsql/txEventQ

export ORACLEAQ_PYTHON_AQ=${ORACLEAQ_HOME}/qPython/aq
export ORACLEAQ_PYTHON_TxEventQ=${ORACLEAQ_HOME}/qPython/txEventQ

export ORACLEAQ_NODE_AQ=${ORACLEAQ_HOME}/qNode/aq
export ORACLEAQ_NODE_TxEventQ=${ORACLEAQ_HOME}/qNode/txEventQ

export ORACLEAQ_JAVA=${ORACLEAQ_HOME}/qJava

export TNS_ADMIN=$ORACLEAQ_HOME/wallet
export USER_DEFINED_WALLET=${TNS_ADMIN}/user_defined_wallet
export TNS_ADMIN_FOR_JAVA=$ORACLEAQ_HOME/wallet_java
export JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
TNS_WALLET_STR="(MY_WALLET_DIRECTORY="$TNS_ADMIN")"

#Create compartment
ROOT_COMPARTMENT_OCID=$(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --raw-output --query "data[?contains(\"id\",'tenancy')].id | [0]")

if [[ -z $(oci iam compartment list --all | jq -r ".data[] | select(.name == \"${COMPARTMENT}\") | .id") ]]; then
    oci iam compartment create --name ${COMPARTMENT} -c ${ROOT_COMPARTMENT_OCID} --description "Oracle Advanced Queue workflow" --wait-for-state ACTIVE
    echo "COMPARTMENT '${COMPARTMENT}' CREATED."
else
    echo "Compartment '${COMPARTMENT}' already exists."
fi

export COMPARTMENT_OCID=$(oci iam compartment list --all | jq -r ".data[] | select(.name == \"${COMPARTMENT}\") | .id")

create_db() {
    #Get the database password

    echo "NOTE: Password must contain:"
    echo "* 12 to 30 characters"
    echo "* at least one uppercase letter"
    echo "* at least one lowercase letter"
    echo "* at least one number"
    echo "* The password cannot start with a numeric letter"
    echo "* The password cannot contain the double quote character or the username 'admin' "
    while true; do
        read -s -r -p "ENTER THE DATABASE PASSWORD: " db_pwd
        if [[ ${#db_pwd} -ge 12 && ${#db_pwd} -le 30 &&
            "$db_pwd" =~ [A-Z] && "$db_pwd" =~ [a-z] && "$db_pwd" =~ [0-9] &&
            "$db_pwd" =~ ^[^0-9] && "$db_pwd" != *admin* && "$db_pwd" != *'"'* ]]; then
            echo
            break
        else
            echo "Invalid Password, please retry"
        fi
    done
    umask 177
    DB_PASSWORD="$db_pwd"
    WALLET_PASSWORD="$db_pwd"
    umask 22

    # Create ATP- #21c always free
    umask 177
    echo '{"adminPassword": "'"$DB_PASSWORD"'"}' >temp_params
    umask 22
    oci db autonomous-database create -c ${COMPARTMENT_OCID} --db-name ${DB_NAME} --display-name ${DB_NAME} --db-workload OLTP --is-free-tier true --cpu-core-count 1 --data-storage-size-in-tbs 1 --db-version "21c" --wait-for-state AVAILABLE --wait-interval-seconds 5 --from-json "file://temp_params"
    rm temp_params
}

export DB_ID=$(oci db autonomous-database list -c ${COMPARTMENT_OCID} --query "data[?\"db-name\"=='aqdatabase'].id | [0]" --raw-output)
if [[ -z "${DB_ID}" ]]; then
    create_db
else
    echo "ATP '${DB_NAME}' already exists."
    while true; do
        read -p "Database '${DB_NAME}' already exists. Do you want to delete the existing ATP database [y/n]?" yn
        case $yn in
        [Yy]*)
            echo "Deleting existing database. Please wait..."
            oci db autonomous-database delete --autonomous-database-id ${DB_ID} --force --wait-for-state SUCCEEDED
            echo "Creating new database."
            create_db
            break
            ;;
        [Nn]*)
            read -s -r -p " " db_pwd
            while true; do
                read -s -r -p "Enter the password used to create existing ATP: " db_pwd
                if [[ ${#db_pwd} -ge 12 && ${#db_pwd} -le 30 &&
                    "$db_pwd" =~ [A-Z] && "$db_pwd" =~ [a-z] && "$db_pwd" =~ [0-9] &&
                    "$db_pwd" =~ ^[^0-9] && "$db_pwd" != *admin* && "$db_pwd" != *'"'* ]]; then
                    echo
                    break
                else
                    echo "Invalid Password, please retry"
                fi
            done
            ;;
        esac
    done
fi

# Get connection string
DB_OCID=$(oci db autonomous-database list -c ${COMPARTMENT_OCID} --query "data [?\"db-name\"=='${DB_NAME}'] | [0].id" --raw-output)
export DB_ALIAS=$(oci db autonomous-database get --autonomous-database-id "$DB_OCID" --query 'data."connection-strings".profiles[?"consumer-group"=='"'TP'"']."display-name" | [0]' --raw-output)

# Generating wallet
mkdir -p $TNS_ADMIN
mkdir -p $TNS_ADMIN_FOR_JAVA
cd $TNS_ADMIN
umask 177
echo '{"password": "'"$DB_PASSWORD"'"}' >temp_params
umask 22
oci db autonomous-database generate-wallet --autonomous-database-id "$DB_OCID" --file 'wallet.zip' --from-json "file://temp_params"
rm temp_params
unzip -oq wallet.zip

#copy wallet for Java
cp wallet.zip $TNS_ADMIN_FOR_JAVA/
cd $TNS_ADMIN_FOR_JAVA
unzip -oq wallet.zip
#Configure sqlnet.ora for java
cat >sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$TNS_ADMIN_FOR_JAVA")))
SQLNET.WALLET_OVERRIDE = TRUE
SSL_SERVER_DN_MATCH = yes
!

#Configure sqlnet.ora for ADMIN
cd $TNS_ADMIN
cat >sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$USER_DEFINED_WALLET")))
SQLNET.WALLET_OVERRIDE = TRUE
SSL_SERVER_DN_MATCH = yes
!

rm -rf $USER_DEFINED_WALLET
mkdir -p $USER_DEFINED_WALLET

# Add the admin credential to the wallet
# set classpath for mkstore - align this to your local SQLcl installation
#export SQLCL=$(dirname $(which sql))/../lib
export SQLCL=/opt/oracle/sqlcl/lib
export CLASSPATH=${SQLCL}/oraclepki.jar:${SQLCL}/osdt_core.jar:${SQLCL}/osdt_cert.jar

# Create New User Defined Wallet to store DB Credentials
java -classpath ${CLASSPATH} oracle.security.pki.OracleSecretStoreTextUI -nologo -wrl "$USER_DEFINED_WALLET" -create >/dev/null <<!
$WALLET_PASSWORD
$WALLET_PASSWORD
!

# Add User1 Credentials to the newly created User Defined Wallet
java -classpath ${CLASSPATH} oracle.security.pki.OracleSecretStoreTextUI -nologo -wrl "$USER_DEFINED_WALLET" -createCredential "${DB_ALIAS}_${PLSQL_DB_USER1}" $PLSQL_DB_USER1 >/dev/null <<!
$DB_PASSWORD
$DB_PASSWORD
$WALLET_PASSWORD
!

# ADD TNS Aliases to the TNSNAMES.ORA
tns_alias=$(grep "$DB_ALIAS " $TNS_ADMIN/tnsnames.ora)
tns_alias=${tns_alias/security=/security= $TNS_WALLET_STR}
tns_alias1=${tns_alias/$DB_ALIAS /${DB_ALIAS}_${PLSQL_DB_USER1} }

echo $tns_alias1 >>$TNS_ADMIN/tnsnames.ora

# Print names of the newly created TNS Aliases
echo "Added TNS Alias: ${DB_ALIAS}_${PLSQL_DB_USER1}"

sqlplus /@${DB_ALIAS}_${PLSQL_DB_USER1} <<!
SET VERIFY OFF;

CREATE USER ${JAVA_DB_USER} IDENTIFIED BY $DB_PASSWORD ;
SET echo off;
GRANT execute on DBMS_AQ TO ${JAVA_DB_USER};
GRANT CREATE SESSION TO ${JAVA_DB_USER};
GRANT RESOURCE TO ${JAVA_DB_USER};
GRANT CONNECT TO ${JAVA_DB_USER};
GRANT EXECUTE ANY PROCEDURE TO ${JAVA_DB_USER};
GRANT AQ_USER_ROLE TO ${JAVA_DB_USER};
GRANT EXECUTE ON dbms_aqadm TO ${JAVA_DB_USER};
GRANT EXECUTE ON dbms_aq TO ${JAVA_DB_USER} ;
GRANT EXECUTE ON dbms_aqin TO ${JAVA_DB_USER};
GRANT UNLIMITED TABLESPACE TO ${JAVA_DB_USER};
GRANT EXECUTE ON DBMS_CLOUD_ADMIN TO ${JAVA_DB_USER};
GRANT PDB_DBA TO ${JAVA_DB_USER};
GRANT EXECUTE ON DBMS_CLOUD TO ${JAVA_DB_USER};
GRANT CREATE DATABASE LINK TO ${JAVA_DB_USER};
GRANT EXECUTE ON sys.dbms_aqadm TO ${JAVA_DB_USER};
GRANT EXECUTE ON sys.dbms_aq TO ${JAVA_DB_USER};
EXIT;
!

cd $ORACLEAQ_HOME
export TNS_ADMIN=${TNS_ADMIN_FOR_JAVA}
sqlplus /@"${DB_ALIAS}" <<!
Show user;
!
#Java Setup

# Add JavaUser Credentials to the ATP Wallet
cd ..
cd $TNS_ADMIN_FOR_JAVA
java -Doracle.pki.debug=true -classpath ${CLASSPATH} oracle.security.pki.OracleSecretStoreTextUI -nologo -wrl "$TNS_ADMIN_FOR_JAVA" -createCredential "${DB_ALIAS}" $JAVA_DB_USER >/dev/null <<!
$DB_PASSWORD
$DB_PASSWORD
$WALLET_PASSWORD
!

export JDBC_URL=jdbc:oracle:thin:@${DB_ALIAS}?TNS_ADMIN=${TNS_ADMIN_FOR_JAVA}

#Build java code
cd ../
cd $ORACLEAQ_JAVA
{
    mvn clean install -Dmaven.wagon.http.ssl.insecure=true -Dmaven.test.skip=true
    cd target
    nohup java -jar qJava-0.0.1-SNAPSHOT.jar &
} &>/dev/null
echo "Java setup completed."

#Node.js setup
cd $ORACLEAQ_HOME
npm install oracledb debug
echo "node.js setup completed."

echo "ORACLEAQ_HOME     : "$ORACLEAQ_HOME
echo "COMPARTMENT NAME  : "${COMPARTMENT}
echo "COMPARTMENT OCID  : "${COMPARTMENT_OCID}
echo "DATABASE NAME     : "${DB_NAME}
echo "ATP OCID          : "${DB_OCID}
echo "TNS ALIAS- USER1  :  ${DB_ALIAS}_${PLSQL_DB_USER1}"
echo "TNS ALIAS- USER2  : "${DB_ALIAS}
echo "JDBC URL          : "${JDBC_URL}
echo
echo "-------------------------------"
echo "        SETUP COMPLETED        "
echo "-------------------------------"
