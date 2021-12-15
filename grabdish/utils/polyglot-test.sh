#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Deploy each inventory service and perform functional test
#SERVICES="inventory-python inventory-nodejs inventory-dotnet inventory-go inventory-helidon-se"
#SERVICES="inventory-dotnet inventory-go inventory-python inventory-nodejs inventory-helidon-se inventory-plsql inventory-springboot inventory-micronaut inventory-quarkus"
SERVICES="$LAB3_NON_JAVA_BUILDS $LAB3_JAVA_BUILDS"
ORDER_ID=66

cd $GRABDISH_HOME/inventory-helidon
./undeploy.sh

# Wait for Pod to stop
while test 0 -lt `kubectl get pods -n msdataworkshop | egrep 'inventory-' | wc -l`; do
  echo "Waiting for pod to stop..."
  sleep 5
done

for s in $SERVICES; do
  echo "Testing $s"
  cd $GRABDISH_HOME/$s
  ./deploy.sh

  if test "$s" != 'inventory-plsql'; then # PL/SQL service is not deployed in k8s and starts immediately
    while test 1 -gt `kubectl get pods -n msdataworkshop | grep "${s}" | grep "1/1" | wc -l`; do
      echo "Waiting for pod to start..."
      sleep 5
    done
  fi

  cd $GRABDISH_HOME
  ORDER_ID=$(($ORDER_ID + 100))
  utils/func-test.sh "Polyglot $s" $ORDER_ID $s
  
  cd $GRABDISH_HOME/$s
  ./undeploy.sh

  # Wait for Pod to stop
  while test 0 -lt `kubectl get pods -n msdataworkshop | egrep 'inventory-' | wc -l`; do
    echo "Waiting for pod to stop..."
    sleep 5
  done

done

cd $GRABDISH_HOME/inventory-helidon
./deploy.sh
