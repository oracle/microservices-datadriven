#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

# Give GRAALVM_INSTALLED priority
while ! state_done GRAALVM_INSTALLED; do
  echo "Waiting for GRAALVM_INSTALLED"
  sleep 5
done

# Check JAVA_HOME
pattern='*graalvm-ce-java11-22.0.0.2'

if [[ -z "${JAVA_HOME}" ]] ||  [[ "${JAVA_HOME}" != $pattern ]]
then
    JAVA_HOME="$HOME"/graalvm-ce-java11-22.0.0.2
    if [ ! -e "$JAVA_HOME" ]
    then
      echo "ERROR: This script requires JAVA_HOME to be set to GraalVM"
      exit
    fi
    export JAVA_HOME=$JAVA_HOME
fi

# PATH to OKafka Library
OKAFKA_LIB="$LAB_HOME"/cloud-setup/okafka/okafka-0.8.lib
OKAFKA_JAR="$LAB_HOME"/cloud-setup/okafka/okafka-0.8.jar

# rename Lib to Jar
mv "$OKAFKA_LIB" "$OKAFKA_JAR"

# Install okafka library into Maven local repository.
mvn install:install-file -Dfile="$OKAFKA_JAR" -DgroupId=org.oracle.okafka -DartifactId=okafka -Dversion=0.8 -Dpackaging=jar

state_set_done OKAFKA_INSTALLED