#!/usr/bin/env bash

CLIENT_ID=$1
CLIENT_SECRET=$2
LB=$3

display_usage() {
    echo "This  script needs 3 parameters; CLIENT_ID, CLIENT_SECRET and LB IPADDRESS"
    echo "\n Usasge: $0 [arguments] \n"
}

if [  $# -le 2 ] 
then 
    display_usage
	exit 1
fi 

curl -k -0 --user $CLIENT_ID:$CLIENT_SECRET --data "grant_type=authorization_code&code=$1" https://${LB}/ords/ordstest/oauth/token
