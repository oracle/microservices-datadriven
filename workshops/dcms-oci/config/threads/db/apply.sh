#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu


if ! provisioning-helper-pre-apply; then
  exit 1
fi


# Wait for dependencies
DEPENDENCIES='COMPARTMENT_OCID OCI_REGION DB1_NAME DB2_NAME DB_PASSWORD_SECRET RUN_NAME ATP_LIMIT_CHECK VCN_OCID DB_DEPLOYMENT DB_TYPE'
while ! test -z "$DEPENDENCIES"; do
  echo "Waiting for $DEPENDENCIES"
  WAITING_FOR=""
  for d in $DEPENDENCIES; do
    if ! state_done $d; then
      WAITING_FOR="$WAITING_FOR $d"
    fi
  done
  DEPENDENCIES="$WAITING_FOR"
  sleep 1
done


# Provision the Wallet Object Store Bucket (ATP only)
if test "$(state_get DB_TYPE)" == "ATP"; then
  OS_STATE=$DCMS_INFRA_STATE/os
  mkdir -p $OS_STATE
  cd $OS_STATE
  cat >$OS_STATE/input.env <<!
COMPARTMENT_OCID=$(state_get COMPARTMENT_OCID)
BUCKET_NAME=$(state_get RUN_NAME)
!
  provisioning-apply $MSDD_INFRA_CODE/os/oci
  state_set CWALLET_OS_BUCKET "$(state_get RUN_NAME)"
else
  state_set CWALLET_OS_BUCKET ''
fi


# For Live Labs
if test "$(state_get RUN_TYPE)" == 'LL'; then
  # For Live Labs set the password and download the tns info
  for db in db1 db2; do
    db_upper=`echo $db | tr '[:lower:]' '[:upper:]'`
    # Legacy - until we change LL terraform to create DB1 and DB2
    if test "$db" == 'db1'; then
      DB_DIS_NAME="ORDERDB"
    else
      DB_DIS_NAME="INVENTORYDB"
    fi

    # DB is already provisioned.  Just need to set the password and get the TNS info
    if ! state_done ${db_upper}_OCID; then
      DB_OCID=`oci db autonomous-database list --compartment-id "$(state_get COMPARTMENT_OCID)" --query 'join('"' '"',data[?"display-name"=='"'${DB_DIS_NAME}'"'].id)' --raw-output`
      state_set ${db_upper}_OCID "$DB_OCID"
    fi

    # Set the password
    if ! state_done ${db_upper}_PASSWORD_SET; then
      DB_PASSWORD=$(get_secret $(state_get DB_PASSWORD_SECRET))
      umask 177
      echo '{"adminPassword": '`echo -n "$DB_PASSWORD" | jq -aRs .`'}' > temp_params
      umask 22
      oci db autonomous-database update --autonomous-database-id "$(state_get ${db_upper}_OCID)" --from-json "file://temp_params" >/dev/null
      rm temp_params
      state_set_done ${db_upper}_PASSWORD_SET
    fi

    # Download the wallet
    if ! state_done ${db_upper}_TNS_ADMIN; then
      TNS_ADMIN=$MY_STATE/${db}_tns_admin
      mkdir -p $TNS_ADMIN
      rm -rf $TNS_ADMIN/*
      cd $TNS_ADMIN
      oci db autonomous-database generate-wallet --autonomous-database-id "$(state_get ${db_upper}_OCID)" --file 'wallet.zip' --password 'Welcome1' --generate-type 'ALL'
      unzip wallet.zip
      cat - >sqlnet.ora <<!
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$TNS_ADMIN")))
SSL_SERVER_DN_MATCH=yes
!
      state_set ${db_upper}_TNS_ADMIN "$TNS_ADMIN"
      state_set ${db_upper}_ALIAS "$(state_get ${db_upper}_NAME)_tp"
    fi
  done
else
  # Not Live Labs so need to provision the databases
  # Switch depending on DB deployment mode
  case $(state_get DB_DEPLOYMENT) in
    1DB)
      # We need to provision one database
      DB_STATE=$DCMS_INFRA_STATE/db/db1
      mkdir -p $DB_STATE
      cat >$DB_STATE/input.env <<!
TENANCY_OCID='$(state_get TENANCY_OCID)'
COMPARTMENT_OCID=$(state_get COMPARTMENT_OCID)
OCI_REGION=$(state_get OCI_REGION)
DB_NAME=$(state_get DB1_NAME)
DISPLAY_NAME='DB1'
DB_PASSWORD_SECRET=$(state_get DB_PASSWORD_SECRET)
RUN_NAME=$(state_get RUN_NAME)
VCN_OCID=$(state_get VCN_OCID)
VERSION='19c'
!
      cd $DB_STATE
      if test $(state_get DB_TYPE) == "ATP"; then
        provisioning-apply $MSDD_INFRA_CODE/db/atp
      else
        provisioning-apply $MSDD_INFRA_CODE/db/dbcs
      fi  
      (
      source $DB_STATE/output.env
      state_set DB1_OCID "$DB_OCID"
      state_set DB1_TNS_ADMIN $TNS_ADMIN
      state_set DB1_ALIAS "$DB_ALIAS"
      state_set DB2_OCID ''
      state_set DB2_TNS_ADMIN ''
      state_set DB2_ALIAS ''
      )
      ;;
    2DB)
      for db in db1 db2; do
        db_upper=`echo $db | tr '[:lower:]' '[:upper:]'`
        DB_STATE=$DCMS_INFRA_STATE/db/$db
        mkdir -p $DB_STATE
        cd $DB_STATE
        DB_NAME="$(state_get ${db_upper}_NAME)"
        cat >input.env <<!
TENANCY_OCID='$(state_get TENANCY_OCID)'
COMPARTMENT_OCID='$(state_get COMPARTMENT_OCID)'
OCI_REGION='$(state_get OCI_REGION)'
DB_NAME='$DB_NAME'
DISPLAY_NAME='${db_upper}'
DB_PASSWORD_SECRET='$(state_get DB_PASSWORD_SECRET)'
RUN_NAME='$(state_get RUN_NAME)'
VCN_OCID='$(state_get VCN_OCID)'
VERSION='19c'
!
        if test $(state_get DB_TYPE) == "ATP"; then
          provisioning-apply $MSDD_INFRA_CODE/db/atp
        else
          provisioning-apply $MSDD_INFRA_CODE/db/dbcs
        fi  
        (
        source $DB_STATE/output.env
        state_set ${db_upper}_OCID "$DB_OCID"
        state_set ${db_upper}_TNS_ADMIN $TNS_ADMIN
        state_set ${db_upper}_ALIAS "$DB_ALIAS"
        )
      done
      ;;
    *)
      echo "ERROR: Invalid DB_DEPLOYMENT $(state_get DB_DEPLOYMENT)"
      exit 1
  esac
fi

touch $OUTPUT_FILE
state_set_done DB_THREAD