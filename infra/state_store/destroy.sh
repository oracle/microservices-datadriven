#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .

if ! provisioning-helper-pre-destroy; then
  return 1
fi

STATE_STORE_STATE=$MY_STATE/state

if test -d $STATE_STORE_STATE; then
  rm -rf $STATE_STORE_STATE
fi

rm -f $STATE_FILE