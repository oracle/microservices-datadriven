#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
function source_check()
{
    if [[ ${FUNCNAME[-1]} != "source" ]]
    then
        printf "Failure.  Usage: source %s <STATE_LOC> or, source %s if the environment variable STATE_LOC is defined\n" "$0"
        exit 1
    fi
}
source_check

# Validate State Location
if test $# -gt 0; then
  STATE_LOC="$1"
fi

if test -z "$STATE_LOC"; then
  echo "ERROR: State folder was not specified"
  exit
fi

if ! test -d $STATE_LOC; then
  echo "ERROR: State folder $STATE_LOC does not exist"
  exit
fi

export STATE_LOC=readlink -m $STATE_LOC
# Test if the state is done (file exists) 
function state_done() {
  test -f $STATE_LOC/"$1"
}

# Set the state to done
function state_set_done() {
  touch $STATE_LOC/"$1"
}

# Set the state to done and it's value
function state_set() {
  echo "$2" > $STATE_LOC/"$1"
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