#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if ! (return 0 2>/dev/null); then
  echo "ERROR: Usage 'source perf.sh'"
  exit
fi

echo "Deleting any previous $GRABDISH_LOG/main-perf.log"
rm -f $GRABDISH_LOG/main-perf.log
rm -f $GRABDISH_LOG/perflog-*

$GRABDISH_HOME/utils/main-perf.sh 2>&1 | tee -ai $GRABDISH_LOG/main-perf.log

$GRABDISH_HOME/utils/perf-summary.sh
