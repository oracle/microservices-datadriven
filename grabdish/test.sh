#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if ! (return 0 2>/dev/null); then
  echo "ERROR: Usage 'source test.sh'"
  exit
fi

echo Deleting any previous $GRABDISH_LOG/main-test.log
rm -f $GRABDISH_LOG/main-test.log
rm -f $GRABDISH_LOG/testlog-*

$GRABDISH_HOME/utils/main-test.sh 2>&1 | tee -ai $GRABDISH_LOG/main-test.log

$GRABDISH_HOME/utils/test-summary.sh
