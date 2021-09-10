#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .

if ! provisioning-helper-pre-apply; then
  return 1
fi

STATE_STORE=$MY_STATE/state
mkdir -p $STATE_STORE
cat >$OUTPUT_FILE <<!
export STATE_STORE=$STATE_STORE
export STATE_LOG=$STATE_LOG
!
cat $MY_CODE/state-functions.env >>$OUTPUT_FILE