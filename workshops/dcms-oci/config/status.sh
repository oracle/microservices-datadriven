#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -eu

export DCMS_THREAD_STATE=$DCMS_STATE/threads

THREADS="db build-prep k8s grabdish"
for t in $THREADS; do
  THREAD_STATE=$DCMS_THREAD_STATE/$t
  STATUS=$(provisioning-get-status $THREAD_STATE)
  echo "Thread $t status $STATUS"
  tail -1 $DCMS_LOG_DIR/$t-thread.log
  echo
done