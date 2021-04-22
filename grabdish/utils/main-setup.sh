#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Check home is set
if test -z "$GRABDISH_HOME"; then
  echo "ERROR: This script requires GRABDISH_HOME to be set"
  exit
fi


# Get the User OCID
while ! state_done USER_OCID; do
  read -p "Please enter your OCI user's OCID: " USER_OCID
  # Validate
  if test ""`oci iam user get --user-id "$USER_OCID" --query 'data."lifecycle-state"' --raw-output 2>$GRABDISH_LOG/user_ocid_err` == 'ACTIVE'; then
    state_set USER_OCID "$USER_OCID"
  else
    echo "That user OCID could not be validated"
    cat $GRABDISH_LOG/user_ocid_err
  fi
done


# Get User Name
while ! state_done USER_NAME; do
  USER_NAME=`oci iam user get --user-id "$(state_get USER_OCID)" --query "data.name" --raw-output`
  state_set USER_NAME "$USER_NAME"
done


# Identify Run Type
while ! state_done RUN_TYPE; do
  if [[ "$USERNAME" =~ LL[0-9]{4,4}-USER$ ]]; then
    # Green Button
    state_set RUN_TYPE "3"
  else
    state_set RUN_TYPE "1" 
  fi
done


# Get Run Name from directory name
while ! state_done RUN_NAME; do
  cd $GRABDISH_HOME
  cd ../..
  # Validate that a folder was creared
  if test "$PWD" == ~; then 
    echo "ERROR: The workshop is not installed in a separate folder."
    exit
  fi
  RN=`basename "$PWD"`
  # Validate run name.  Must be between 1 and 12 characters, only letters or numbers, starting with letter
  if [[ "$RN" =~ [a-zA-Z][a-zA-Z0-9]{0,11}$ ]]; then
    state_set RUN_NAME "$RN"
    state_set ORDER_DB_NAME "${RN}o"
    state_set INVENTORY_DB_NAME "${RN}i"
  else
    echo "Invalid folder name $RN"
    exit
  fi
  cd $GRABDISH_HOME
done


# Get the tenancy OCID
while ! state_done TENANCY_OCID; do
  state_set TENANCY_OCID "$OCI_TENANCY" # Set in cloud shell env
done


# Double check and then set the region
while ! state_done REGION; do
  HOME_REGION=`oci iam region-subscription list --query 'data[?"is-home-region"]."region-name" | join('\'' '\'', @)' --raw-output`
  if test "$OCI_REGION" != "$HOME_REGION"; then
    echo "This script only works in the home OCI region.  Please switch to the $HOME_REGION and retry."
    exit
  fi
  state_set REGION "$OCI_REGION" # Set in cloud shell env
done


# Create the compartment
while ! state_done COMPARTMENT_OCID; do
  echo "Resources will be created in a new compartment named $(state_get RUN_NAME)"
  COMPARTMENT_OCID=`oci iam compartment create --compartment-id "$(state_get TENANCY_OCID)" --name "$(state_get RUN_NAME)" --description "GribDish Workshop" --query 'data.id' --raw-output`
  while ! test `oci iam compartment get --compartment-id "$COMPARTMENT_OCID" --query 'data."lifecycle-state"' --raw-output`"" == 'ACTIVE'; do
    echo "Waiting for the compartment to become ACTIVE"
    sleep 2
  done
  state_set COMPARTMENT_OCID "$COMPARTMENT_OCID"
done


# Switch to SSH Key auth for the oci cli (workaround to perm issue awaiting fix)
source $GRABDISH_HOME/utils/oci-cli-cs-key-auth.sh


# Run the terraform.sh in the background
if ! state_get PROVISIONING; then
  if ps -ef | grep "$GRABDISH_HOME/utils/terraform.sh" | grep -v grep; then
    echo "$GRABDISH_HOME/utils/terraform.sh is already running"
  else
    echo "Executing terraform.sh in the background"
    nohup $GRABDISH_HOME/utils/terraform.sh &>> $GRABDISH_LOG/terraform.log &
  fi
fi


# Get Namespace
while ! state_done NAMESPACE; do
  NAMESPACE=`oci os ns get --compartment-id "$(state_get COMPARTMENT_OCID)" --query "data" --raw-output`
  state_set NAMESPACE "$NAMESPACE"
done


# login to docker
while ! state_done DOCKER_REGISTRY; do
  if ! TOKEN=`oci iam auth-token create  --user-id "$(state_get USER_OCID)" --description 'grabdish docker login' --query 'data.token' --raw-output 2>$GRABDISH_LOG/docker_registry_err`; then
    if grep UserCapacityExceeded $GRABDISH_LOG/docker_registry_err >/dev/null; then 
      # The key already exists
      echo 'ERROR: Failed to create auth token.  Please delete an old token from the OCI Console (Profile -> User Settings -> Auth Tokens).'
      read -p "Hit return when you are ready to retry?"
    else
      echo "ERROR: Creating auth token had failed:"
      cat $GRABDISH_LOG/docker_registry_err
      exit
    fi
  else
    sleep 5 # Allow time for the auth token to come into effect
    RETRIES=0
    while test $RETRIES -le 10; do
      if echo "$TOKEN" | docker login -u "$(state_get NAMESPACE)/$(state_get USER_NAME)" --password-stdin "$(state_get REGION).ocir.io"; then
        state_set DOCKER_REGISTRY "$(state_get REGION).ocir.io/$(state_get NAMESPACE)/$(state_get RUN_NAME)"
        break
      else
        echo "Docker login failed.  Retrying"
        RETRIES=$((RETRIES+1))
        sleep 5
      fi
    done
  fi
done


# Run the build-all.sh in the background
if ! state_get BUILD_ALL; then
  if ps -ef | grep "$GRABDISH_HOME/utils/build-all.sh" | grep -v grep; then
    echo "$GRABDISH_HOME/utils/build-all.sh is already running"
  else
    echo "Executing build-all.sh in the background"
    nohup $GRABDISH_HOME/utils/build-all.sh &>> $GRABDISH_LOG/build-all.log &
  fi
fi


## Run the java-builds.sh in the background
if ! state_get JAVA_BUILDS; then
  if ps -ef | grep "$GRABDISH_HOME/utils/java-builds.sh" | grep -v grep; then
    echo "$GRABDISH_HOME/utils/java-builds.sh is already running"
  else
    echo "Executing java-builds.sh in the background"
    nohup $GRABDISH_HOME/utils/java-builds.sh &>> $GRABDISH_LOG/java-builds.log &
  fi
fi


# Run the non-java-builds.sh in the background
if ! state_get NON_JAVA_BUILDS; then
  if ps -ef | grep "$GRABDISH_HOME/utils/non-java-builds.sh" | grep -v grep; then
    echo "$GRABDISH_HOME/utils/non-java-builds.sh is already running"
  else
    echo "Executing non-java-builds.sh in the background"
    nohup $GRABDISH_HOME/utils/non-java-builds.sh &>> $GRABDISH_LOG/non-java-builds.log &
  fi
fi


# run oke-setup.sh in background
if ! state_get OKE_SETUP; then
  if ps -ef | grep "$GRABDISH_HOME/utils/oke-setup.sh" | grep -v grep; then
    echo "$GRABDISH_HOME/utils/oke-setup.sh is already running"
  else
    echo "Executing oke-setup.sh in the background"
    nohup $GRABDISH_HOME/utils/oke-setup.sh &>>$GRABDISH_LOG/oke-setup.log &
  fi
fi


# run db-setup.sh in background
if ! state_get DB_SETUP; then
  if ps -ef | grep "$GRABDISH_HOME/utils/db-setup.sh" | grep -v grep; then
    echo "$GRABDISH_HOME/utils/db-setup.sh is already running"
  else
    echo "Executing db-setup.sh in the background"
    nohup $GRABDISH_HOME/utils/db-setup.sh &>>$GRABDISH_LOG/db-setup.log &
  fi
fi


# Wait for provisioning
if ! state_done PROVISIONING; then
  echo "`date`: Waiting for terraform provisioning"
  while ! state_done PROVISIONING; do
    LOGLINE=`tail -1 $GRABDISH_LOG/terraform.log`
    echo -ne r"\033[2K\r${LOGLINE:0:120}"
    sleep 2
  done
  echo
fi


# Get Order DB OCID
while ! state_done ORDER_DB_OCID; do
  ORDER_DB_OCID=`oci db autonomous-database list --compartment-id "$(cat state/COMPARTMENT_OCID)" --query 'join('"' '"',data[?"display-name"=='"'ORDERDB'"'].id)' --raw-output`
  if [[ "$ORDER_DB_OCID" =~ ocid1.autonomousdatabase* ]]; then
    state_set ORDER_DB_OCID "$ORDER_DB_OCID"
  else
    echo "ERROR: Incorrect Order DB OCID: $ORDER_DB_OCID"
    exit
  fi
done


# Get Inventory DB OCID
while ! state_done INVENTORY_DB_OCID; do
  INVENTORY_DB_OCID=`oci db autonomous-database list --compartment-id "$(cat state/COMPARTMENT_OCID)" --query 'join('"' '"',data[?"display-name"=='"'INVENTORYDB'"'].id)' --raw-output`
  if [[ "$INVENTORY_DB_OCID" =~ ocid1.autonomousdatabase* ]]; then
    state_set INVENTORY_DB_OCID "$INVENTORY_DB_OCID"
  else
    echo "ERROR: Incorrect Inventory DB OCID: $INVENTORY_DB_OCID"
    exit
  fi
done


# Wait for kubectl Setup
if ! state_done OKE_NAMESPACE; then
  echo "`date`: Waiting for kubectl configuration and msdataworkshop namespace"
  while ! state_done OKE_NAMESPACE; do
    LOGLINE=`tail -1 $GRABDISH_LOG/state.log`
    echo -ne r"\033[2K\r${LOGLINE:0:120}"
    sleep 2
  done
  echo
fi


# Collect DB password and create secret
while ! state_done DB_PASSWORD; do
  echo
  echo 'Database passwords must be 12 to 30 characters and contain at least one uppercase letter,'
  echo 'one lowercase letter, and one number. The password cannot contain the double quote (")'
  echo 'character or the word "admin".'
  echo

  while true; do
    read -s -r -p "Enter the password to be used for the order and inventory databases: " PW
      if [[ ${#PW} -ge 12 && ${#PW} -le 30 && "$PW" =~ [A-Z] && "$PW" =~ [a-z] && "$PW" =~ [0-9] && "$PW" != *admin* && "$PW" != *'"'* ]]; then
      echo
      break
    else
      echo "Invalid Password, please retry"
    fi
  done

  #Set password in OKE secret
  BASE64_DB_PASSWORD=`echo -n "$PW" | base64`
  
  while true; do
    if kubectl create -n msdataworkshop -f -; then
      state_set_done DB_PASSWORD
      break
    else
      echo 'Error: Creating DB Password Secret Failed.  Retrying...'
      sleep 10
    fi <<!
{
   "apiVersion": "v1",
   "kind": "Secret",
   "metadata": {
      "name": "dbuser"
   },
   "data": {
      "dbpassword": "${BASE64_DB_PASSWORD}"
   }
}
!
  done
done


# Collect UI password and create secret
while ! state_done UI_PASSWORD; do
  echo
  echo 'UI passwords must be 8 to 30 characters'
  echo

  while true; do
    read -s -r -p "Enter the password to be used for accessing the UI: " PW
      if [[ ${#PW} -ge 8 && ${#PW} -le 30 ]]; then
      echo
      break
    else
      echo "Invalid Password, please retry"
    fi
  done

  #Set password in OKE secret
  BASE64_UI_PASSWORD=`echo -n "$PW" | base64`

  while true; do
    if kubectl create -n msdataworkshop -f -; then
      state_set_done UI_PASSWORD
      break
    else
      echo 'Error: Creating UI Password Secret Failed.  Retrying...'
      sleep 10
    fi <<!
{
   "apiVersion": "v1",
   "kind": "Secret",
   "metadata": {
      "name": "frontendadmin"
   },
   "data": {
      "password": "${BASE64_UI_PASSWORD}"
   }
}
!
  done
done


# Set admin password in order database
while ! state_done ORDER_DB_PASSWORD_SET; do
  # get password from vault secret
  DB_PASSWORD=`kubectl get secret dbuser -n msdataworkshop --template={{.data.dbpassword}} | base64 --decode`
  umask 177
  echo '{"adminPassword": "'"$DB_PASSWORD"'"}' > temp_params
  umask 22
  oci db autonomous-database update --autonomous-database-id "$(state_get ORDER_DB_OCID)" --from-json "file://temp_params" >/dev/null
  rm temp_params
  state_set_done ORDER_DB_PASSWORD_SET
done


# Set admin password in inventory database
while ! state_done INVENTORY_DB_PASSWORD_SET; do
  # get password from vault secret
  DB_PASSWORD=`kubectl get secret dbuser -n msdataworkshop --template={{.data.dbpassword}} | base64 --decode`
  umask 177
  echo '{"adminPassword": "'"$DB_PASSWORD"'"}' > temp_params
  umask 22 

  oci db autonomous-database update --autonomous-database-id "$(state_get INVENTORY_DB_OCID)" --from-json "file://temp_params" >/dev/null
  rm temp_params
  state_set_done INVENTORY_DB_PASSWORD_SET
done


ps -ef | grep "$GRABDISH_HOME/utils" | grep -v grep


# Verify Setup
bgs="BUILD_ALL JAVA_BUILDS NON_JAVA_BUILDS OKE_SETUP DB_SETUP PROVISIONING"
while ! state_done SETUP_VERIFIED; do
  NOT_DONE=0
  bg_not_done=
  for bg in $bgs; do
    if state_done $bg; then
      echo "$bg completed"
    else
      echo "$bg has not completed"
      NOT_DONE=$((NOT_DONE+1))
      bg_not_done="$bg_not_done $bg"
    fi
  done
  if test "$NOT_DONE" -gt 0; then
    echo "Log files are located in $GRABDISH_LOG"
    bgs=$bg_not_done
    sleep 10
  else
    state_set_done SETUP_VERIFIED
  fi
done