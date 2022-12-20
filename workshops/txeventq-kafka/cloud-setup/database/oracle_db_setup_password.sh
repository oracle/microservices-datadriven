#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

function db_password_valid() {
  local password=$1
  (( ${#password} >= 12 ))         || echo 'Error: Too short'
  (( ${#password} <= 30 ))         || echo 'Error: Too long'
  [[ $password == *[[:digit:]]* ]] || echo 'Error: Does not contain a digit'
  [[ $password == *[[:lower:]]* ]] || echo 'Error: Does not contain a lower case letter'
  [[ $password == *[[:upper:]]* ]] || echo 'Error: Does not contain an upper case letter'
  [[ $password != *'"'* ]]         || echo 'Error: Cannot contain the double quote (") character'
  [[ $(echo "$password" | tr '[:lower:]' '[:upper:]') != *'ADMIN'* ]]  || echo 'Error: Cannot contain the word "admin".'
}

  echo
  echo 'Enter the password to be used for the lab database.'
  echo 'Database passwords must be 12 to 30 characters and contain at least one uppercase letter,'
  echo 'one lowercase letter, and one number. The password cannot contain the double quote (")'
  echo 'character or the word "admin".'
  echo

  # Collect the DB password
  while true; do
    #read -s -r -p "Enter the password to be used for the lab database: " PW
    read -s -r -p "Please enter a password: " PW
    echo "***********"
    read -s -r -p "Retype a password: " second
    echo "***********"

    if [ "$PW" != "$second" ]; then
      echo "You have entered different passwords. Please, try again.."
      echo
      continue
    fi

    msg=$(db_password_valid "$PW");
    if [[ $msg != *'Error'* ]] ; then
      echo
      break
    else
      echo "$msg"
      echo "You have entered invalid passwords. Please, try again.."
      echo
    fi
  done
  BASE64_DB_PASSWORD=$(echo -n "$PW" | base64)

  echo "my password $PW"

