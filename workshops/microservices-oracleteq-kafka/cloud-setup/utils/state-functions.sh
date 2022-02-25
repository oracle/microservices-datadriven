#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if ! (return 0 2>/dev/null); then
  echo "ERROR: Usage: 'source state-functions.sh"
  exit
fi

if test -z "$LAB_STATE_HOME"; then
  echo "ERROR: The lab state home folder was not set"
else
  mkdir -p "$LAB_STATE_HOME"
fi

# Test if the state is done (file exists)
function state_done() {
  test -f "$LAB_STATE_HOME"/"$1"
}

# Set the state to done
function state_set_done() {
  touch "$LAB_STATE_HOME"/"$1"
  echo "$(date): $1" >>"$LAB_LOG"/state.log
  echo "$1 completed"
}

# Set the state to done and it's value
function state_set() {
  echo "$2" > "$LAB_STATE_HOME"/"$1"
  echo "$(date): $1: $2" >>"$LAB_LOG"/state.log
#  echo "$1: $2"
}

# Reset the state - not done and no value
function state_reset() {
  rm -f "$LAB_STATE_HOME"/"$1"
}

# Get state value
function state_get() {
    if ! state_done "$1"; then
        return 1
    fi
    cat "$LAB_STATE_HOME"/"$1"
}

# Export the functions so that they are available to subshells
export -f state_done
export -f state_set_done
export -f state_set
export -f state_reset
export -f state_get
