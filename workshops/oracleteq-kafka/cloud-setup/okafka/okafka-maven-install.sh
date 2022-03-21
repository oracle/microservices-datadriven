#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# PATH to OKafka Library
OKAFKA_LIB="$LAB_HOME"/cloud-setup/okafka/okafka-0.8.jar

# Install okafka library into Maven local repository.
mvn install:install-file -Dfile="$OKAFKA_LIB" -DgroupId=org.oracle.okafka -DartifactId=okafka -Dversion=0.8 -Dpackaging=jar

state_set_done OKAFKA_INSTALLED