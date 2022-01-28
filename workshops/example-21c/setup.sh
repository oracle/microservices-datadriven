#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

# Make sure this is executed and not sourced
if (return 0 2>/dev/null) ; then
  echo "ERROR: Usage './setup.sh'"
  exit 1
fi

# Environment must be setup before running this script
if test -z "$EG21C_STATE"; then
  echo "ERROR: Workshop environment not setup"
  exit 1
fi

# Get the setup status
if ! EG21C_STATUS=$(provisioning-get-status $EG21C_STATE); then
  echo "ERROR: Unable to get workshop provisioning status"
  exit 1
fi

# Setup the vault
if ! folder-vault-setup $EG21C_VAULT; then
  echo "Error: Failed to provision the folder vault"
  exit 1
fi

case "$EG21C_STATUS" in

  applied | byo)
    # Nothing to do
    exit 0
    ;;

  applying)
    # Nothing to do
    exit 0
    ;;

  destroying | destroying-failed | destroyed)
    # Cannot setup during destroy phase
    echo "ERROR: Destroy is running and so cannot run setup"
    exit 1
    ;;

  applying-failed)
    # Restart the setup
    cd $EG21C_STATE
    echo "Restarting setup"
    provisioning-apply $MSDD_WORKSHOP_CODE/$EG21C_WORKSHOP/config
    exit 0
    ;;

  new)
    # New setup
    ;;

esac

##### New Setup

# Register our source.env in .bash_profile
PROF=~/.bashrc
if test -f "$PROF"; then
  sed -i.bak '/microservices-datadriven/d' $PROF
fi
echo "source $MSDD_WORKSHOP_CODE/$EG21C_WORKSHOP/source.env #microservices-datadriven" >>$PROF
echo 'echo "Running workshop $EG21C_WORKSHOP from folder $MSDD_WORKSHOP_CODE #microservices-datadriven"' >>$PROF

# Check that the prerequisite utils are installed
for util in oci terraform; do
  exec=`which $util`
  if test -z "$exec"; then
    echo "ERROR: $util is not installed"
    exit 1
  fi
done

# Check that the OCI CLI is configured
if ! test -f "$OCI_CLI_CONFIG_FILE" && ! test -f ~/.oci/config; then
  echo "ERROR: The OCI CLI is not configured"
  exit 1
fi

# Run Name (random)
RUN_NAME=gd`awk 'BEGIN { srand(); print int(1 + rand() * 100000000)}'`

# Tenancy OCID
if ! test -z "$OCI_TENANCY"; then
  TENANCY_OCID="$OCI_TENANCY"
else
  # Get the tenancy OCID
  while true; do
    read -p "Please enter your OCI tenancy OCID: " OCI_TENANCY
    if oci iam tenancy get --tenancy-id "$OCI_TENANCY" 2>&1 >$EG21C_LOG_DIR/tenancy_ocid_err; then
      TENANCY_OCID="$OCI_TENANCY"
    else
      echo "The tenancy OCID $OCI_TENANCY could not be validated.  Please retry."
      cat $EG21C_LOG_DIR/tenancy_ocid_err
    fi
  done
fi

# Home Region
HOME_REGION=`oci iam region-subscription list --query 'data[?"is-home-region"]."region-name" | join('\'' '\'', @)' --raw-output`

# Request compartment details and create or validate
if ! compartment-dialog 'OT' "$TENANCY_OCID" "$HOME_REGION" "GrabDish Workshop $RUN_NAME"; then
  echo "Error: Failed in compartment-dialog"
  exit 1
fi

# OCI Region
if test -z "$OCI_REGION"; then
  if test 1 -eq `oci iam region-subscription list --query 'length(data[])' --raw-output`; then
    # Only one subcribed region so must be home region
    OCI_REGION="$HOME_REGION"
  else
    read -p "Please enter the name of the region that you are connected to: " OCI_REGION
  fi
fi

# Collect DB password
if ! is_secret_set DB_PASSWORD; then
  echo
  echo 'Database passwords must be 12 to 30 characters and contain at least one uppercase letter,'
  echo 'one lowercase letter, and one number. The password cannot contain the double quote (")'
  echo 'character or the word "admin".'
  echo

  while true; do
    if test -z "${TEST_DB_PASSWORD-}"; then
      read -s -r -p "Enter the password to be used for the order and inventory databases: " PW
    else
      PW="${TEST_DB_PASSWORD-}"
    fi
    if [[ ${#PW} -ge 12 && ${#PW} -le 30 && "$PW" =~ [A-Z] && "$PW" =~ [a-z] && "$PW" =~ [0-9] && "$PW" != *admin* && "$PW" != *'"'* ]]; then
      echo
      break
    else
      echo "Invalid Password, please retry"
    fi
  done
  set_secret DB_PASSWORD_SECRET $PW
fi

# Run the setup in the background
cd $EG21C_STATE
cat >$EG21C_STATE/input.env <<!
TENANCY_OCID='$TENANCY_OCID'
COMPARTMENT_OCID='$COMPARTMENT_OCID'
OCI_REGION='$OCI_REGION'
RUN_NAME='$RUN_NAME'
!
echo "Setup running"
provisioning-apply $MSDD_WORKSHOP_CODE/$EG21C_WORKSHOP/config
source $EG21C_STATE/output.env