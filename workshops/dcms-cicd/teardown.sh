#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if (return 0 2>/dev/null); then
  echo "ERROR: Usage './teardown.env'"
  exit 1
fi

# Environment must be setup before running this script
if test -z "$DCMS_CICD_STATE_DIR"; then
  echo "ERROR: Workshop environment not setup"
  exit 1
fi

# Check for Live Labs
if [[ "$HOME" =~ /home/ll[0-9]{1,5}_us ]]; then
  echo "No need to teardown in Live Labs"
  exit 0
fi

# Get the provisioning status
if ! DCMS_STATUS=$(provisioning-get-status $DCMS_CICD_STATE_DIR); then
  echo "ERROR: Unable to get workshop provisioning status"
  exit 1
fi

case "$DCMS_STATUS" in

  new | destroyed | byo | destroying)
    # Nothing to do
    ;;

  applying)
    echo "ERROR: Destroy cannot be executed because setup is running."
    exit 1
    ;;

  applied | applying-failed | destroying-failed)
    if ! test "$DCMS_STATUS" == 'destroying-failed'; then
      # First time running destroy. Take an archive copy of the state
      BACKUP_DIR=${DCMS_CICD_RUN_DIR}_$( date '+%F_%H:%M:%S' )
      mkdir -p $BACKUP_DIR
      echo "Making a backup copy of the workshop state in $BACKUP_DIR"
      cp -r $DCMS_CICD_RUN_DIR/* $BACKUP_DIR/
    fi

    # Start or restart destroy
    cd $DCMS_CICD_STATE_DIR
    echo "Starting teardown.  Call 'status' to get the status of the teardown"
    nohup bash -c "provisioning-destroy" >> $DCMS_CICD_LOG_DIR/teardown.log 2>&1 &
    exit
    ;;

esac
