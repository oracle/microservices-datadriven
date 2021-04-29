#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Create SSL Certs
while ! state_done SSL; do
  mkdir -p $GRABDISH_HOME/tls
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $GRABDISH_HOME/tls/tls.key -out $GRABDISH_HOME/tls/tls.crt -subj "/CN=grabdish/O=grabdish"
  state_set_done SSL
done


# Wait for provisioning
if [[ $(state_get RUN_TYPE) != 3 ]]; then
while ! state_done PROVISIONING; do
  echo "`date`: Waiting for terraform provisioning"
  sleep 10
done 
else
echo "`date`: OCI resources have been already created."
fi


# Get OKE OCID
while ! state_done OKE_OCID; do
  OKE_OCID=`oci ce cluster list --compartment-id "$(state_get COMPARTMENT_OCID)" --query "join(' ',data[*].id)" --raw-output`
  state_set OKE_OCID "$OKE_OCID"
  # Wait for OKE to warm up
done


# Setup Cluster Access
while ! state_done KUBECTL; do
  oci ce cluster create-kubeconfig --cluster-id "$(state_get OKE_OCID)"
  state_set_done KUBECTL
done


# Wait for OKE nodes to become redy
while true; do
  READY_NODES=`kubectl get nodes | grep Ready | wc -l` || echo 'Ignoring any Error'
  if test "$READY_NODES" -eq 3; then
    echo "3 OKE nodes are ready"
    break
  fi
  echo "Waiting for OKE nodes to become ready"
  sleep 10
done


# Create OKE Namespace
while ! state_done OKE_NAMESPACE; do
  if kubectl create ns msdataworkshop; then
    state_set_done OKE_NAMESPACE
  else
    echo "Failed to create namespace.  Retrying..."
    sleep 10
  fi
done


# Create SSL Secret
while ! state_done SSL_SECRET; do
  if kubectl create secret tls ssl-certificate-secret --key $GRABDISH_HOME/tls/tls.key --cert $GRABDISH_HOME/tls/tls.crt -n msdataworkshop; then
    state_set_done SSL_SECRET
  else
    echo "SSL Secret creation failed.  Retrying..."
    sleep 10
  fi
done


# Provision Load Balancer
while ! state_done LB; do
  if kubectl create -f $GRABDISH_HOME/frontend-helidon/frontend-service.yaml -n msdataworkshop; then
    state_set_done LB
  else
    echo "Load Balancer creation failed.  Retrying..."
    sleep 10
  fi
done


# Install Jaeger
while ! state_done JAEGER; do
  if kubectl create -f https://tinyurl.com/yc52x6q5 -n msdataworkshop 2>$GRABDISH_LOG/jaeger_err; then
    state_set_done JAEGER
  else
    echo "Jaeger installation failed.  Retrying..."
    cat $GRABDISH_LOG/jaeger_err
    sleep 10
  fi
done


state_set_done OKE_SETUP