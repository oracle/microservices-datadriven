#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Add NGINX Ingress Controller Repo to Helm
while ! state_done NGINX_HELM_REPO; do
  if helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>$GRABDISH_LOG/nginx_repo_err; then
    helm repo update
    state_set_done NGINX_HELM_REPO
  else
    echo "Add NGINX to Helm Repo failed.  Retrying..."
    cat $GRABDISH_LOG/nginx_repo_err
    sleep 10
  fi
done

# Create Ingress NGINX Namespace
#while ! state_done NGINX_NAMESPACE; do
#  if kubectl create -f $GRABDISH_HOME/ingress/nginx/ingress-nginx-namespace.yaml 2>$GRABDISH_LOG/nginx_ingress_ns_err; then
#    state_set_done NGINX_NAMESPACE
#  else
#    echo "Failed to create Ingress NGINX namespace.  Retrying..."
#    sleep 5
#  fi
#done

# Create SSL Secret
while ! state_done SSL_SECRET_INGRESS; do
  if kubectl create secret tls ssl-certificate-secret --key $GRABDISH_HOME/tls/tls.key --cert $GRABDISH_HOME/tls/tls.crt -n msdataworkshop; then
    state_set_done SSL_SECRET_INGRESS
  else
    echo "Ingress SSL Secret creation failed.  Retrying..."
    sleep 5
  fi
done

# Provision Ingress Controller
while ! state_done NGINX_INGRESS_SETUP; do
  if helm install ingress-nginx ingress-nginx/ingress-nginx --namespace msdataworkshop --values $GRABDISH_HOME/ingress/nginx/ingress-nginx-helm-values4oci.yaml 2>$GRABDISH_LOG/nginx_ingress_err; then
    state_set_done NGINX_INGRESS_SETUP
  else
    echo "Ingress Controller installation failed.  Retrying..."
    cat $GRABDISH_LOG/nginx_ingress_err
    sleep 10
  fi
done


# Get LB ENDPOINT
#ip_pattern='^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$'
#while ! state_done NGINX_LB_ENDPOINT; do
#  NGINX_LB_ENDPOINT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o "go-template={{range .status.loadBalancer.ingress}}{{or .ip .hostname}}{{end}}")
#  if [[ ! $NGINX_LB_ENDPOINT == $ip_pattern ]]
#    state_set NGINX_LB_ENDPOINT "$NGINX_LB_ENDPOINT"
#  else
#    echo "Invalid IP [$NGINX_LB_ENDPOINT]"    
#    exit
#  fi
#done

state_set_done NGINX_INGRESS_SETUP_DONE