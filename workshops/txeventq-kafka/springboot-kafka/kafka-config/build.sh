#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


# Check home is set
if test -z "$LAB_HOME"; then
  echo "ERROR: This script requires LAB_HOME to be set"
  exit
fi


# Build the project
mvn clean install -DskipTests
