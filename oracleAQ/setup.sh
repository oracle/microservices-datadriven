#!/bin/bash

# variable declarations
export comp_name="oracleAQ";   
export db_name="aqdatabase"; 
mkdir -p $comp_name ;
export WORKFLOW_HOME=${HOME}/${comp_name}; 
export display_name=${db_name}                                      
export TNS_ADMIN=$WORKFLOW_HOME/network/admin 
#export db_pwd="WelcomeAQ1234";

#get user's OCID
   # read user's OCID
#echo "Enter OCID of root compartment:" ; read -s rootCompOCID; export rootCompOCID                          
   # fetch user's OCID
rootCompOCID=$(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --raw-output --query "data[?contains(\"id\",'tenancy')].id | [0]")

#Create compartment
oci iam compartment create --name ${comp_name} -c ${rootCompOCID} --description "Oracle Advanced Queue workflow" --wait-for-state ACTIVE  
ocid_comp=$(oci iam compartment list --all | jq -r ".data[] | select(.name == \"${comp_name}\") | .id")

#Get the database password
echo "Enter Database Password :" ; 
echo "NOTE: Password must be 12 to 30 characters and contain at least one uppercase letter, one lowercase letter, and one number. The password cannot contain the double quote character or the username 'admin' ";
read -s db_pwd; export db_pwd

# Create ATP
   #21c always free
oci db autonomous-database create --admin-password ${db_pwd} -c ${ocid_comp} --db-name ${db_name} --display-name ${db_name} --db-workload OLTP --is-free-tier true --cpu-core-count 1 --data-storage-size-in-tbs 1 --db-version "21c" --wait-for-state AVAILABLE --wait-interval-seconds 5;
   #19c default
#oci db autonomous-database create --admin-password ${db_pwd} -c ${ocid_comp} --db-name ${db_name} --display-name ${db_name} --db-workload OLTP --cpu-core-count 1 --data-storage-size-in-tbs 1 

# Get connection string
db_conn=$(oci db autonomous-database list -c ${ocid_comp} --query "data [?\"db-name\"=='${db_name}'] | [0].\"connection-strings\".low" --raw-output)
adb_id=$(oci db autonomous-database list -c ${ocid_comp} --query "data [?\"db-name\"=='${db_name}'] | [0].id" --raw-output)

# Generating wallet
mkdir -p ${TNS_ADMIN}
cd $TNS_ADMIN;
oci db autonomous-database generate-wallet --autonomous-database-id ${adb_id} --password ${db_pwd} --file wallet.zip --generate-type ALL
unzip wallet.zip

# create DBUSER
cd $WORKFLOW_HOME;
sql /nolog @$WORKFLOW_HOME/basicCreateUser.sql $db_pwd

# Java setup
cd $WORKFLOW_HOME/aqJava;
mvn clean install
cd target
killall java
nohup java -jar aqJava-0.0.1-SNAPSHOT.jar &
echo "Setup completed."

cd $WORKFLOW_HOME;

echo "WORKFLOW_HOME     : " $WORKFLOW_HOME;
echo "Compartment Name  : " ${comp_name}
echo "Compartment OCID  : " ${ocid_comp}
echo "Database Name     : " ${db_name}
echo "ATP Database OCID : " ${adb_id}
echo "TNS Conn String   : " ${display_name}_tp