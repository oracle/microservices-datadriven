#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

if ! provisioning-helper-pre-destroy; then
  exit 1
fi


# Delete Repos
echo "Deleting Repositories"
for r in $REPO_OCIDS; do 
  oci artifacts container repository delete --repository-id "$r" --force || true
done


rm -f $STATE_FILE