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

# export LAB_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck disable=SC2164
cd "$LAB_HOME"
echo "LAB_HOME: $LAB_HOME"

# Java Home
GRAALVM_VERSION=${1:-"22.1.0"}
OS_NAME=$(uname)
if ! [[ $OS_NAME == *"darwin"* ]]; then
  # Assume linux
  export JAVA_HOME=~/graalvm-ce-java11-${GRAALVM_VERSION}
else
  # We are on Mac doing local dev
  export JAVA_HOME=~/graalvm-ce-java11-${GRAALVM_VERSION}/Contents/Home;
fi
export PATH=$JAVA_HOME/bin/:$PATH

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

export PATH=$PATH:${LAB_HOME}/cloud-setup/utils/
