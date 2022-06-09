#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

# This script configure okafka client to connect with Oracle TEQ.

echo "Configuring TEQ connection properties."
# Get Oracle Instance Name
LAB_DB_SVC="$(state_get LAB_DB_NAME)_tp"

if [ -z "${LAB_DB_SVC}" ]; then
  echo "ERROR: The topic name should not be empty!"
  exit 2
fi

# Setting up Oracle Instance Name & Oracle TNS Alias
#  oracle-instance-name: LAB_DB_SVC
#  tns-alias: LAB_DB_SVC
sed -i 's/LAB_DB_SVC/'"${LAB_DB_SVC}"'/g' "$LAB_HOME/springboot-oracleteq/okafka-producer/src/main/resources/application.yaml"
sed -i 's/LAB_DB_SVC/'"${LAB_DB_SVC}"'/g' "$LAB_HOME/springboot-oracleteq/okafka-consumer/src/main/resources/application.yaml"

# Get Oracle Service Name


# Setting up Oracle Service Name
#  oracle-service-name: xxxxxxxxxxxxxxx_teqlab_tp.adb.oraclecloud.com

# Setting up Oracle Bootstrap Servers
#  bootstrap-servers: <namedb>.<region>.oraclecloud.com:<1522>