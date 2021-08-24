#/bin/bash

# Fail on error
set -e

CURL_METADATA_COMMAND="curl -L http://169.254.169.254/opc/v1/instance/metadata"
grabdish_database_password=$($CURL_METADATA_COMMAND | jq --raw-output  '.grabdish_database_password')
#DB_PASSWORD=$(echo -n $1 | base64)

DB_PASSWORD=$(echo -n $grabdish_database_password | base64)


#while ! state_done DB_PASSWORD; do
#  while true; do
    if kubectl apply -n msdataworkshop -f -; then
      state_set_done DB_PASSWORD
      break
    else
      echo 'Error: Creating DB Password Secret Failed.  Retrying...'
      sleep 10
    fi <<!
apiVersion: v1
data:
  dbpassword: $(echo $DB_PASSWORD)
kind: Secret
metadata:
  name: dbuser
!
#  done
#done
