#!/bin/bash
# Copyright (c) 2021, 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

GRAALVM_VERSION=${1:-"21"}
OS_NAME="$(uname -s | tr '[:upper:]' '[:lower:]')"
MACHINE_ARCH=$(uname -p)

if [[ $OS_NAME == *"darwin"* ]] && [[ $MACHINE_ARCH == *"arm"* ]]; then
  OS_NAME=macos
  MACHINE_ARCH=aarch64
fi

# Install Oracle GraalVM
# https://download.oracle.com/graalvm/21/latest/graalvm-jdk-21_linux-aarch64_bin.tar.gz
# https://download.oracle.com/graalvm/21/latest/graalvm-jdk-21_macos-aarch64_bin.tar.gz

if ! test -d ~/graalvm-jdk-"${GRAALVM_VERSION}"; then
  echo "$(date): Installing Oracle GraalVM ${GRAALVM_VERSION}"
  (cd ~ && wget -q https://download.oracle.com/graalvm/"${GRAALVM_VERSION}"/latest/graalvm-jdk-"${GRAALVM_VERSION}"_"${OS_NAME}"-"${MACHINE_ARCH}"_bin.tar.gz)
  tar xzf graalvm-jdk-"${GRAALVM_VERSION}"_"${OS_NAME}"-"${MACHINE_ARCH}"_bin.tar.gz
  rm graalvm-jdk-"${GRAALVM_VERSION}"_"${OS_NAME}"-"${MACHINE_ARCH}"_bin.tar.gz
  mv graalvm-jdk-${GRAALVM_VERSION}* ~/graalvm-jdk-"${GRAALVM_VERSION}"
  export JAVA_HOME=~/graalvm-jdk-"${GRAALVM_VERSION}"
fi

if [[ $OS_NAME == *"darwin"* ]]; then
  export JAVA_HOME=$JAVA_HOME/Contents/Home
fi
echo "$(date): JAVA_HOME ${JAVA_HOME}"

export PATH=$JAVA_HOME/bin/:$PATH
echo "$(date): PATH ${PATH}"

if ! state_done CONTAINER_ENG_SETUP; then
  echo "$(date): Oracle GraalVM ${GRAALVM_VERSION}"
  docker pull container-registry.oracle.com/graalvm/jdk:${GRAALVM_VERSION} --quiet
  state_set CONTAINER_ENG_SETUP "container-registry.oracle.com/graalvm/jdk:${GRAALVM_VERSION}"
  echo
fi

state_set_done GRAALVM_INSTALLED
