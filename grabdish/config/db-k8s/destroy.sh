#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy-sh; then
  exit 1
fi


cd $MY_CODE/../..
export GRABDISH_HOME=$PWD
export GRABDISH_LOG


# Delete SSL Certs and anything else
rm -rf $MY_STATE/*