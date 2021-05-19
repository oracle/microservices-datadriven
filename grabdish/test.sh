#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if ! (return 0 2>/dev/null); then
  echo "ERROR: Usage 'source test.sh $USER_OCID'"
  exit
fi

TEST_SCRIPT="$GRABDISH_HOME/utils/main-test.sh"
$TEST_SCRIPT 2>&1 | tee -ai $GRABDISH_LOG/main-test.log