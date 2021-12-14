#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -eu

LAB="$1"
LAB_UPPER=`echo $LAB | tr '[:lower:]' '[:upper:]'`

printf "$LAB builds:"
JAVA_BUILDS_VAR="${LAB_UPPER}_JAVA_BUILDS"
NON_JAVA_BUILDS_VAR="${LAB_UPPER}_NON_JAVA_BUILDS"
BUILDS="${!JAVA_BUILDS_VAR} ${!NON_JAVA_BUILDS_VAR}"

RUNNING_BUILDS=""
COMPLETED_BUILDS=""
FAILED_BUILDS=""
TO_BE_RUN_BUILDS=""
for b in $BUILDS; do
  if test -d $DCMS_BACKGROUND_BUILDS/$b; then
    if state_done "BUILD_$b"; then
      COMPLETED_BUILDS="$COMPLETED_BUILDS $b"
    else
      PID_FILE="$DCMS_BACKGROUND_BUILDS/$b/PID"
      if test -f $PID_FILE && ps -fp $(<$PID_FILE) >>/dev/null 2>&1; then
        RUNNING_BUILDS="$RUNNING_BUILDS $b"
      else
        FAILED_BUILDS="$FAILED_BUILDS $b"
      fi
    fi
  else
    TO_BE_RUN_BUILDS="$TO_BE_RUN_BUILDS $b"
  fi
done

if ! test -z "$COMPLETED_BUILDS"; then
  printf " Completed:$COMPLETED_BUILDS "
fi

if ! test -z "$RUNNING_BUILDS"; then
  printf " Running:$RUNNING_BUILDS "
fi

if ! test -z "$TO_BE_RUN_BUILDS"; then
  printf " Waiting to run:$TO_BE_RUN_BUILDS "
fi

if ! test -z "$FAILED_BUILDS"; then
  printf " Failed:$FAILED_BUILDS "
fi

echo

for b in $FAILED_BUILDS; do
  echo "  Build $b log: $DCMS_LOG_DIR/build_$b.log"
done