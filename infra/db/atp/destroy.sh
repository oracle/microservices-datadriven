#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


# Remove wallet and other TNS information
if test -f $MY_STATE/state_wallet_downloaded; then
  TNS_ADMIN=$MY_STATE/tns_admin
  rm -rf $TNS_ADMIN
  rm $MY_STATE/state_wallet_downloaded
fi


# Cancel Set DB Password
if test -f $MY_STATE/state_password_set; then
  rm $MY_STATE/state_password_set
fi


# Execute terraform destroy
if test -f $MY_STATE/state_provisioning_done; then
  if [[ ! "$BYO_DB_OCID" =~ ^ocid1\.autonomousdatabase ]]; then
    cd $MY_STATE/terraform
    export TF_VAR_ociCompartmentOcid="$COMPARTMENT_OCID"
    export TF_VAR_ociRegionIdentifier="$OCI_REGION"
    export TF_VAR_dbName="$DB_NAME"
    export TF_VAR_displayName="$DISPLAY_NAME"
    case "$VERSION" in
      21c)
        export TF_VAR_dbVersion='21c'
        export TF_VAR_dbIsFreeTier='true'
        ;;
      19c)
        export TF_VAR_dbVersion='19c'
        export TF_VAR_dbIsFreeTier='false'
        ;;
      *)
        echo "Error: Invalid DB version $VERSION"
        exit 1
        ;;
    esac

    if ! terraform init; then
        echo 'ERROR: terraform init failed!'
        exit 1
    fi

    if ! terraform destroy -auto-approve; then
        echo 'ERROR: terraform destroy failed!'
        exit 1
    fi
  fi
  rm $MY_STATE/state_provisioning_done
fi


rm -f $STATE_FILE