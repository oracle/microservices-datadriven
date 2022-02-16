#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

GRAALVM_VERSION=${1:-"22.0.0.2"}
OS_NAME=`uname`

# Install GraalVM
if ! test -d ~/graalvm-ce-java11-${GRAALVM_VERSION}; then
  (cd ~ && curl -sL https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-${GRAALVM_VERSION}/graalvm-ce-java11-${OS_NAME}-amd64-${GRAALVM_VERSION}.tar.gz | tar xz)
#  mv graalvm-ce-java11-${GRAALVM_VERSION} ~/
fi

if ! [[ $OS_NAME == *"darwin"* ]]; then
  # Assume linux
  ~/graalvm-ce-java11-${GRAALVM_VERSION}/bin/gu install native-image
  export JAVA_HOME=~/graalvm-ce-java11-${GRAALVM_VERSION}
else
  # We are on Mac doing local dev
  ~/graalvm-ce-java11-${GRAALVM_VERSION}/Contents/Home/bin/gu install native-image
  export JAVA_HOME=~/graalvm-ce-java11-${GRAALVM_VERSION}/Contents/Home;
fi

export PATH=$JAVA_HOME/bin:$PATH

state_set_done GRAALVM_INSTALLED
