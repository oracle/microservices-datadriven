#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -eu

BUILD="$1"

MY_STATE=$PWD

if state_done BUILD_$BUILD; then
  exit
fi

# Prevent parallel execution
PID_FILE="$MY_STATE/PID"
if test -f $PID_FILE && ps -fp $(<$PID_FILE); then
    echo "The build of $BUILD is already running."
    echo "If you want to run an operation on it, kill process $(cat $PID_FILE), delete the file $PID_FILE, and then retry"
    exit
fi
trap "rm -f -- '$PID_FILE'" EXIT
echo $$ > "$PID_FILE"

echo "Build of $BUILD starting"
if ! test -d $GRABDISH_HOME/$BUILD; then
  if ! test -d $GRABDISH_HOME/*/$BUILD; then
    echo "ERROR: No code for folder for build $BUILD"
  else
    cd $GRABDISH_HOME/*/$BUILD
  fi
else
  cd $GRABDISH_HOME/$BUILD
fi

echo "Build of $BUILD starting in $PWD"
time ./build.sh
echo "Build of $BUILD completed"
state_set_done BUILD_$BUILD