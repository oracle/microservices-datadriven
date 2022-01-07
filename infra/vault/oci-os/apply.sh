#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu


if ! provisioning-helper-pre-apply; then
  exit 1
fi


oci os bucket create --compartment-id "$COMPARTMENT_OCID" --name "$BUCKET_NAME" >/dev/null
  
cat >$OUTPUT_FILE <<!
export VAULT_BUCKET='$BUCKET_NAME'
!
cat $MY_CODE/vault-oci-os-functions.env >>$OUTPUT_FILE