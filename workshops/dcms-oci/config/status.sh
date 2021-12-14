#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -eu

export DCMS_THREAD_STATE=$DCMS_STATE/threads

THREADS="build-prep db k8s grabdish"
for t in $THREADS; do
  THREAD_STATE=$DCMS_THREAD_STATE/$t
  STATUS=$(provisioning-get-status $THREAD_STATE)
  printf "Thread %-10s: Status: %s\n" "$t" "$STATUS"
  if [[ "$STATUS" =~ byo|new|applied|destroyed ]]; then
    # Skip this log
    continue
  fi
  printf "  Most recent log entry in %s:\n" "$DCMS_LOG_DIR/$t-thread.log"
  LAST_LOG=`tail -1 $DCMS_LOG_DIR/$t-thread.log`
  printf "  %-100s\n\n" "$LAST_LOG"
done