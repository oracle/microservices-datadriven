#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if ! (return 0 2>/dev/null); then
  echo "ERROR: Usage: 'source state-functions.sh <STATE_LOC>' or, "
  echo "              'source state-functions.sh' if the environment variable STATE_LOC is defined"
  exit
fi

# Validate State Location
if test $# -gt 0; then
  STATE_LOC="$1"
fi

if test -z "$STATE_LOC"; then
  echo "ERROR: State folder was not specified"
fi

if ! test -d $STATE_LOC; then
  echo "ERROR: State folder $STATE_LOC does not exist"
fi

export STATE_LOC=`readlink -m $STATE_LOC`

# Test if the state is done (file exists) 
function state_done() {
  test -f $STATE_LOC/"$1"
}

# Set the state to done
function state_set_done() {
  touch $STATE_LOC/"$1"
  echo "`date`: $1" | tee $LOG_LOC/state
}

# Set the state to done and it's value
function state_set() {
  echo "$2" > $STATE_LOC/"$1"
  echo "`date`: $1: $2" | tee $LOG_LOC/state.log
}

# Reset the state - not done and no value
function state_reset() {
  rm -f $STATE_LOC/"$1"
}

# Get state value
function state_get() {
    if ! state_done "$1"; then
        return 1
    fi
    cat $STATE_LOC/"$1"
}