#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if ! (return 0 2>/dev/null); then
  echo "ERROR: Usage 'source setup.sh'"
  exit
fi

if state_done SETUP; then
  echo "The setup has been completed"
  return 0
fi

SETUP_SCRIPT="$GRABDISH_HOME/utils/main-setup.sh"
if ps -ef | grep "$SETUP_SCRIPT" | grep -v grep; then
  echo "The $SETUP_SCRIPT is already running.  If you want to restart it then kill it and then rerun."
else
  $SETUP_SCRIPT 2>&1 | tee -ai $GRABDISH_LOG/main-setup.log
fi