#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Source the state functions
source utils/state_functions.sh


# Setup Cluster Access
while ! state_done KUBECTL_DONE; do
  oci ce cluster create-kubeconfig --cluster-id "$(state_get OKE_OCID)"
  state_set_done KUBECTL_DONE
done


# Create SSL Certs
while ! state_done SSL_DONE; do
  mkdir -p $GRABDISH_HOME/tls
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $GRABDISH_HOME/tls/tls.key -out $GRABDISH_HOME/tls/tls.crt -subj "/CN=convergeddb/O=convergeddb"
  state_set_done SSL_DONE
done


# Create SSL Secret
while ! state_done "SSL_SECRET_DONE"; do
  kubectl create secret tls ssl-certificate-secret --key $GRABDISH_HOME/tls/tls.key --cert $GRABDISH_HOME/tls/tls.crt -n msdataworkshop
  state_set_done "SSL_SECRET_DONE"
done


# Install Jaegar
while ! state_done "JAEGAR_DONE"; do
  kubectl create -f https://tinyurl.com/yc52x6q5 -n msdataworkshop
  state_set_done "JAEGAR_DONE"
done


# Provision Load Balancer
while ! state_done "LB_DONE"; do
  kubectl create -f $GRABDISH_HOME/frontend-helidon/frontend-service.yaml -n msdataworkshop
  state_set_done "LB_DONE"
done


# OKE Setup Done
state_set_done "OKE_SETUP_DONE"