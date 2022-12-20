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
if test -z "$DCMS_STATE"; then
  echo "ERROR: Workshop environment not setup"
  exit 1
fi

# Setup the state store
if ! state-store-setup "$DCMS_STATE_STORE" "$DCMS_LOG_DIR/state.log"; then
  echo "Error: Provisioning the state store failed"
  exit 1
fi

# Get the setup status
if ! DCMS_STATUS=$(provisioning-get-status $DCMS_STATE); then
  echo "ERROR: Unable to get workshop provisioning status"
  exit 1
fi

case "$DCMS_STATUS" in

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
    cd $DCMS_STATE
    echo "Restarting setup.  Call 'status' to get the status of the setup"
    nohup bash -c "provisioning-apply $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/config" >>$DCMS_LOG_DIR/config.log 2>&1 &
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
echo "source $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/source.env #microservices-datadriven" >>$PROF
echo 'echo "Running workshop $DCMS_WORKSHOP from folder $MSDD_WORKSHOP_CODE #microservices-datadriven"' >>$PROF

# Check that the prerequisite utils are installed
for util in oci terraform ssh sqlplus; do
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
if ! state_done RUN_NAME; then
  state_set RUN_NAME gd`awk 'BEGIN { srand(); print int(1 + rand() * 100000000)}'`
fi

# Hard coded for now
if ! state_done DB_DEPLOYMENT; then
state_set DB_DEPLOYMENT 1DB
fi

if ! state_done DB_TYPE; then
state_set DB_TYPE ATP
fi

if ! state_done QUEUE_TYPE; then
state_set QUEUE_TYPE teq
fi

if ! state_done DB_VERSION; then
state_set DB_VERSION 21c
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
    state_set HOME_REGION 'NA'
  else
    # Run in your own tenancy
    state_set RUN_TYPE "OT"
    state_set DB_NAME "$(state_get RUN_NAME)"
    state_set DB_ALIAS "$(state_get RUN_NAME)_tp"
  fi
done

# Tenancy OCID
while ! state_done TENANCY_OCID; do
  if ! test -z "$OCI_TENANCY"; then
    state_set TENANCY_OCID "$OCI_TENANCY"
  else
    # Get the tenancy OCID
    while true; do
      read -p "Please enter your OCI tenancy OCID: " OCI_TENANCY
      if oci iam tenancy get --tenancy-id "$OCI_TENANCY" 2>&1 >$DCMS_LOG_DIR/tenancy_ocid_err; then
        state_set TENANCY_OCID "$OCI_TENANCY"
      else
        echo "The tenancy OCID $OCI_TENANCY could not be validated.  Please retry."
        cat $DCMS_LOG_DIR/tenancy_ocid_err
      fi
    done
  fi
done

# Check "Always Free Autonomous Transaction Processing Instance Count" limit
while ! state_done ATP_LIMIT_CHECK; do
  CHECK=1
  # ADB Always Free availability
  if test $(oci limits resource-availability get --compartment-id="$(state_get TENANCY_OCID)" --service-name "database" --limit-name "adb-free-count" --query 'to_string(min([data."fractional-availability",`1.0`]))' --raw-output) != '1.0'; then
    echo 'The "Always Free Autonomous Transaction Processing Instance Count" resource availability is insufficent to run this workshop.'
    echo '1 instance is required.  Terminate some existing always free databases and try again.'
    CHECK=0
  fi

  if test $CHECK -eq 1; then
    state_set_done ATP_LIMIT_CHECK
  else
    read -p "Hit [RETURN] when you are ready to retry? " DUMMY
  fi
done

# Home Region
if ! state_done HOME_REGION; then
  state_set HOME_REGION `oci iam region-subscription list --query 'data[?"is-home-region"]."region-name" | join('\'' '\'', @)' --raw-output`
fi

# Request compartment details and create or validate
if ! state_done COMPARTMENT_OCID; then
  echo
  if compartment-dialog "$(state_get RUN_TYPE)" "$(state_get TENANCY_OCID)" "$(state_get HOME_REGION)" "GrabDish Workshop $(state_get RUN_NAME)"; then
    state_set COMPARTMENT_OCID $COMPARTMENT_OCID
  else
    echo "Error: Failed in compartment-dialog"
    exit 1
  fi
fi


# Get the User OCID
while ! state_done USER_OCID; do
  echo
  if test -z "${TEST_USER_OCID-}"; then
    echo "Your user's OCID has a name beginning ocid1.user.oc1.."
    read -p "Please enter your OCI user's OCID: " USER_OCID
  else
    USER_OCID=${TEST_USER_OCID-}
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

# OCI Region
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

if ! state_done ORDS_SCHEMA_NAME; then
  state_set ORDS_SCHEMA_NAME 'ORDS_PUBLIC_USER2'
fi

# Run the setup in the background
cd $DCMS_STATE
echo
echo "Setup runs terraform to provision a network, autonomous database, compute instance and load balancer."
echo "The status of setup and the most recent log entries will be displayed as the setup runs."
echo "The full log file ( $DCMS_LOG_DIR/config.log ) can be viewed in a separate Cloud Console window."
nohup bash -c "provisioning-apply $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/config" >>$DCMS_LOG_DIR/config.log 2>&1 &
