#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


export GRABDISH_LOG


# Setup the environment variable
DB_PASSWORD=$(get_secret $DB_PASSWORD_SECRET)

CONFIG_HOME=$GRABDISH_HOME/config/db
if test $DB_DEPLOYMENT == "1DB"; then
  # 1DB
  SCRIPT_HOME=$CONFIG_HOME/1db/destroy
else
  # 2DB
  if test $DB_TYPE == "ATP"; then
    # ATP
    SCRIPT_HOME=$CONFIG_HOME/2db-atp/destroy
  else
    # Stand Alone
    SCRIPT_HOME=$CONFIG_HOME/2db-sa/destroy
  fi
fi

source $CONFIG_HOME/params.env


# Expand common destroy scripts
# COMMON_SCRIPT_HOME=$MY_STATE/expanded-common-scripts/destroy
# mkdir -p $COMMON_SCRIPT_HOME
# chmod 700 $COMMON_SCRIPT_HOME
# files=$(ls -r $CONFIG_HOME/common/destroy)
# for f in $files; do
#   eval "
# cat >$COMMON_SCRIPT_HOME/$f <<!
# $(<$CONFIG_HOME/common/destroy/$f)
# !
# "
#   chmod 400 $COMMON_SCRIPT_HOME/$f
# done


# Execute DB destroy scripts
files=$(ls -r $SCRIPT_HOME)
for f in $files; do
  # Execute all the SQL scripts in order using the appropriate TNS_ADMIN
  db=`grep -o 'db.' <<<"$f"`
  db_upper=`echo $db | tr '[:lower:]' '[:upper:]'`
  echo "Executing $SCRIPT_HOME/$f on database $db"
  eval "
export TNS_ADMIN=\$${db_upper}_TNS_ADMIN
sqlplus /nolog <<!
$(<$SCRIPT_HOME/$f)
!
"
done


# Remove expanded common scripts
rm -rf $COMMON_SCRIPT_HOME


# Clean up the object store
if test $DB_DEPLOYMENT == "2DB" && test $DB_TYPE == "ATP"; then
  # Delete Authenticated Link to Wallet
  if !  test -f $MY_STATE/DB1_state_cwallet_auth_url || test -f $MY_STATE/DB2_state_cwallet_auth_url; then
    PARIDS=`oci os preauth-request list --bucket-name "$CWALLET_OS_BUCKET" --query "join(' ',data[*].id)" --raw-output`
    for id in $PARIDS; do
      oci os preauth-request delete --par-id "$id" --bucket-name "$CWALLET_OS_BUCKET" --force
    done
    rm -f $MY_STATE/DB1_state_cwallet_auth_url
    rm -f $MY_STATE/DB2_state_cwallet_auth_url
  fi


  for db in DB1 DB2; do
    # Remove Object from Bucket
    if test -f $MY_STATE/${db}_state_cwallet_put; then
      oci os object delete --object-name "${db}_cwallet.sso" --bucket-name "$CWALLET_OS_BUCKET" --force
      rm -f $MY_STATE/${db}_state_cwallet_put
    fi
  done
fi


rm -f $STATE_FILE