#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
  exit 1
fi


# Install Graal
if ! test -d ~/graalvm-ce-java11-20.1.0; then
  cd $MY_STATE
  OS_NAME=`uname`
  curl -sL https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-20.1.0/graalvm-ce-java11-${OS_NAME}-amd64-20.1.0.tar.gz | tar xz
  mv graalvm-ce-java11-20.1.0 ~/
fi

# Java Home
if test -d ~/graalvm-ce-java11-20.1.0/Contents/Home/bin; then
  # We are on Mac doing local dev
  ~/graalvm-ce-java11-20.1.0/Contents/Home/bin/gu install native-image
  JAVA_HOME=~/graalvm-ce-java11-20.1.0/Contents/Home;
else
  # Assume linux
  ~/graalvm-ce-java11-20.1.0/bin/gu install native-image
  JAVA_HOME=~/graalvm-ce-java11-20.1.0
fi


cat >$OUTPUT_FILE <<!
JAVA_HOME='$JAVA_HOME'
!