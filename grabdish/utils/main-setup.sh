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

#Create log and state directories
export LOG_LOC=$GRABDISH_HOME/logs
mkdir -p $LOG_LOC
export STATE_LOC=$GRABDISH_HOME/state
mkdir -p $STATE_LOC
export STATE_LOG=$LOG_LOC/state.log
echo "!!! Starting main-setup.sh\n" >>$STATE_LOG
tail -f $STATE_LOG &

# Source the state functions
source utils/state-functions.sh


# Get Run Name from directory name
while ! state_done RUN_NAME; do
  cd $GRABDISH_HOME
  cd ../..
  state_set RUN_NAME `basename "$PWD"`
  cd $GRABDISH_HOME
done


# Identify Run Type
# Hopefully can identify shared loaned Oracle tenancy(ies)
# Ask user whether they want OCI Service or Compute based workshop
while ! state_done RUN_TYPE; do
  PS3='Please choose how you would like to provision resources to run this workshop: '
  options=("OCI Services" "Green Button" "On Prem")
  select opt in "${options[@]}"
  do
    case "$REPLY" in
      1|2|3)
        state_set RUN_TYPE "$REPLY"
        break
        ;;
      *) echo "invalid option";;
    esac
  done
done


# Get the User OCID
while ! state_done USER_OCID; do
  read -p "Please enter your OCI user's OCID: " USER_OCID
  # Validate
  if test `oci iam user get --user-id "$USER_OCID" --query 'data."lifecycle-state"' --raw-output` == 'ACTIVE'; then
    state_set USER_OCID "$USER_OCID"
  else
    echo "That user could not be validated"
  fi
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
  COMPARTMENT_OCID=`oci iam compartment create --compartment-id "$(state_get TENANCY_OCID)" --name "$(state_get RUN_NAME)" --description "GribDish Workshop" --query 'data.id' --raw-output`
  while `oci iam compartment get --compartment-id "$COMPARTMENT_OCID" --query 'data."lifecycle-state"' --raw-output` != 'ACTIVE'; do
    echo "Waiting for the compartment to become ACTIVE"
    sleep 2
  done
  state_set COMPARTMENT_OCID "$COMPARTMENT_OCID"
done
echo "Compartment: $(state_get RUN_NAME) with OCID: $(state_get COMPARTMENT_OCID)"


# Run the build-all.sh in the background
$GRABDISH_HOME/utils/build-all.sh &>> $LOG_LOC/build-all.log &


# Switch to SSH Key auth for the oci cli (workaround to perm issue awaiting fix)
source $GRABDISH_HOME/utils/oci-cli-cs-key-auth.sh


# Run the terraform.sh in the background
$GRABDISH_HOME/utils/terraform.sh &>> $LOG_LOC/terraform.log &


# Run the vault-setup.sh in the background
$GRABDISH_HOME/utils/vault-setup.sh &>> $LOG_LOC/vault-setup.log &


# Get Namespace
while ! state_done NAMESPACE; do
  NAMESPACE=`oci os ns get --compartment-id "$(state_get COMPARTMENT_OCID)" --query "data" --raw-output`
  state_set NAMESPACE "$NAMESPACE"
done


# Get User Name
while ! state_done USER_NAME; do
  USER_NAME=`oci iam user get --user-id "$(state_get USER_OCID)" --query "data.name" --raw-output`
  state_set USER_NAME "$USER_NAME"
done


# login to docker
while ! state_done DOCKER_REGISTRY; do
  if ! TOKEN=`oci iam auth-token create  --user-id "$(state_get USER_OCID)" --description 'grabdish docker login'`; then
    echo 'ERROR: Failed to create auth token.  Please delete an old token and I will try again in 10 seconds'
    sleep 10
  else
    echo "$TOKEN" | docker login -u "$(state_get NAMESPACE)/$(state_get USER_NAME)" --password-stdin "$(state_get REGION).ocir.io"
    state_set DOCKER_REGISTRY "$(state_get REGION).ocir.io/$(state_get NAMESPACE)/$(state_get RUN_NAME)"
  fi
done


# Wait for vault
if ! state_done VAULT_SETUP_DONE; then
  echo "`date`: Waiting for vault"
  while ! state_done VAULT_SETUP_DONE; do
    sleep 1
  done
fi


# Collect DB password and create secret
while ! state_done DB_PASSWORD_OCID; do
  echo 'Database passwords must be 12 to 30 characters and contain at least one uppercase letter,'
  echo 'one lowercase letter, and one number. The password cannot contain the double quote (")'
  echo 'character or the word "admin".'
  read -p "Enter the password to be used for the order and inventory databases: " DB_PASSWORD

  #Set password in vault
  BASE64_DB_PASSWORD=`echo -n "$DB_PASSWORD" | base64`

  umask 177 
  cat >temp_params <<!
{
  "compartmentId": "$(state_get COMPARTMENT_OCID)",
  "description": "DB Password",
  "keyId": "$(state_get VAULT_KEY_OCID)",
  "secretContentContent": "$BASE64_DB_PASSWORD",
  "secretContentName": "dbpassword",
  "secretContentStage": "CURRENT",
  "secretName": "dbpassword",
  "vaultId": "$(state_get VAULT_OCID)"
}
!

  # Create a secret
  DB_PWD_OCID=`oci vault secret create-base64 -d --from-json "file://temp_params" --query 'data.id' --raw-output`
  rm temp_params
  umask 177 
  state_set DB_PASSWORD_OCID "$DB_PWD_OCID" 
done


# Collect UI password and create secret
while ! state_done UI_PASSWORD_OCID; do
  read -p "Enter the password to be used for the user interface: " UI_PASSWORD

  #Set password in vault
  BASE64_UI_PASSWORD=`echo -n "$UI_PASSWORD" | base64`

  umask 177 
  cat >temp_params <<!
{
  "compartmentId": "$(state_get COMPARTMENT_OCID)",
  "description": "UI Password",
  "keyId": "$(state_get VAULT_KEY_OCID)",
  "secretContentContent": "$BASE64_UI_PASSWORD",
  "secretContentName": "uipassword",
  "secretContentStage": "CURRENT",
  "secretName": "uipassword",
  "vaultId": "$(state_get VAULT_OCID)"
}
!

  # Create a secret
  UI_PWD_OCID=`oci vault secret create-base64 -d --from-json "file://temp_params" --query 'data.id' --raw-output`
  rm temp_params
  umask 177 
  state_set UI_PASSWORD_OCID "$UI_PWD_OCID" 
done


# Wait for provisioning
if ! state_done PROVISIONING_DONE; then
  echo "`date`: Waiting for terraform provisioning"
  while ! state_done PROVISIONING_DONE; do
    sleep 1
  done
fi


# Get Order DB OCID
while ! state_done ORDER_DB_OCID; do
  ORDER_DB_OCID=`oci db autonomous-database list --compartment-id "$(cat state/COMPARTMENT_OCID)" --query 'join('"' '"',data[?"db-name"=='"'ORDERDB'"'].id)' --raw-output`
  state_set ORDER_DB_OCID "$ORDER_DB_OCID"
done


# Get Inventory DB OCID
while ! state_done INVENTORY_DB_OCID; do
  INVENTORY_DB_OCID=`oci db autonomous-database list --compartment-id "$(cat state/COMPARTMENT_OCID)" --query 'join('"' '"',data[?"db-name"=='"'INVENTORYDB'"'].id)' --raw-output`
  state_set INVENTORY_DB_OCID "$INVENTORY_DB_OCID"
done


# run oke-setup.sh in background
$GRABDISH_HOME/utils/oke-setup.sh &>>$LOG_LOC/oke-setup.log &


# run db-setup.sh in background
$GRABDISH_HOME/utils/db-setup.sh &>>$LOG_LOC/db-setup.log &


# Set admin password in inventory database
while ! state_done INVENTORY_DB_PASSWORD_SET; do
  # get password from vault secret
  DB_PASSWORD=`oci secrets secret-bundle get --secret-id "$(state_get DB_PASSWORD_OCID)" --query 'data."secret-bundle-content"' -raw-output | base64 --decode`
  umask 177
  echo '{"adminPassword": "'"$DB_PASSWORD"'"}' > temp_params
  oci db autonomous-database update --autonomous-database-id "$(state_get INVENTORY_DB_OCID)" --from-json "file://$GRABDISH_HOME/DB_PASSWORD"
  rm temp_params
  state_set_done INVENTORY_DB_PASSWORD_SET
done


# Set admin password in order database
while ! state_done ORDER_DB_PASSWORD_SET; do
  # get password from vault secret
  DB_PASSWORD=`oci secrets secret-bundle get --secret-id "$(state_get DB_PASSWORD_OCID)" --query 'data."secret-bundle-content"' -raw-output | base64 --decode`
  umask 177
  echo '{"adminPassword": "'"$DB_PASSWORD"'"}' > temp_params
  oci db autonomous-database update --autonomous-database-id "$(state_get ORDER_DB_OCID)" --from-json "file://temp_params"
  rm temp_params
  state_set_done ORDER_DB_PASSWORD_SET
done

# Wait for backgrounds
wait


# Verify Setup
if ! state_done SETUP_VERIFIED; then
  if state_done BUILD_ALL_DONE && state_done OKE_SETUP_DONE && state_done DB_SETUP_DONE && state_done PROVISIONING_DONE && state_done VAULT_SETUP_DONE; then
    state_set_done SETUP_VERIFIED
  else
    if ! state_done BUILD_ALL_DONE; then
      echo "ERROR: build-all.sh failed"
    fi
    if ! state_done OKE_SETUP_DONE; then
      echo "ERROR: oke-setup.sh failed"
    fi
    if ! state_done DB_SETUP_DONE; then
      echo "ERROR: db-setup.sh failed"
    fi
    if ! state_done PROVISIONING_DONE; then
      echo "ERROR: terraform.sh failed"
    fi
    if ! state_done VAULT_SETUP_DONE; then
      echo "ERROR: vault-setup.sh failed"
    fi
  fi
fi