#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

if ! provisioning-helper-pre-destroy; then
  exit 1
fi

oci os bucket delete --force --name "$BUCKET_NAME"

rm -f $STATE_FILE