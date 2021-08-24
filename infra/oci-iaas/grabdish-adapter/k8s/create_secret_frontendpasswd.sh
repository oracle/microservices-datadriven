#/bin/bash
# Fail on error
set -e

CURL_METADATA_COMMAND="curl -L http://169.254.169.254/opc/v1/instance/metadata"
app_public_repo=$($CURL_METADATA_COMMAND | jq --raw-output  '.grabdish_application_password')
#BASE64PWD=$(echo -n $1 | base64)

BASE64PWD=$(echo -n $app_public_repo | base64)


#while ! state_done FRONTEND_PASSWORD; do
  while true; do
    if kubectl apply -n msdataworkshop -f -; then
      state_set_done FRONTEND_PASSWORD
      break
    else
      echo 'Error: Creating DB Password Secret Failed.  Retrying...'
      sleep 10
    fi <<!
apiVersion: v1
data:
  password: $BASE64PWD
kind: Secret
metadata:
  name: frontendadmin
!
  done
#done
