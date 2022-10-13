#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if ! (return 0 2>/dev/null); then
  echo "ERROR: Usage 'source env.sh'"
  exit
fi

# POSIX compliant find and replace
function sed_i(){
  local OP="$1"
  local FILE="$2"
  sed -e "$OP" "$FILE" >"/tmp/$FILE"
  mv -- "/tmp/$FILE" "$FILE"
}
export -f sed_i

# Set LAB_HOME
str="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
substr="cloud-setup"
prefix=${str%%$substr*}
index=${#prefix}
export LAB_HOME=${str:0:$index-1}
cd "$LAB_HOME" || exit
echo "LAB_HOME: $LAB_HOME"

# Java Home
GRAALVM_VERSION=${1:-"22.2.0"}
OS_NAME=$(uname)
if ! [[ $OS_NAME == *"darwin"* ]]; then
  # Assume linux
  export JAVA_HOME=~/graalvm-ce-java11-${GRAALVM_VERSION}
else
  # We are on Mac doing local dev
  export JAVA_HOME=~/graalvm-ce-java11-${GRAALVM_VERSION}/Contents/Home;
fi
export PATH=$JAVA_HOME/bin/:$PATH

# Setup CMD bin
export PATH=${LAB_HOME}/cloud-setup/cmd/:$PATH

# State directory
if test -d ~/lab-state; then
  export LAB_STATE_HOME=~/lab-state
else
  export LAB_STATE_HOME="${LAB_HOME}"/cloud-setup/state
fi

# Log directory
export LAB_LOG="${LAB_HOME}"/cloud-setup/log
mkdir -p "${LAB_LOG}"

# Source the state functions
source "${LAB_HOME}"/cloud-setup/utils/state-functions.sh

# Identify Run Type
regex='/home/ll[0-9]{1,5}_us'
while ! state_done RUN_TYPE; do
  if [[ "$HOME" =~  ${regex} ]]; then
    # Green Button (hosted by Live Labs)
    state_set RUN_TYPE "3"
    state_set RESERVATION_ID $(grep -oP '(?<=/home/ll).*?(?=_us)' <<<"$HOME")
    state_set USER_OCID 'NA'
    state_set USER_NAME "LL$(state_get RESERVATION_ID)-USER"
    state_set_done PROVISIONING
    state_set RUN_NAME "lab$(state_get RESERVATION_ID)"
    state_set LAB_DB_NAME "LAB$(state_get RESERVATION_ID)"
    state_set_done ATP_LIMIT_CHECK
  else
    state_set RUN_TYPE "1"
  fi
done

# Get Run Name from directory name
while ! state_done RUN_NAME; do
  cd "$LAB_HOME"
  cd ../../..
  # Validate that a folder was creared
  if test "$PWD" == ~; then
    echo "ERROR: The workshop is not installed in a separate folder."
    exit
  fi
  DN=$(basename "$PWD")
  # Validate run name.  Must be between 1 and 13 characters, only letters or numbers, starting with letter
  if [[ "$DN" =~ ^[a-zA-Z][a-zA-Z0-9]{0,12}$ ]]; then
    # shellcheck disable=SC2046
    state_set RUN_NAME $(echo "$DN" | awk '{print tolower($0)}')
    state_set LAB_DB_NAME "$(state_get RUN_NAME)"
  else
    echo "Error: Invalid directory name $RN.  The directory name must be between 1 and 13 characters,"
    echo "containing only letters or numbers, starting with a letter.  Please restart the workshop with a valid directory name."
    exit
  fi
  cd "$LAB_HOME"
done

# Configure Bash to LAB Environment
#source "${LAB_HOME}"/cloud-setup/utils/bash-setup.sh
if ! state_get BASH_SETUP; then
  if ps -ef | grep "$LAB_HOME/cloud-setup/utils/bash-setup.sh" | grep -v grep; then
    echo "$LAB_HOME/cloud-setup/utils/bash_setup.sh is already running"
  else
    echo "Executing bash_setup.sh in the background"
    nohup "$LAB_HOME"/cloud-setup/utils/bash-setup.sh &>>"$LAB_LOG"/bash-setup.log &
  fi
fi