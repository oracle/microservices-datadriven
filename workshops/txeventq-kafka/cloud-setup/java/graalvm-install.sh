#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

GRAALVM_VERSION=${1:-"22.2.0"}
OS_NAME=$(uname)

# Install GraalVM
# https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-22.2.0/graalvm-ce-java11-linux-amd64-22.2.0.tar.gz
if ! test -d ~/graalvm-ce-java11-"${GRAALVM_VERSION}"; then
  echo "$(date): Installing graalvm-ce-java11-${GRAALVM_VERSION}"
  (cd ~ && curl -sL https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-"${GRAALVM_VERSION}"/graalvm-ce-java11-"${OS_NAME}"-amd64-"${GRAALVM_VERSION}".tar.gz | tar xz)
#  mv graalvm-ce-java11-${GRAALVM_VERSION} ~/
fi

if ! [[ $OS_NAME == *"darwin"* ]]; then
  # Assume linux
  ~/graalvm-ce-java11-"${GRAALVM_VERSION}"/bin/gu install native-image
  export JAVA_HOME=~/graalvm-ce-java11-${GRAALVM_VERSION}
else
  # We are on Mac doing local dev
  ~/graalvm-ce-java11-"${GRAALVM_VERSION}"/Contents/Home/bin/gu install native-image
  export JAVA_HOME=~/graalvm-ce-java11-${GRAALVM_VERSION}/Contents/Home;
  echo "$(date): JAVA_HOME ${JAVA_HOME}"
fi

export PATH=$JAVA_HOME/bin/:$PATH
echo "$(date): PATH ${PATH}"

if ! state_done CONTAINER_ENG_SETUP; then
  echo "$(date): Installing GraalVM CE Java 11 Image"
  docker pull ghcr.io/graalvm/graalvm-ce:ol8-java11 --quiet
  state_set CONTAINER_ENG_SETUP "ghcr.io/graalvm/graalvm-ce:ol8-java11"
  echo
fi

state_set_done GRAALVM_INSTALLED
