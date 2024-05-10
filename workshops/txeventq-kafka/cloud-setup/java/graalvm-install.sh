#!/bin/bash
# Copyright (c) 2021, 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

GRAALVM_VERSION=${1:-"17.0.9"}
OS_NAME=$(uname)

# Install GraalVM
# https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-17.0.9/graalvm-community-jdk-17.0.9_linux-aarch64_bin.tar.gz
if ! test -d ~/graalvm-community-jdk-"${GRAALVM_VERSION}"; then
  echo "$(date): Installing community-jdk-${GRAALVM_VERSION}"
  (cd ~ && curl -sL https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-"${GRAALVM_VERSION}"/graalvm-community-jdk-17.0.9_"${OS_NAME}"-aarch64_bin.tar.gz | tar xz)
#  mv graalvm-ce-java11-${GRAALVM_VERSION} ~/
fi

if ! [[ $OS_NAME == *"darwin"* ]]; then
  # Assume linux
  ~/graalvm-community-openjdk-"${GRAALVM_VERSION}+9.1"/bin/gu install native-image
  export JAVA_HOME=~/graalvm-community-openjdk-${GRAALVM_VERSION}+9.1
fi
# else
#   # We are on Mac doing local dev
#   ~/graalvm-ce-java11-"${GRAALVM_VERSION}"/Contents/Home/bin/gu install native-image
#   export JAVA_HOME=~/graalvm-ce-java11-${GRAALVM_VERSION}/Contents/Home;
#   echo "$(date): JAVA_HOME ${JAVA_HOME}"
# fi

export PATH=$JAVA_HOME/bin/:$PATH
echo "$(date): PATH ${PATH}"

if ! state_done CONTAINER_ENG_SETUP; then
  echo "$(date): GraalVM for JDK 17 Community 17.0.9"
  docker pull ghcr.io/graalvm/graalvm-community:17.0.9 --quiet
  state_set CONTAINER_ENG_SETUP "docker pull ghcr.io/graalvm/graalvm-community:17.0.9"
  echo
fi

state_set_done GRAALVM_INSTALLED
