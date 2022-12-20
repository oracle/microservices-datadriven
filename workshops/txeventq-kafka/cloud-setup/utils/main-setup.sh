#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

function db_password_valid() {
  local password=$1
  (( ${#password} >= 12 ))         || echo 'Error: Too short'
  (( ${#password} <= 30 ))         || echo 'Error: Too long'
  [[ $password == *[[:digit:]]* ]] || echo 'Error: Does not contain a digit'
  [[ $password == *[[:lower:]]* ]] || echo 'Error: Does not contain a lower case letter'
  [[ $password == *[[:upper:]]* ]] || echo 'Error: Does not contain an upper case letter'
  [[ $password != *'"'* ]]         || echo 'Error: Cannot contain the double quote (") character'
  [[ $(echo "$password" | tr '[:lower:]' '[:upper:]') != *'ADMIN'* ]]  || echo 'Error: Cannot contain the word "admin".'
}


# Check home is set
if test -z "$LAB_HOME"; then
  echo "ERROR: This script requires LAB_HOME to be set"
  exit
fi


# Exit if we are already done
if state_done SETUP_VERIFIED; then
  echo "SETUP_VERIFIED completed"
  exit
fi


## Identify Run Type
#while ! state_done RUN_TYPE; do
#  if [[ "$HOME" =~ /home/ll[0-9]{1,5}_us ]]; then
#    # Green Button (hosted by Live Labs)
#    state_set RUN_TYPE "3"
#    state_set RESERVATION_ID $(grep -oP '(?<=/home/ll).*?(?=_us)' <<<"$HOME")
#    state_set USER_OCID 'NA'
#    state_set USER_NAME "LL$(state_get RESERVATION_ID)-USER"
#    state_set_done PROVISIONING
#    state_set RUN_NAME "lab$(state_get RESERVATION_ID)"
#    state_set LAB_DB_NAME "LAB$(state_get RESERVATION_ID)"
#    state_set_done ATP_LIMIT_CHECK
#  else
#    state_set RUN_TYPE "1"
#  fi
#done


# Get the User OCID
while ! state_done USER_OCID; do
  if test -z "$TEST_USER_OCID"; then
    read -p "Please enter your OCI user's OCID: " USER_OCID
  else
    USER_OCID=$TEST_USER_OCID
  fi
  # Validate
  if test $(oci iam user get --user-id "$USER_OCID" --query 'data."lifecycle-state"' --raw-output 2>"${LAB_LOG}"/user_ocid_err) == 'ACTIVE'; then
    state_set USER_OCID "$USER_OCID"
  else
    echo "That user OCID could not be validated"
    cat "$LAB_LOG"/user_ocid_err
  fi
done


# Get User Name
while ! state_done USER_NAME; do
  USER_NAME=$(oci iam user get --user-id "$(state_get USER_OCID)" --query "data.name" --raw-output)
  state_set USER_NAME "$USER_NAME"
done


## Get Run Name from directory name
#while ! state_done RUN_NAME; do
#  cd "$LAB_HOME"
#  cd ../../..
#  # Validate that a folder was creared
#  if test "$PWD" == ~; then
#    echo "ERROR: The workshop is not installed in a separate folder."
#    exit
#  fi
#  DN=$(basename "$PWD")
#  # Validate run name.  Must be between 1 and 13 characters, only letters or numbers, starting with letter
#  if [[ "$DN" =~ ^[a-zA-Z][a-zA-Z0-9]{0,12}$ ]]; then
#    # shellcheck disable=SC2046
#    state_set RUN_NAME $(echo "$DN" | awk '{print tolower($0)}')
#    state_set LAB_DB_NAME "$(state_get RUN_NAME)"
#  else
#    echo "Error: Invalid directory name $RN.  The directory name must be between 1 and 13 characters,"
#    echo "containing only letters or numbers, starting with a letter.  Please restart the workshop with a valid directory name."
#    exit
#  fi
#  cd "$LAB_HOME"
#done


# Get the tenancy OCID
while ! state_done TENANCY_OCID; do
  state_set TENANCY_OCID "$OCI_TENANCY" # Set in cloud shell env.sh
done


# Double check and then set the region
while ! state_done REGION; do
  if test "$(state_get RUN_TYPE)" -eq 1; then
    HOME_REGION=$(oci iam region-subscription list --query 'data[?"is-home-region"]."region-name" | join('\'' '\'', @)' --raw-output)
    state_set HOME_REGION "$HOME_REGION"
  fi
  state_set REGION "$OCI_REGION" # Set in cloud shell env.sh
done


# Create the compartment
while ! state_done COMPARTMENT_OCID; do
  if test "$(state_get RUN_TYPE)" -ne 3; then
    echo "Resources will be created in a new compartment named $(state_get RUN_NAME)"
    export OCI_CLI_PROFILE=$(state_get HOME_REGION)
    LAB_DESCRIPTION="Simplify Event-driven Apps with TxEventQ in Oracle Database (with Kafka interoperability)"
    COMPARTMENT_OCID=$(oci iam compartment create --compartment-id "$(state_get TENANCY_OCID)" --name "$(state_get RUN_NAME)" --description "$LAB_DESCRIPTION" --query 'data.id' --raw-output)
    export OCI_CLI_PROFILE=$(state_get REGION)
  else
    read -p "Please enter your OCI compartment's OCID: " COMPARTMENT_OCID
  fi
  while ! test $(oci iam compartment get --compartment-id "$COMPARTMENT_OCID" --query 'data."lifecycle-state"' --raw-output 2>/dev/null)"" == 'ACTIVE'; do
    echo "Waiting for the compartment to become ACTIVE"
    sleep 2
  done
  state_set COMPARTMENT_OCID "$COMPARTMENT_OCID"
done

# Check ATP resource availability
while ! state_done ATP_LIMIT_CHECK; do
  CHECK=1
  # Check if user wants to use Always Free Autonomous Database Instance.
  read -r -p "Do you want to use Always Free Autonomous Database Instance? (y/N) " ADB_FREE
  if [[ "$ADB_FREE" =~ ^([yY][eE][sS]|[yY])$ ]]
  then
        # ATP Free Tier OCPU availability
        if test $(oci limits resource-availability get --compartment-id="$OCI_TENANCY" --service-name "database" --limit-name "adb-free-count" --query 'to_string(min([data."fractional-availability",`1.0`]))' --raw-output) != '1.0'; then
          echo 'The "Always Free Autonomous Database OCPU Count" resource availability is insufficient to run this workshop.'
          echo '1 OCPUs are required.  Terminate some existing ADB FREE databases and try again.'
          CHECK=0
        else
          state_set ADB_FREE true
        fi
  else
        # ATP OCPU availability
        if test $(oci limits resource-availability get --compartment-id="$OCI_TENANCY" --service-name "database" --limit-name "atp-ocpu-count" --query 'to_string(min([data."fractional-availability",`1.0`]))' --raw-output) != '1.0'; then
          echo 'The "Autonomous Transaction Processing OCPU Count" resource availability is insufficient to run this workshop.'
          echo '1 OCPUs are required.  Terminate some existing ATP databases and try again.'
          CHECK=0
        fi

        # ATP storage availability
        if test $(oci limits resource-availability get --compartment-id="$OCI_TENANCY" --service-name "database" --limit-name "atp-total-storage-tb" --query 'to_string(min([data."fractional-availability",`1.0`]))' --raw-output) != '1.0'; then
          echo 'The "Autonomous Transaction Processing Total Storage (TB)" resource availability is insufficient to run this workshop.'
          echo '1 TB are required.  Terminate some existing ATP databases and try again.'
          CHECK=0
        fi
        state_set ADB_FREE false
  fi

  if test $CHECK -eq 1; then
    state_set_done ATP_LIMIT_CHECK
  else
    read -p "Hit [RETURN] when you are ready to retry? " DUMMY
  fi
done


## Run the terraform.sh in the background
if ! state_get PROVISIONING; then
  if ps -ef | grep "$LAB_HOME/cloud-setup/utils/terraform.sh" | grep -v grep; then
    echo "$LAB_HOME/cloud-setup/utils/terraform.sh is already running"
  else
    echo "Executing terraform.sh in the background"
    nohup "$LAB_HOME"/cloud-setup/utils/terraform.sh &>> "$LAB_LOG"/terraform.log &
  fi
fi

# Get Namespace
while ! state_done NAMESPACE; do
  NAMESPACE=$(oci os ns get --compartment-id "$(state_get COMPARTMENT_OCID)" --query "data" --raw-output)
  state_set NAMESPACE "$NAMESPACE"
done

# Install GraalVM
GRAALVM_VERSION="22.2.0"
if ! state_get GRAALVM_INSTALLED; then
  if ps -ef | grep "$LAB_HOME/cloud-setup/java/graalvm-install.sh" | grep -v grep; then
    echo "$LAB_HOME/cloud-setup/java/graalvm-install.sh is already running"
  else
    echo "Executing java/graalvm-install.sh in the background"
    nohup "$LAB_HOME"/cloud-setup/java/graalvm-install.sh ${GRAALVM_VERSION} &>>"$LAB_LOG"/graalvm_install.log &
  fi
fi

# run oracle_db_setup.sh in background
if ! state_get DB_SETUP; then
  if ps -ef | grep "$LAB_HOME/cloud-setup/database/oracle_db_setup.sh" | grep -v grep; then
    echo "$LAB_HOME/cloud-setup/database/oracle_db_setup.sh is already running"
  else
    echo "Executing oracle_db_setup.sh in the background"
    nohup "$LAB_HOME"/cloud-setup/database/oracle_db_setup.sh &>>"$LAB_LOG"/db-setup.log &
  fi
fi


# Collect DB password
if ! state_done DB_PASSWORD; then
  echo
  echo 'Enter the password to be used for the lab database.'
  echo 'Database passwords must be 12 to 30 characters and contain at least one uppercase letter,'
  echo 'one lowercase letter, and one number. The password cannot contain the double quote (")'
  echo 'character or the word "admin".'
  echo

  while true; do
     #read -s -r -p "Enter the password to be used for the lab database: " PW
     read -s -r -p "Please enter a password: " PW
     echo "***********"
     read -s -r -p "Retype a password: " second
     echo "***********"

     if [ "$PW" != "$second" ]; then
       echo "You have entered different passwords. Please, try again.."
       echo
       continue
     fi

    msg=$(db_password_valid "$PW");
    if [[ $msg != *'Error'* ]] ; then
      echo
      break
    else
      echo "$msg"
      echo "You have entered invalid passwords. Please, try again.."
      echo
    fi
  done
  BASE64_DB_PASSWORD=$(echo -n "$PW" | base64)
fi

# Wait for provisioning
if ! state_done PROVISIONING; then
  echo "$(date): Waiting for terraform provisioning"
  while ! state_done PROVISIONING; do
    LOGLINE=$(tail -1 "$LAB_LOG"/terraform.log)
    echo -ne r"\033[2K\r${LOGLINE:0:120}"
    sleep 2
  done
  echo
fi

# Get Lab DB OCID
while ! state_done LAB_DB_OCID; do
  ADB_QUERY='join('"' '"',data[?"display-name"=='"'$(state_get LAB_DB_NAME)_ATP'"'].id)'
  LAB_DB_OCID=$(oci db autonomous-database list --compartment-id "$(state_get COMPARTMENT_OCID)" --query "$ADB_QUERY" --raw-output)
  if [[ "$LAB_DB_OCID" =~ ocid1.autonomousdatabase* ]]; then
    state_set LAB_DB_OCID "$LAB_DB_OCID"
  else
    echo "ERROR: Incorrect Lab DB OCID: $LAB_DB_OCID"
    exit
  fi
done

# Set admin password in lab database
while ! state_done LAB_DB_PASSWORD_SET; do
  DB_PASSWORD=$(echo "$BASE64_DB_PASSWORD" | base64 --decode)
  umask 177
  echo '{"adminPassword": "'"$DB_PASSWORD"'"}' > temp_params
  umask 22
  oci db autonomous-database update --autonomous-database-id "$(state_get LAB_DB_OCID)" --from-json "file://temp_params" >/dev/null
  rm temp_params
  state_set BASE64_DB_PASSWORD "$BASE64_DB_PASSWORD"
  state_set_done DB_PASSWORD
  state_set_done LAB_DB_PASSWORD_SET
done

# run kafka-setup.sh in background
if ! state_get KAFKA_SETUP; then
  if ps -ef | grep "$LAB_HOME/cloud-setup/confluent-kafka/kafka-setup.sh" | grep -v grep; then
    echo "$LAB_HOME/cloud-setup/confluent-kafka/kafka-setup.sh is already running"
  else
    echo "Executing kafka-setup.sh in the background"
    nohup "$LAB_HOME"/cloud-setup/confluent-kafka/kafka-setup.sh &>>"$LAB_LOG"/kafka-setup.log &
  fi
fi

ps -ef | grep "$LAB_HOME/cloud-setup/utils" | grep -v grep

ps -ef | grep "$LAB_HOME/cloud-setup/confluent-kafka" | grep -v grep


# Verify Setup
# bgs="BUILD_ALL JAVA_BUILDS NON_JAVA_BUILDS OKE_SETUP DB_SETUP KAFKA_SETUP PROVISIONING"
bgs="DB_SETUP PROVISIONING CONTAINER_ENG_SETUP KAFKA_SETUP"
while ! state_done SETUP_VERIFIED; do
  NOT_DONE=0
  bg_not_done=
  for bg in $bgs; do
    if state_done $bg; then
      echo "$bg has completed"
    else
      # echo "$bg is running"
      NOT_DONE=$((NOT_DONE+1))
      bg_not_done="$bg_not_done $bg"
    fi
  done
  if test "$NOT_DONE" -gt 0; then
    # echo "Log files are located in $LAB_LOG"
    bgs=$bg_not_done
    echo -ne r"\033[2K\r$bgs still executing... \n"
    sleep 10
  else
    state_set_done SETUP_VERIFIED
  fi
done

## Export state file for local development
#cd "$LAB_HOME"
#source "$LAB_HOME"/cloud-setup/env.sh
#
