#!/bin/bash
# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 
export COMPARTMENT="dra"
export DB_NAME="dradb"
export DB_ADMIN_USER="admin"
export DB_NORMAL_USER="tkdradata"
export DRA_HOME=${HOME}/microservices-data-refactoring
export TNS_ADMIN=$DRA_HOME/wallet
export DB_ALIAS="dradb_tp"
export SQLCL=/opt/oracle/sqlcl/lib

# fetch user's OCID
ROOT_COMPARTMENT_OCID=$(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --raw-output --query "data[?contains(\"id\",'tenancy')].id | [0]")

# Create compartment
oci iam compartment create --name ${COMPARTMENT} -c ${ROOT_COMPARTMENT_OCID} --description "Oracle Data Refactoring Assistant" --wait-for-state ACTIVE
COMPARTMENT_OCID=$(oci iam compartment list --all | jq -r ".data[] | select(.name == \"${COMPARTMENT}\") | .id")

#Get the database password
echo "ENTER THE DATABASE PASSWORD:" ;
echo "NOTE: Password must contain:"
echo "* 12 to 30 characters"
echo "* at least one uppercase letter"
echo "* at least one lowercase letter"
echo "* at least one number"
echo "* The password cannot contain the double quote character or the username 'admin' ";
while true; do
    read -s -r -p "Please enter the password to be used for the database users: " db_pwd
    if [[ ${#db_pwd} -ge 12 && ${#db_pwd} -le 30 && "$db_pwd" =~ [A-Z] && "$db_pwd" =~ [a-z] && "$db_pwd" =~ [0-9] && "$db_pwd" != *admin* && "$db_pwd" != *'"'* ]]; then
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
echo '{"adminPassword": "'"$DB_PASSWORD"'"}' > temp_params
umask 22
oci db autonomous-database create -c ${COMPARTMENT_OCID} --db-name ${DB_NAME} --display-name ${DB_NAME} --db-workload OLTP --is-free-tier true --cpu-core-count 1 --data-storage-size-in-tbs 1 --db-version "21c" --wait-for-state AVAILABLE --wait-interval-seconds 5 --from-json "file://temp_params"
rm temp_params;

# Get connection string
DB_OCID=$(oci db autonomous-database list -c ${COMPARTMENT_OCID} --query "data [?\"db-name\"=='${DB_NAME}'] | [0].id" --raw-output)
export DB_ALIAS=`oci db autonomous-database get --autonomous-database-id "$DB_OCID" --query 'data."connection-strings".profiles[?"consumer-group"=='"'TP'"']."display-name" | [0]' --raw-output`

# Generating wallet
mkdir -p $TNS_ADMIN
cd $TNS_ADMIN
umask 177
echo '{"password": "'"$DB_PASSWORD"'"}' > temp_params
umask 22
oci db autonomous-database generate-wallet --autonomous-database-id "$DB_OCID" --file 'wallet.zip' --from-json "file://temp_params"
rm temp_params
unzip -oq wallet.zip
 
#Configure sqlnet.ora for ADMIN
cd $TNS_ADMIN
cat >sqlnet.ora <<EOF
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$TNS_ADMIN")))
SQLNET.WALLET_OVERRIDE = TRUE
SSL_SERVER_DN_MATCH = yes
EOF

sqlplus ${DB_ADMIN_USER}/${DB_PASSWORD}@${DB_ALIAS} <<EOF
SET VERIFY OFF;

CREATE USER ${DB_NORMAL_USER} IDENTIFIED BY $DB_PASSWORD ;
GRANT CREATE SESSION TO ${DB_NORMAL_USER};
GRANT RESOURCE TO ${DB_NORMAL_USER};
GRANT CONNECT TO ${DB_NORMAL_USER};
GRANT CREATE TABLE TO ${DB_NORMAL_USER};
GRANT DWROLE TO ${DB_NORMAL_USER};
GRANT GRAPH_DEVELOPER TO ${DB_NORMAL_USER};
GRANT CREATE VIEW TO ${DB_NORMAL_USER};
GRANT EXECUTE ANY PROCEDURE TO ${DB_NORMAL_USER};
GRANT UNLIMITED TABLESPACE TO ${DB_NORMAL_USER};
GRANT EXECUTE ON DBMS_CLOUD_ADMIN TO ${DB_NORMAL_USER};
GRANT ADMINISTER SQL TUNING SET TO ${DB_NORMAL_USER};
GRANT SELECT ON DBA_SQLSET_PLANS TO ${DB_NORMAL_USER};

-- enable web access to graph studio
ALTER USER ${DB_NORMAL_USER} GRANT CONNECT THROUGH "GRAPH\$PROXY_USER";

-- enable web access to database actions
BEGIN
   ORDS_ADMIN.ENABLE_SCHEMA(
     p_enabled => TRUE,
     p_schema => '${DB_NORMAL_USER}',
     p_url_mapping_type => 'BASE_PATH',
     p_url_mapping_pattern => '${DB_NORMAL_USER}',
     p_auto_rest_auth => TRUE
   );
   COMMIT;
END;
/
EXIT;
EOF

echo "DRA_HOME          : "$DRA_HOME;
echo "COMPARTMENT NAME  : "${COMPARTMENT}
echo "COMPARTMENT OCID  : "${COMPARTMENT_OCID}
echo "DATABASE NAME     : "${DB_NAME}
echo "ATP OCID          : "${DB_OCID}
echo 
echo "-------------------------------"
echo "        SETUP COMPLETED        "
echo "-------------------------------"