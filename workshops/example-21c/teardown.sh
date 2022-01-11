#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if (return 0 2>/dev/null); then
  echo "ERROR: Usage './teardown.env'"
  exit 1
fi

# Environment must be setup before running this script
if test -z "$EG21C_STATE"; then
  echo "ERROR: Workshop environment not setup"
  exit 1
fi

# Get the provisioning status
if ! EG21C_STATUS=$(provisioning-get-status $EG21C_STATE); then
  echo "ERROR: Unable to get workshop provisioning status"
  exit 1
fi

case "$EG21C_STATUS" in

  new | destroyed | byo | destroying)
    # Nothing to do
    ;;

  applying)
    echo "ERROR: Destroy cannot be executed because setup is running."
    exit 1
    ;;

  applied | applying-failed | destroying-failed)
    if ! test "$EG21C_STATUS" == 'destroying-failed'; then
      # First time running destroy. Take an archive copy of the state
      BACKUP_DIR=${EG21C_RUN_DIR}_$( date '+%F_%H:%M:%S' )
      mkdir -p $BACKUP_DIR
      echo "Making a backup copy of the workshop state in $BACKUP_DIR"
      cp -r $EG21C_RUN_DIR/* $BACKUP_DIR/
    fi

    # Start or restart destroy
    cd $EG21C_STATE
    echo "Starting teardown."
    provisioning-destroy
    exit 0
    ;;

esac
