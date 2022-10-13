#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

GRAALVM_VERSION=${1:-"22.2.0"}

if ! state_get GRAALVM_INSTALLED; then
  exit 1
fi

# Uninstall GraalVM
if test -d ~/graalvm-ce-java11-"${GRAALVM_VERSION}"; then
  echo "$(date): Uninstalling graalvm-ce-java11-${GRAALVM_VERSION} local installation."
  rm -rf ~/graalvm-ce-java11-"${GRAALVM_VERSION}"
fi

# Uninstall GraalVM Image
if state_done CONTAINER_ENG_SETUP; then
  result=$(docker inspect -f '{{.Id}}' "$(state_get CONTAINER_ENG_SETUP)")
  if [[ "$result" != "" ]]; then
    echo "$(date): Uninstalling $(state_get CONTAINER_ENG_SETUP) Image"
    docker rmi -f $(state_get CONTAINER_ENG_SETUP)
    state_reset CONTAINER_ENG_SETUP
    echo
  fi
fi