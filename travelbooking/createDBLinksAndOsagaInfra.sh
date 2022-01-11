#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

pwd=$(pwd)
echo $pwd
export TNS_ADMIN=$pwd/wallet
echo TNS_ADMIN = $TNS_ADMIN

#echo ____________________________________________________
export sagadb1_tptnsentry=$(grep -i "sagadb1_tp " $TNS_ADMIN/tnsnames.ora)
echo ____________________________________________________
# for each variable, string off begin (based on identifier)
echo sagadb1hostname...
export b="(host="
export sagadb1hostname=$(echo ${sagadb1_tptnsentry/*$b/$b})
export c="))(connect_data="
export sagadb1hostname=$(echo ${sagadb1hostname/$c*/$c})
export sagadb1hostname=${sagadb1hostname#"$b"}
export sagadb1hostname=${sagadb1hostname%"$c"}
echo $sagadb1hostname
echo
echo sagadb1port...
export b="(port="
export sagadb1port=$(echo ${sagadb1_tptnsentry/*$b/$b})
export c=")(host"
export sagadb1port=$(echo ${sagadb1port/$c*/$c})
export sagadb1port=${sagadb1port#"$b"}
export sagadb1port=${sagadb1port%"$c"}
echo $sagadb1port
echo
echo sagadb1service_name...
export b="(service_name="
export sagadb1service_name=$(echo ${sagadb1_tptnsentry/*$b/$b})
export c="))(security"
export sagadb1service_name=$(echo ${sagadb1service_name/$c*/$c})
export sagadb1service_name=${sagadb1service_name#"$b"}
export sagadb1service_name=${sagadb1service_name%"$c"}
echo $sagadb1service_name
echo
echo sagadb1ssl_server_cert_dn...
export b="(ssl_server_cert_dn=\""
export sagadb1ssl_server_cert_dn=$(echo ${sagadb1_tptnsentry/*$b/$b})
export c="\")))"
export sagadb1ssl_server_cert_dn=$(echo ${sagadb1ssl_server_cert_dn/$c*/$c})
export sagadb1ssl_server_cert_dn=${sagadb1ssl_server_cert_dn#"$b"}
export sagadb1ssl_server_cert_dn=${sagadb1ssl_server_cert_dn%"$c"}
echo $sagadb1ssl_server_cert_dn


#echo ____________________________________________________
export sagadb2_tptnsentry=$(grep -i "sagadb2_tp " $TNS_ADMIN/tnsnames.ora)
echo ____________________________________________________
# for each variable, string off begin (based on identifier)
echo sagadb2hostname...
export b="(host="
export sagadb2hostname=$(echo ${sagadb2_tptnsentry/*$b/$b})
export c="))(connect_data="
export sagadb2hostname=$(echo ${sagadb2hostname/$c*/$c})
export sagadb2hostname=${sagadb2hostname#"$b"}
export sagadb2hostname=${sagadb2hostname%"$c"}
echo $sagadb2hostname
echo
echo sagadb2port...
export b="(port="
export sagadb2port=$(echo ${sagadb2_tptnsentry/*$b/$b})
export c=")(host"
export sagadb2port=$(echo ${sagadb2port/$c*/$c})
export sagadb2port=${sagadb2port#"$b"}
export sagadb2port=${sagadb2port%"$c"}
echo $sagadb2port
echo
echo sagadb2service_name...
export b="(service_name="
export sagadb2service_name=$(echo ${sagadb2_tptnsentry/*$b/$b})
export c="))(security"
export sagadb2service_name=$(echo ${sagadb2service_name/$c*/$c})
export sagadb2service_name=${sagadb2service_name#"$b"}
export sagadb2service_name=${sagadb2service_name%"$c"}
echo $sagadb2service_name
echo
echo sagadb2ssl_server_cert_dn...
export b="(ssl_server_cert_dn=\""
export sagadb2ssl_server_cert_dn=$(echo ${sagadb2_tptnsentry/*$b/$b})
export c="\")))"
export sagadb2ssl_server_cert_dn=$(echo ${sagadb2ssl_server_cert_dn/$c*/$c})
export sagadb2ssl_server_cert_dn=${sagadb2ssl_server_cert_dn#"$b"}
export sagadb2ssl_server_cert_dn=${sagadb2ssl_server_cert_dn%"$c"}
echo $sagadb2ssl_server_cert_dn



echo setting up DB links and OSaga infrastructure ...
cd osaga-java-api
#nohup java -jar
java -jar target/osaga-java-api.jar
cd ../


