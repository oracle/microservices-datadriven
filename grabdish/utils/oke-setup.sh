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
while ! state_done PROVISIONING; do
  echo "`date`: Waiting for terraform provisioning"
  sleep 10
done


# Get OKE OCID
while ! state_done OKE_OCID; do
  OKE_OCID=`oci ce cluster list --compartment-id "$(state_get COMPARTMENT_OCID)" --query "join(' ',data[?"'"lifecycle-state"'"=='ACTIVE'].id)" --raw-output`
  state_set OKE_OCID "$OKE_OCID"
  # Wait for OKE to warm up
done


# Setup Cluster Access
while ! state_done KUBECTL; do
  oci ce cluster create-kubeconfig --cluster-id "$(state_get OKE_OCID)" --file $HOME/.kube/config --region "$(state_get REGION)" --token-version 2.0.0

  cluster_id="$(state_get OKE_OCID)"
  kubectl config set-credentials "user-${cluster_id:(-11)}" --exec-command="kube_token_cache.sh" \
  --exec-arg="ce" \
  --exec-arg="cluster" \
  --exec-arg="generate-token" \
  --exec-arg="--cluster-id" \
  --exec-arg="${cluster_id}" \
  --exec-arg="--region" \
  --exec-arg="$(state_get REGION)"

  state_set_done KUBECTL
done


# Wait for OKE nodes to become redy
while true; do
  READY_NODES=`kubectl get nodes | grep Ready | wc -l` || echo 'Ignoring any Error'
  if test "$READY_NODES" -ge 3; then
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


# Wait for Order User (avoid concurrent kubectl)
while ! state_done ORDER_USER; do
  echo "`date`: Waiting for ORDER_USER"
  sleep 2
done


# Create Ingress NGINX Namespace
while ! state_done NGINX_NAMESPACE; do
  if kubectl create -f $GRABDISH_HOME/ingresscontrollers/nginx/ingress-nginx-namespace.yaml 2>$GRABDISH_LOG/nginx_ingress_ns_err; then
    state_set_done NGINX_NAMESPACE
  else
    echo "Failed to create Ingress NGINX namespace.  Retrying..."
    sleep 10
  fi
done


# Create SSL Secret
while ! state_done SSL_SECRET_INGRESS; do
  if kubectl create secret tls ssl-certificate-secret --key $GRABDISH_HOME/tls/tls.key --cert $GRABDISH_HOME/tls/tls.crt -n ingress-nginx; then
    state_set_done SSL_SECRET_INGRESS
  else
    echo "Ingress SSL Secret creation failed.  Retrying..."
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


# Provision Ingress Controller
while ! state_done INGRESSCTLR; do
  if kubectl create -f $GRABDISH_HOME/ingresscontrollers/nginx/ingress-nginx-controller.yaml 2>$GRABDISH_LOG/nginx_ingress_err; then
    state_set_done INGRESSCTLR
  else
    echo "Ingress Controller installation failed.  Retrying..."
    cat $GRABDISH_LOG/nginx_ingress_err
    sleep 10
  fi
done

echo "Waiting for ingress controller creation to complete"
sleep 90

# Provision Frontend Ingress
while ! state_done FRONTEND_INGRESS; do
  if kubectl create -f $GRABDISH_HOME/ingresscontrollers/nginx/grabdish-frontend-ingress.yaml -n msdataworkshop; then
    state_set_done FRONTEND_INGRESS
  else
    echo "Frontend Ingress creation failed.  Retrying..."
    sleep 10
  fi
done



# Provision Frontend Service
while ! state_done LB; do
  if kubectl create -f $GRABDISH_HOME/frontend-helidon/frontend-service.yaml -n msdataworkshop; then
    state_set_done LB
  else
    echo "Frontend Service creation failed.  Retrying..."
    sleep 10
  fi
done


# Install Jaeger
while ! state_done JAEGER; do
  if kubectl create -f $GRABDISH_HOME/observability/jaeger/jaeger-all-in-one-template.yml -n msdataworkshop 2>$GRABDISH_LOG/jaeger_err; then
    state_set_done JAEGER
  else
    echo "Jaeger installation failed.  Retrying..."
    cat $GRABDISH_LOG/jaeger_err
    sleep 10
  fi
done

# Provision Jaeger Ingress
while ! state_done JAEGER_INGRESS; do
  if kubectl create -f $GRABDISH_HOME/ingresscontrollers/nginx/grabdish-jaeger-ingress.yaml -n msdataworkshop; then
    state_set_done JAEGER_INGRESS
  else
    echo "Jaeger Ingress creation failed.  Retrying..."
    sleep 10
  fi
done


state_set_done OKE_SETUP
