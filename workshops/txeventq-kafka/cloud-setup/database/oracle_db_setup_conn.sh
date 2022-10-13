#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# This script configure okafka client to connect with Oracle TxEventQ.

echo "Configuring TxEventQ connection properties."
# Get Oracle Instance Name
LAB_DB_SVC="$(state_get LAB_DB_NAME)_tp"

# Get Oracle Connection String
oci db autonomous-database get --autonomous-database-id "$(state_get LAB_DB_OCID)" > .db_info
connection_string=$(jq --raw-output '.data|."connection-strings"|."all-connection-strings"|.TP' .db_info)
rm .db_info

#Define multi-character delimiter
delimiter="/"
#Concatenate the delimiter with the main string
string=$connection_string$delimiter

#Split the text based on the delimiter
myarray=()
while [[ $string ]]; do
  myarray+=( "${string%%"$delimiter"*}" )
  string=${string#*"$delimiter"}
done

if [ -z "${LAB_DB_SVC}" ]; then
  echo "ERROR: The topic name should not be empty!"
  exit 2
fi

# Setting up Oracle Instance Name & Oracle TNS Alias
#  oracle-instance-name: LAB_DB_SVC
#  tns-alias: LAB_DB_SVC
sed -i 's/LAB_DB_SVC/'"${LAB_DB_SVC}"'/g' "$LAB_HOME/springboot-txeventq/okafka-producer/src/main/resources/application.yaml"
sed -i 's/LAB_DB_SVC/'"${LAB_DB_SVC}"'/g' "$LAB_HOME/springboot-txeventq/okafka-consumer/src/main/resources/application.yaml"

# Setting up Oracle Bootstrap Servers
#  bootstrap-servers: <namedb>.<region>.oraclecloud.com:<1522>
bootstrap_server="${myarray[0]}"
sed -i 's/BOOTSTRAP_SRV/'"${bootstrap_server}"'/g' "$LAB_HOME/springboot-txeventq/okafka-producer/src/main/resources/application.yaml"
sed -i 's/BOOTSTRAP_SRV/'"${bootstrap_server}"'/g' "$LAB_HOME/springboot-txeventq/okafka-consumer/src/main/resources/application.yaml"

# Setting up Oracle Service Name
#  oracle-service-name: xxxxxxxxxxxxxxx_txeventqlab_tp.adb.oraclecloud.com
oracle_service_name="${myarray[1]}"
sed -i 's/SERVICE_NAME/'"${oracle_service_name}"'/g' "$LAB_HOME/springboot-txeventq/okafka-producer/src/main/resources/application.yaml"
sed -i 's/SERVICE_NAME/'"${oracle_service_name}"'/g' "$LAB_HOME/springboot-txeventq/okafka-consumer/src/main/resources/application.yaml"

state_set_done LAB_DB_CONNECTION