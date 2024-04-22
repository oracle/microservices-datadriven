#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


# Destroy java home
STATE=$DCMS_INFRA_STATE/java
cd $STATE
provisioning-destroy
state_reset JAVA_HOME


# Destroy image repos
STATE=$DCMS_INFRA_STATE/image-repo
cd $STATE
provisioning-destroy
state_reset IMAGE_REPOS


# Delete state file
rm -f $STATE_FILE
state_reset BUILD_PREP_THREAD