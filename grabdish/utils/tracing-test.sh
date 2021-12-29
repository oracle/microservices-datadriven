#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Get JAEGER_URL (way have to retry)
RETRIES=0
while ! state_done JAEGER_URL; do
  #IP=`kubectl get services -n msdataworkshop | awk '/jaeger-query/ {print $4}'`
  IP=$(kubectl -n msdataworkshop get svc ingress-nginx-controller -o "go-template={{range .status.loadBalancer.ingress}}{{or .ip .hostname}}{{end}}")
  if [[ "$IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    state_set JAEGER_URL "https://$IP/jaeger/"
  else
    RETRIES=$(($RETRIES + 1))
    if test $RETRIES -gt 10; then
      echo "ERROR: Failed to get JAEGER_URL"
      exit
    fi
    sleep 5
  fi
done

# Is the UI available?
if wget -qO- --no-check-certificate "$(state_get JAEGER_URL)" | grep 'JAEGER_VERSION' >/dev/null; then
  echo "TEST_LOG: Jaeger UI Available"
else
  echo "TEST_LOG_FAILED: Jaeger UI Unavailable"
  exit
fi

