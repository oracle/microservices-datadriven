#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Install Jaeger
while ! state_done JAEGER_SETUP; do
  if kubectl create -f $GRABDISH_HOME/observability/jaeger/jaeger-all-in-one-template.yml -n msdataworkshop 2>$GRABDISH_LOG/jaeger_err; then
    state_set_done JAEGER_SETUP
  else
    echo "Jaeger installation failed.  Retrying..."
    cat $GRABDISH_LOG/jaeger_err
    sleep 10
  fi
done

# Provision Jaeger Ingress
while ! state_done JAEGER_INGRESS; do
  if kubectl create -f $GRABDISH_HOME/observability/jaeger/jaeger-ingress.yaml -n msdataworkshop; then
    state_set_done JAEGER_INGRESS
  else
    echo "Jaeger Ingress creation failed.  Retrying..."
    sleep 5
  fi
done

state_set_done JAEGER_SETUP_DONE