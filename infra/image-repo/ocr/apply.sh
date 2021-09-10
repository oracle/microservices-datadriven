#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
  exit 1
fi


# Provision Repos
REPO_OCIDS=""
for b in $BUILDS; do
  REPO_OCID=`oci artifacts container repository create --compartment-id "$COMPARTMENT_OCID" --display-name "$RUN_NAME/$b" --is-public true --query "data.id" --raw-output`
  REPO_OCIDS="$REPO_OCIDS $REPO_OCID"
done
echo "REPO_OCIDS='$REPO_OCIDS'" >>$STATE_FILE


touch $OUTPUT_FILE