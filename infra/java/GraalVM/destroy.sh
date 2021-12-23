#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


# Install Graal
if test -d ~/graalvm-ce-java11-20.1.0; then
  rm -rf ~/graalvm-ce-java11-20.1.0
fi


rm -f $STATE_FILE