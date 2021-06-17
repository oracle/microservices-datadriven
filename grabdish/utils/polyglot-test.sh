#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Deploy each inventory service and perform functional test
#SERVICES="inventory-python inventory-nodejs inventory-dotnet inventory-go inventory-helidon-se"
SERVICES="inventory-dotnet inventory-go inventory-python inventory-nodejs inventory-helidon-se"
ORDER_ID=66

cd $GRABDISH_HOME/inventory-helidon
./undeploy.sh

for s in $SERVICES; do
  echo "Testing $s"
  cd $GRABDISH_HOME/$s
  ./deploy.sh

  while test 1 -gt `kubectl get pods -n msdataworkshop | grep "${s}" | grep "1/1" | wc -l`; do
    echo "Waiting for pod to start..."
    sleep 5
  done

  cd $GRABDISH_HOME
  ORDER_ID=$(($ORDER_ID + 100))
  utils/func-test.sh "Polyglot $s" $ORDER_ID $s
  
  cd $GRABDISH_HOME/$s
  ./undeploy.sh
done

cd $GRABDISH_HOME/inventory-helidon
./deploy.sh
