#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Build all the images (no push) except frontend-helidon (requires Jaeger)
while ! state_done JAVA_BUILDS; do
  BUILDS="admin-helidon order-helidon supplier-helidon-se inventory-helidon inventory-helidon-se"
  for b in $BUILDS; do 
    cd $GRABDISH_HOME/$b
    time ./build.sh
  done
  state_set_done JAVA_BUILDS
done