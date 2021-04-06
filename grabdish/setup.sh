#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if ! (return 0 2>/dev/null); then
  echo "ERROR: Usage 'source setup.sh'"
  exit
fi

# Set GRABDISH_HOME
export GRABDISH_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $GRABDISH_HOME
echo "GRABDISH_HOME: $GRABDISH_HOME"

export JAVA_HOME=~/graalvm-ce-java11-20.1.0

$GRABDISH_HOME/utils/main-setup.sh