#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if ! provisioning-helper-pre-destroy; then
  return 1
fi

VAULT_FOLDER=$MY_STATE/vault

if test -d $VAULT_FOLDER; then
  rm -rf $VAULT_FOLDER
fi

rm -f $STATE_FILE