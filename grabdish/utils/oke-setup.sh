#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Wait for provisioning
while ! state_done PROVISIONING_DONE; do
  echo "`date`: Waiting for terraform provisioning"
  sleep 10
done


# Get OKE OCID
while ! state_done OKE_OCID; do
  OKE_OCID=`oci ce cluster list --compartment-id "$(state_get COMPARTMENT_OCID)" --query "join(' ',data[*].id)" --raw-output`
  state_set OKE_OCID "$OKE_OCID"
done


# Setup Cluster Access
while ! state_done KUBECTL_DONE; do
  oci ce cluster create-kubeconfig --cluster-id "$(state_get OKE_OCID)"
  state_set_done KUBECTL_DONE
done


# Create SSL Certs
while ! state_done SSL_DONE; do
  mkdir -p $GRABDISH_HOME/tls
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $GRABDISH_HOME/tls/tls.key -out $GRABDISH_HOME/tls/tls.crt -subj "/CN=grabdish/O=grabdish"
  state_set_done SSL_DONE
done


# Create SSL Secret
while ! state_done OKE_NAMESPACE_DONE; do
  kubectl create ns msdataworkshop
  state_set_done OKE_NAMESPACE_DONE
done


# Create SSL Secret
while ! state_done SSL_SECRET_DONE; do
  kubectl create secret tls ssl-certificate-secret --key $GRABDISH_HOME/tls/tls.key --cert $GRABDISH_HOME/tls/tls.crt -n msdataworkshop
  state_set_done SSL_SECRET_DONE
done


# Install Jaeger
while ! state_done JAEGER_DONE; do
  kubectl create -f https://tinyurl.com/yc52x6q5 -n msdataworkshop
  state_set_done JAEGER_DONE
done


# Provision Load Balancer
while ! state_done LB_DONE; do
  kubectl create -f $GRABDISH_HOME/frontend-helidon/frontend-service.yaml -n msdataworkshop
  state_set_done LB_DONE
done


# Get JAEGER_QUERY_ADDRESS
while ! state_done JAEGER_QUERY_ADDRESS; do
  # JAEGER_IP=`kubectl get services jaeger-query -n msdataworkshop --template='{{(index .status.loadBalancer.ingress 0).ip}}'`
  JAEGER_IP=`kubectl get service jaeger-query -n msdataworkshop | awk '/jaeger-query/ {print $4}'`
  if [[ "$JAEGER_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    state_set JAEGER_QUERY_ADDRESS "https://$JAEGER_IP"
  else
    echo "Waiting for jaeger IP to be assigned"
    sleep 10
  fi
done


# Create Jaeger ConfigMap
while ! state_done JAEGER_CONFIG_MAP; do
  kubectl create -n msdataworkshop -f - <<!
{
   "apiVersion": "v1",
   "kind": "ConfigMap",
   "metadata": {
      "name": "jaegerqueryaddress"
   },
   "data": {
      "address": "${JAEGER_QUERY_ADDRESS}"
   }
}
!
  state_set_done JAEGER_CONFIG_MAP
done


state_set_done OKE_SETUP_DONE