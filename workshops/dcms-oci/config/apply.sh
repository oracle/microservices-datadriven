#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
  exit 1
fi


# Make sure folders are created
mkdir -p $DCMS_LOG_DIR $DCMS_INFRA_STATE $DCMS_APP_STATE $DCMS_THREAD_STATE 


# Create the state store
STATE_STORE=$DCMS_INFRA_STATE/state_store
if ! test -f $STATE_STORE/output.env; then
  mkdir -p $STATE_STORE
  cd $STATE_STORE
  echo "STATE_LOG='$DCMS_LOG_DIR/state.log'" > input.env
  provisioning-apply $MSDD_INFRA_CODE/state_store
fi
source $STATE_STORE/output.env


# Set tenancy OCID (input parameter)
if ! state_done TENANCY_OCID; then
  state_set TENANCY_OCID "$TENANCY_OCID"
fi


# Set Compartment OCID (input parameter)
if ! state_done COMPARTMENT_OCID; then
  state_set COMPARTMENT_OCID "$COMPARTMENT_OCID"
fi


# Generate Random (hopefully unique) Run Name



if ! state_done RUN_NAME; then
  state_set RUN_NAME gd`awk 'BEGIN { srand(); print int(1 + rand() * 100000000)}'`
fi


# Create the vault
VAULT=$DCMS_INFRA_STATE/vault
if ! test -f $VAULT/output.env; then
  mkdir -p $VAULT
  cd $VAULT
  provisioning-apply $MSDD_INFRA_CODE/vault/folder
fi
source $VAULT/output.env


# Start the background threads
THREADS="db build-prep k8s grabdish"
for t in $THREADS; do
  THREAD_STATE=$DCMS_THREAD_STATE/$t
  mkdir -p $THREAD_STATE
  cd $THREAD_STATE
  THREAD_CODE="$MY_CODE/threads/$t"
  nohup bash -c "provisioning-apply $THREAD_CODE" >>$DCMS_LOG_DIR/$t-thread.log 2>&1 &
done


# Start background builds
mkdir -p "$MY_STATE/background-builds"
nohup $MY_CODE/background-builds.sh "$MY_STATE/background-builds" >>$DCMS_LOG_DIR/background-builds.log 2>&1 &


# Hard coded for now
if ! state_done DB_DEPLOYMENT; then
state_set DB_DEPLOYMENT 2DB
fi

if ! state_done DB_TYPE; then
state_set DB_TYPE ATP
fi

if ! state_done QUEUE_TYPE; then
state_set QUEUE_TYPE classicq
fi


# Identify Run Type
while ! state_done RUN_TYPE; do
  if [[ "$HOME" =~ /home/ll[0-9]{1,5}_us ]]; then
    state_set RUN_TYPE "LL"
    state_set RESERVATION_ID `grep -oP '(?<=/home/ll).*?(?=_us)' <<<"$HOME"`
    state_set USER_OCID 'NA'
    state_set USER_NAME "LL$(state_get RESERVATION_ID)-USER"
    state_set DB1_NAME "ORDER$(state_get RESERVATION_ID)"
    state_set DB2_NAME "INVENTORY$(state_get RESERVATION_ID)"
    state_set_done OKE_LIMIT_CHECK
    state_set_done ATP_LIMIT_CHECK
  else
    # Run in your own tenancy
    state_set RUN_TYPE "OT"
    state_set DB1_NAME "$(state_get RUN_NAME)1"
    state_set DB2_NAME "$(state_get RUN_NAME)2"
  fi
done


# Get the User OCID
while ! state_done USER_OCID; do
  if test -z "$TEST_USER_OCID"; then
    read -p "Please enter your OCI user's OCID: " USER_OCID
  else
    USER_OCID=$TEST_USER_OCID
  fi
  # Validate
  if test ""`oci iam user get --user-id "$USER_OCID" --query 'data."lifecycle-state"' --raw-output 2>$DCMS_LOG_DIR/user_ocid_err` == 'ACTIVE'; then
    state_set USER_OCID "$USER_OCID"
  else
    echo "That user OCID could not be validated"
    cat $DCMS_LOG_DIR/user_ocid_err
  fi
done


# Get User Name
while ! state_done USER_NAME; do
  USER_NAME=`oci iam user get --user-id "$(state_get USER_OCID)" --query "data.name" --raw-output`
  state_set USER_NAME "$USER_NAME"
done


# Double check and then set the home region and region
while ! state_done HOME_REGION; do
  HOME_REGION=`oci iam region-subscription list --query 'data[?"is-home-region"]."region-name" | join('\'' '\'', @)' --raw-output`
  state_set HOME_REGION "$HOME_REGION"
done

while ! state_done OCI_REGION; do
  if test -z "$OCI_REGION"; then
    if test 1 -eq `oci iam region-subscription list --query 'length(data[])' --raw-output`; then
      # Only one subcribed region so must be home region
      OCI_REGION="$(state_get HOME_REGION)"
    else
      read -p "Please enter the name of the region that you are connected to: " OCI_REGION
    fi
  fi
  state_set OCI_REGION "$OCI_REGION"
done


# Check OKE Limits
if ! state_done OKE_LIMIT_CHECK; then
  # Cluster Service Limit
  OKE_LIMIT=`oci limits value list --compartment-id "$(state_get TENANCY_OCID)" --service-name "container-engine" --query 'sum(data[?"name"=='"'cluster-count'"'].value)'`
  if test "$OKE_LIMIT" -lt 1; then
    echo 'The service limit for the "Container Engine" "Cluster Count" is insufficent to run this workshop.  At least 1 is required.'
    exit
  elif test "$OKE_LIMIT" -eq 1; then
    echo 'You are limited to only one OKE cluster in this tenancy.  This workshop will create one additional OKE cluster and so any other OKE clusters must be terminated.'
    if test -z "$TEST_USER_OCID"; then
      read -p "Please confirm that no other un-terminated OKE clusters exist in this tenancy and then hit [RETURN]? " DUMMY
    fi
  fi
  state_set_done OKE_LIMIT_CHECK
fi


# Check ATP resource availability
while ! state_done ATP_LIMIT_CHECK; do
  CHECK=1
  # ATP OCPU availability
  if test $(oci limits resource-availability get --compartment-id="$(state_get TENANCY_OCID)" --service-name "database" --limit-name "atp-ocpu-count" --query 'to_string(min([data."fractional-availability",`4.0`]))' --raw-output) != '4.0'; then
    echo 'The "Autonomous Transaction Processing OCPU Count" resource availability is insufficent to run this workshop.'
    echo '4 OCPUs are required.  Terminate some existing ATP databases and try again.'
    CHECK=0
  fi

  # ATP storage availability
  if test $(oci limits resource-availability get --compartment-id="$(state_get TENANCY_OCID)" --service-name "database" --limit-name "atp-total-storage-tb" --query 'to_string(min([data."fractional-availability",`2.0`]))' --raw-output) != '2.0'; then
    echo 'The "Autonomous Transaction Processing Total Storage (TB)" resource availability is insufficent to run this workshop.'
    echo '2 TB are required.  Terminate some existing ATP databases and try again.'
    CHECK=0
  fi

  if test $CHECK -eq 1; then
    state_set_done ATP_LIMIT_CHECK
  else
    read -p "Hit [RETURN] when you are ready to retry? " DUMMY
  fi
done


# Get Namespace
while ! state_done NAMESPACE; do
  NAMESPACE=`oci os ns get --compartment-id "$(state_get COMPARTMENT_OCID)" --query "data" --raw-output`
  state_set NAMESPACE "$NAMESPACE"
done


# Get the docker auth token
while ! is_secret_set DOCKER_AUTH_TOKEN; do
  if test $(state_get RUN_TYPE) != "LL"; then
    # export OCI_CLI_PROFILE=$(state_get HOME_REGION)
    if ! TOKEN=`oci iam auth-token create --region "$(state_get HOME_REGION)" --user-id "$(state_get USER_OCID)" --description 'grabdish docker login' --query 'data.token' --raw-output 2>$DCMS_LOG_DIR/docker_auth_token`; then
      if grep UserCapacityExceeded $DCMS_LOG_DIR/docker_auth_token >/dev/null; then
        # The key already exists
        echo 'ERROR: Failed to create auth token.  Please delete an old token from the OCI Console (Profile -> User Settings -> Auth Tokens).'
        read -p "Hit return when you are ready to retry?"
        continue
      else
        echo "ERROR: Creating auth token has failed:"
        cat $DCMS_LOG_DIR/docker_auth_token
        exit
      fi
    fi
  else
    read -s -r -p "Please generate an Auth Token and enter the value: " TOKEN
    echo
    echo "Auth Token entry accepted.  Attempting docker login."
  fi
  set_secret DOCKER_AUTH_TOKEN "$TOKEN"
done


# login to docker
while ! state_done DOCKER_REGISTRY; do
  RETRIES=0
  while test $RETRIES -le 30; do
    if echo "$(get_secret DOCKER_AUTH_TOKEN)" | docker login -u "$(state_get NAMESPACE)/$(state_get USER_NAME)" --password-stdin "$(state_get OCI_REGION).ocir.io" &>/dev/null; then
      echo "Docker login completed"
      state_set DOCKER_REGISTRY "$(state_get OCI_REGION).ocir.io/$(state_get NAMESPACE)/$(state_get RUN_NAME)"
      break
    else
      # echo "Docker login failed.  Retrying"
      RETRIES=$((RETRIES+1))
      sleep 5
    fi
  done
done


# Collect DB password
if ! is_secret_set DB_PASSWORD; then
  echo
  echo 'Database passwords must be 12 to 30 characters and contain at least one uppercase letter,'
  echo 'one lowercase letter, and one number. The password cannot contain the double quote (")'
  echo 'character or the word "admin".'
  echo

  while true; do
    if test -z "$TEST_DB_PASSWORD"; then
      read -s -r -p "Enter the password to be used for the order and inventory databases: " PW
    else
      PW="$TEST_DB_PASSWORD"
    fi
    if [[ ${#PW} -ge 12 && ${#PW} -le 30 && "$PW" =~ [A-Z] && "$PW" =~ [a-z] && "$PW" =~ [0-9] && "$PW" != *admin* && "$PW" != *'"'* ]]; then
      echo
      break
    else
      echo "Invalid Password, please retry"
    fi
  done
  set_secret DB_PASSWORD $PW
  state_set DB_PASSWORD_SECRET "DB_PASSWORD"
fi


# Collect UI password and create secret
if ! is_secret_set UI_PASSWORD; then
  echo
  echo 'UI passwords must be 8 to 30 characters'
  echo

  while true; do
    if test -z "$TEST_UI_PASSWORD"; then
      read -s -r -p "Enter the password to be used for accessing the UI: " PW
    else
      PW="$TEST_UI_PASSWORD"
    fi
    if [[ ${#PW} -ge 8 && ${#PW} -le 30 ]]; then
      echo
      break
    else
      echo "Invalid Password, please retry"
    fi
  done
  set_secret UI_PASSWORD $PW
  state_set UI_PASSWORD_SECRET "UI_PASSWORD"
fi


# Explain what is running and give status as the setup proceeds
if test $(state_get RUN_TYPE) == "LL"; then
  echo "Thank you for entering your information and preferences.  The setup is now running with three background threads:"
  echo "DB_THREAD:       Sets the password of the order and inventory databases - approx 1 minutes"
else
  echo "Thank you for entering your information and preferences.  The setup is now running with four background threads:"
  echo "DB_THREAD:       Provisions the order and inventory databases, and sets their passwords - approx 3 minutes"
  echo "K8S_THREAD:      Provisions the Oracle Kubernetes Engine (OKE) - approx 15 minutes"
fi
echo "BASE_BUILDS:     Builds the microservices for Lab 2 to save you time later - approx 5 minutes"
echo "GRABDISH_THREAD: Configures the grabdish application once the database and OKE are provisioned - approx 1 minutes"
echo


# Wait for the threads and base builds to complete
DEPENDENCIES=' DB_THREAD K8S_THREAD BASE_BUILDS GRABDISH_THREAD'
while ! test -z "$DEPENDENCIES"; do
  WAITING_FOR=""
  for d in $DEPENDENCIES; do
    if ! state_done $d; then
      WAITING_FOR="$WAITING_FOR $d"
    fi
  done
  DEPENDENCIES="$WAITING_FOR"
  echo -ne r"\033[2K\rWaiting for:$DEPENDENCIES to complete"
  sleep 5
done


# Write the output
cat >$OUTPUT_FILE <<!
export DOCKER_REGISTRY='$(state_get DOCKER_REGISTRY)'
export JAVA_HOME=$(state_get JAVA_HOME)
export PATH=$(state_get JAVA_HOME)/bin:$PATH
export ORDER_DB_NAME='$(state_get DB1_NAME)'
export ORDER_DB_TNS_ADMIN='$(state_get DB1_TNS_ADMIN)'
export ORDER_DB_ALIAS='$(state_get DB1_ALIAS)'
export INVENTORY_DB_NAME='$(state_get DB2_NAME)'
export INVENTORY_DB_TNS_ADMIN='$(state_get DB2_TNS_ADMIN)'
export INVENTORY_DB_ALIAS='$(state_get DB2_ALIAS)'
export OCI_REGION='$(state_get OCI_REGION)'
export VAULT_SECRET_OCID=''
!

state_set_done SETUP_VERIFIED # Legacy
echo -ne r"\033[2K\rSetup completed"
echo