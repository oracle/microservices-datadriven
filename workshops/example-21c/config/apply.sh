#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu


if ! provisioning-helper-pre-apply; then
  exit 1
fi

# Provision Databases
for db in db1 db2; do
  db_upper=`echo $db | tr '[:lower:]' '[:upper:]'`
  DB_STATE=$MY_STATE/$db
  mkdir -p $DB_STATE
  cd $DB_STATE
  cat >input.env <<!
TENANCY_OCID='$TENANCY_OCID'
COMPARTMENT_OCID='$COMPARTMENT_OCID'
OCI_REGION='$OCI_REGION'
DB_NAME='${RUN_NAME}${db_upper}'
DISPLAY_NAME='${db_upper}'
DB_PASSWORD_SECRET='DB_PASSWORD_SECRET'
RUN_NAME='$RUN_NAME'
VCN_OCID=''
#VERSION='19c'
VERSION='21c'
!

  provisioning-apply $MSDD_INFRA_CODE/db/atp
  (
  source $DB_STATE/output.env
  cat >>$OUTPUT_FILE <<!
  ${db_upper}_OCID='$DB_OCID'
  ${db_upper}_TNS_ADMIN='$TNS_ADMIN'
  ${db_upper}_ALIAS='$DB_ALIAS'
!
  )
done
