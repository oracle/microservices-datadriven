#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if ! provisioning-helper-pre-apply; then
  exit 1
fi

VAULT_FOLDER=$MY_STATE/vault
mkdir -p $VAULT_FOLDER
chmod 700 $VAULT_FOLDER
export VAULT_FOLDER
  
cat >$OUTPUT_FILE <<!
export VAULT_FOLDER=$VAULT_FOLDER
!
cat $MY_CODE/vault-folder-functions.env >>$OUTPUT_FILE