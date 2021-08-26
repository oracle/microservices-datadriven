#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# INPUTS:
# input.env
#   PASSWORD_SECRET
#
# OUTPUTS:
# None


# Fail on error
set -e


# Check the home folder
MY_HOME="$1"
if ! test -d "$MY_HOME"; then
  echo "ERROR: The home folder does not exist"
  exit
fi


# Source input.env
if test -f $MY_HOME/input.env; then
  source "$MY_HOME"/input.env
else
  echo "ERROR: input.env is required"
  exit
fi


# Source output.env
if test -f $MY_HOME/output.env; then
  source "$MY_HOME"/output.env
else
  echo "ERROR: Cannot set password as setup has not completed"
  exit
fi


cd $MY_HOME
DB_PASSWORD=$(get_secret $PASSWORD_SECRET)
umask 177
echo '{"adminPassword": "'"$DB_PASSWORD"'"}' > temp_params
umask 22
oci db autonomous-database update --autonomous-database-id "$DB_OCID" --from-json "file://temp_params" >/dev/null
rm temp_params