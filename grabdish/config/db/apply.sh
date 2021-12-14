#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu


if ! provisioning-helper-pre-apply; then
  exit 1
fi


export GRABDISH_LOG


# Setup the environment variable
DB_PASSWORD=$(get_secret $DB_PASSWORD_SECRET)

CONFIG_HOME=$GRABDISH_HOME/config/db
if test $DB_DEPLOYMENT == "1DB"; then
  # 1DB
  SCRIPT_HOME=$CONFIG_HOME/1db/apply
else
  # 2DB
  if test $DB_TYPE == "ATP"; then
    # ATP
    SCRIPT_HOME=$CONFIG_HOME/2db-atp/apply

    # Create Object Store CWALLET objects and auth URLs for each database
    for db in DB1 DB2; do
      # Put DB Connection Wallet in the bucket in Object Store
      if ! test -f $MY_STATE/${db}_state_cwallet_put; then
        eval "cd \$${db}_TNS_ADMIN"
        oci os object put --bucket-name $CWALLET_OS_BUCKET --name "${db}_cwallet.sso" --file 'cwallet.sso'
        touch $MY_STATE/${db}_state_cwallet_put
      fi

      # Create Authenticated Link to Wallet
      if ! test -f $MY_STATE/${db}_state_cwallet_auth_url; then
        if test `uname` == 'Linux'; then
          EXPIRE_DATE=$(date '+%Y-%m-%d' --date '+7 days')
        else
          EXPIRE_DATE=$(date -v +7d '+%Y-%m-%d')
        fi
        ACCESS_URI=`oci os preauth-request create --object-name "${db}_cwallet.sso" --access-type 'ObjectRead' --bucket-name "$CWALLET_OS_BUCKET" --name 'grabdish' --time-expires "$EXPIRE_DATE" --query 'data."access-uri"' --raw-output`
        CWALLET_SSO_AUTH_URL="https://objectstorage.${OCI_REGION}.oraclecloud.com${ACCESS_URI}"
        echo "${db}_CWALLET_SSO_AUTH_URL='$CWALLET_SSO_AUTH_URL'" >>$STATE_FILE
        touch $MY_STATE/${db}_state_cwallet_auth_url
      fi
    done
    source $STATE_FILE
  else
    # Standard Database
    SCRIPT_HOME=$CONFIG_HOME/2db-sa/apply
  fi
fi

source $CONFIG_HOME/params.env


# Expand common scripts
COMMON_SCRIPT_HOME=$MY_STATE/expanded-common-scripts/apply
rm -rf $COMMON_SCRIPT_HOME
mkdir -p $COMMON_SCRIPT_HOME
chmod 700 $COMMON_SCRIPT_HOME
files=$(ls $CONFIG_HOME/common/apply)
for f in $files; do
  eval "
cat >$COMMON_SCRIPT_HOME/$f <<!
$(<$CONFIG_HOME/common/apply/$f)
!
"
  chmod 400 $COMMON_SCRIPT_HOME/$f
done


# Execute DB setup scripts
files=$(ls $SCRIPT_HOME)
for f in $files; do
  # Execute all the SQL scripts in order using the appropriate TNS_ADMIN
  db=`grep -o 'db.' <<<"$f"`
  db_upper=`echo $db | tr '[:lower:]' '[:upper:]'`
  echo "Executing $SCRIPT_HOME/$f on database $db_upper"
  eval "
export TNS_ADMIN=\$${db_upper}_TNS_ADMIN
sqlplus /nolog <<!
$(<$SCRIPT_HOME/$f)
!
"
# DEBUG
eval "
cat <<!
$(<$SCRIPT_HOME/$f)
!
"
done


# Remove expanded common scripts
rm -rf $COMMON_SCRIPT_HOME


cat >$OUTPUT_FILE <<!
ORDER_DB_NAME="$ORDER_DB_NAME"
ORDER_DB_ALIAS="$ORDER_DB_ALIAS"
ORDER_DB_TNS_ADMIN="$ORDER_DB_TNS_ADMIN"
INVENTORY_DB_NAME="$INVENTORY_DB_NAME"
INVENTORY_DB_ALIAS="$INVENTORY_DB_ALIAS"
INVENTORY_DB_TNS_ADMIN="$INVENTORY_DB_TNS_ADMIN"
!