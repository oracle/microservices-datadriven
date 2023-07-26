#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

pwd=$(pwd)
echo $pwd
export TNS_ADMIN=$pwd/wallet
echo TNS_ADMIN = $TNS_ADMIN

export sagadb1_tptnsentry=$(grep -i "sagadb1_tp " $TNS_ADMIN/tnsnames.ora)
echo ____________________________________________________
# for each variable, string off begin (based on identifier)

export sagadb1hostname="NULL"
host=$(echo $sagadb1_tptnsentry | sed -nE 's/.*host=([^)]+).*/\1/ip')
if [[ -n $host ]]; then
    sagadb1hostname=$host
fi

export sagadb1port="NULL"
port=$(echo $sagadb1_tptnsentry | sed -nE 's/.*port=([^)]+).*/\1/ip')
if [[ -n $port ]]; then
    export sagadb1port=$port
fi

export sagadb1service_name="NULL"
service_name=$(echo $sagadb1_tptnsentry | sed -nE 's/.*service_name=([^)]+).*/\1/ip')
if [[ -n $service_name ]]; then
    export sagadb1service_name=$service_name
fi

export sagadb1ssl_server_cert_dn="NULL"
ssl_server_cert_dn=$(echo $sagadb1_tptnsentry | sed -nE 's/.*ssl_server_cert_dn=([^)]+).*/\1/ip')
if [[ -n $ssl_server_cert_dn ]]; then
    export sagadb1ssl_server_cert_dn=$ssl_server_cert_dn
fi

echo $sagadb1hostname
echo $sagadb1port
echo $sagadb1service_name
echo $sagadb1ssl_server_cert_dn


export sagadb2_tptnsentry=$(grep -i "sagadb2_tp " $TNS_ADMIN/tnsnames.ora)
echo ____________________________________________________
# for each variable, string off begin (based on identifier)
export sagadb2hostname="NULL"
host=$(echo $sagadb2_tptnsentry | sed -nE 's/.*host=([^)]+).*/\1/ip')
if [[ -n $host ]]; then
    sagadb2hostname=$host
fi

export sagadb2port="NULL"
port=$(echo $sagadb2_tptnsentry | sed -nE 's/.*port=([^)]+).*/\1/ip')
if [[ -n $port ]]; then
    export sagadb2port=$port
fi

export sagadb2service_name="NULL"
service_name=$(echo $sagadb2_tptnsentry | sed -nE 's/.*service_name=([^)]+).*/\1/ip')
if [[ -n $service_name ]]; then
    export sagadb2service_name=$service_name
fi

export sagadb2ssl_server_cert_dn="NULL"
ssl_server_cert_dn=$(echo $sagadb2_tptnsentry | sed -nE 's/.*ssl_server_cert_dn=([^)]+).*/\1/ip')
if [[ -n $ssl_server_cert_dn ]]; then
    export sagadb2ssl_server_cert_dn=$ssl_server_cert_dn
fi

echo $sagadb2hostname
echo $sagadb2port
echo $sagadb2service_name
echo $sagadb2ssl_server_cert_dn
echo ____________________________________________________

echo setting up DB links and OSaga infrastructure ...
cd osaga-java-api
mvn clean install
java -jar target/osaga-java-api.jar
cd ../

