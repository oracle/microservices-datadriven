#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply; then
  exit 1
fi


export GRABDISH_LOG


# Create SSL Certs
if ! test -f $MY_STATE/ssl_certs; then
  mkdir -p $MY_STATE/tls
  chmod 700 $MY_STATE/tls
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $MY_STATE/tls/tls.key -out $MY_STATE/tls/tls.crt -subj "/CN=grabdish/O=grabdish"
  touch $MY_STATE/ssl_certs
fi


# Create OKE Namespace
if ! test -f $MY_STATE/k8s_namespace; then
  kubectl create ns msdataworkshop
  touch $MY_STATE/k8s_namespace
fi


# Create SSL Secret
#if ! test -f $MY_STATE/ssl_secret; then
#  kubectl create secret tls ssl-certificate-secret --key $MY_STATE/tls/tls.key --cert $MY_STATE/tls/tls.crt -n msdataworkshop
#  touch $MY_STATE/ssl_secret
#fi


# Add NGINX Ingress Controller Repo to Helm
while ! test -f $MY_STATE/nginx_helm_repo; do
  if helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>$GRABDISH_LOG/nginx_repo_err; then
    helm repo update
    touch $MY_STATE/nginx_helm_repo
  else
    echo "Add NGINX to Helm Repo failed"
    cat $GRABDISH_LOG/nginx_repo_err
    exit 1
  fi
done


# Create SSL Secret
while ! test -f $MY_STATE/ssl_secret_ingress; do
  if kubectl create secret tls ssl-certificate-secret --key $MY_STATE/tls/tls.key --cert $MY_STATE/tls/tls.crt -n msdataworkshop; then
    touch $MY_STATE/ssl_secret_ingress
  else
    echo "Ingress SSL Secret creation failed"
    exit 1
  fi
done


# Provision Ingress Controller
while ! test -f $MY_STATE/nginx_ingress_setup; do
  if helm install ingress-nginx ingress-nginx/ingress-nginx --namespace msdataworkshop --values $GRABDISH_HOME/ingress/nginx/ingress-nginx-helm-values4oci.yaml 2>$GRABDISH_LOG/nginx_ingress_err; then
    touch $MY_STATE/nginx_ingress_setup
  else
    echo "Ingress Controller installation failed."
    cat $GRABDISH_LOG/nginx_ingress_err
    exit 1
  fi
done


# Create frontend load balancer
#if ! test -f $MY_STATE/frontend_lb; then
#  kubectl create -f $GRABDISH_HOME/frontend-helidon/frontend-service.yaml -n msdataworkshop
#  touch $MY_STATE/frontend_lb
#fi


# Install Jaeger
#if ! test -f $MY_STATE/jaeger; then
#  kubectl create -f https://tinyurl.com/yc52x6q5 -n msdataworkshop
#  touch $MY_STATE/jaeger
#fi


# Create UI password secret
if ! test -f $MY_STATE/ui_password_k8s_secret; then
   BASE64_UI_PASSWORD=`echo -n "$(get_secret $UI_PASSWORD_SECRET)" | base64`
   kubectl create -n msdataworkshop -f - <<!
   {
      "apiVersion": "v1",
      "kind": "Secret",
      "metadata": {
         "name": "frontendadmin"
      },
      "data": {
         "password": "${BASE64_UI_PASSWORD}"
      }
   }
!
  touch $MY_STATE/ui_password_k8s_secret
fi


# Collect DB password and create secret
if ! test -f $MY_STATE/db_password_k8s_secret; then
   BASE64_DB_PASSWORD=`echo -n "$(get_secret $DB_PASSWORD_SECRET)" | base64`
   kubectl apply -n msdataworkshop -f - <<!
   {
      "apiVersion": "v1",
      "kind": "Secret",
      "metadata": {
         "name": "dbuser"
      },
      "data": {
         "dbpassword": "${BASE64_DB_PASSWORD}"
      }
   }
!
  touch $MY_STATE/db_password_k8s_secret
fi


# Done
touch $OUTPUT_FILE