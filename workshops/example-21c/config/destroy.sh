#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

if ! provisioning-helper-pre-destroy; then
  exit 1
fi

# Destroy the DBs
DBS="db1 db2"
for db in $DBS; do
  DB_STATE=$MY_STATE/$db
  cd $DB_STATE
  provisioning-destroy
done

# Delete state file
rm -f $STATE_FILE
