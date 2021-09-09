#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply-sh; then
  exit 1
fi


cd $MY_CODE/../..
export GRABDISH_HOME=$PWD
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
if ! test -f $MY_STATE/ssl_secret; then
  kubectl create secret tls ssl-certificate-secret --key $MY_STATE/tls/tls.key --cert $MY_STATE/tls/tls.crt -n msdataworkshop
  touch $MY_STATE/ssl_secret
fi


# Create frontend load balancer
if ! test -f $MY_STATE/frontend_lb; then
  kubectl create -f $GRABDISH_HOME/frontend-helidon/frontend-service.yaml -n msdataworkshop
  touch $MY_STATE/frontend_lb
fi


# Install Jaeger
if ! test -f $MY_STATE/jaeger; then
  kubectl create -f https://tinyurl.com/yc52x6q5 -n msdataworkshop
  touch $MY_STATE/jaeger
fi


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
   BASE64_DB_PASSWORD=`echo -n "$(get_secret DB_PASSWORD_SECRET)" | base64`
   kubectl create -n msdataworkshop -f - <<!
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