#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Deploy the ingress object
cd $GRABDISH_HOME/order-helidon; 
kubectl apply -f ext-order-ingress.yaml -n msdataworkshop

# Install k6
cd $GRABDISH_HOME/k6; 
if ! test -f k6; then
  wget https://github.com/loadimpact/k6/releases/download/v0.27.0/k6-v0.27.0-linux64.tar.gz; 
  tar -xzf k6-v0.27.0-linux64.tar.gz; 
  ln k6-v0.27.0-linux64/k6 k6
fi

# Get LB (may have to retry)
RETRIES=0
while ! state_done EXT_ORDER_IP; do
  IP=$(kubectl -n msdataworkshop get svc ingress-nginx-controller -o "go-template={{range .status.loadBalancer.ingress}}{{or .ip .hostname}}{{end}}")
  if [[ "$IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    state_set EXT_ORDER_IP "$IP"
  else
    RETRIES=$(($RETRIES + 1))
    echo "Waiting for EXT_ORDER IP"
    if test $RETRIES -gt 24; then
      echo "ERROR: Failed to get EXT_ORDER_IP"
      exit
    fi
    sleep 5
  fi
done

for app_scale in {1..3}; do
    if test $app_scale -gt 1; then
        # Scale app to n
        echo "Scaling order-helidon apps to $app_scale"
        kubectl scale deployment.apps/order-helidon --replicas=$app_scale -n msdataworkshop

        PODS=0
        echo "Waiting for order-helidon pods to start"
        while test $PODS -lt $app_scale; do
            sleep 5
            PODS=`kubectl get pods -n msdataworkshop | grep order-helidon | grep "1/1" | wc -l`
        done
    fi

    # Execute load test
    cd $GRABDISH_HOME/k6; 
    export LB=$(state_get EXT_ORDER_IP)
    echo "Starting Load test scale App $app_scale DB 1"
    echo "TEST_LOG: Scale App $app_scale DB 1: `./test.sh | grep http_reqs | awk '{print $3}'`"
done

# Scale to 3/2
echo "Scaling DB core count to 2"
oci db autonomous-database update --autonomous-database-id $(state_get DB1_OCID) --cpu-core-count 2

echo "Waiting for scaling to complete"
sleep 90

# Execute 3/2 Load Test
cd $GRABDISH_HOME/k6; 
export LB=$(state_get EXT_ORDER_IP)
echo "Starting Load test scale App 3 DB 2"
echo "TEST_LOG: Scale App 3 DB 2: `./test.sh | grep http_reqs | awk '{print $3}'`"

# Scale down to 1/1
kubectl scale deployment.apps/order-helidon --replicas=1 -n msdataworkshop
oci db autonomous-database update --autonomous-database-id $(state_get DB1_OCID) --cpu-core-count 1
