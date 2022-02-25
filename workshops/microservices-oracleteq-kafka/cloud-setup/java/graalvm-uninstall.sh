#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

GRAALVM_VERSION=${1:-"22.0.0.2"}

if ! state_get GRAALVM_INSTALLED; then
  exit 1
fi

# Install GraalVM
if test -d ~/graalvm-ce-java11-"${GRAALVM_VERSION}"; then
  rm -rf ~/graalvm-ce-java11-"${GRAALVM_VERSION}"
fi
