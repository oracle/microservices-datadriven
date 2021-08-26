#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Dependencies:
#   kubectl
#   openssl
#   GRABDISH_HOME (set)
#   
# INPUTS:
#   Parameters:
#     $1  Home directory (to store state, inputs and outputs)
#
# OUTPUTS:
#   $1/output.env (in home directory)
#   <empty indicates done>

# Fail on error
set -e


# Check the home folder
MY_HOME="$1"
if ! test -d "$MY_HOME"; then
  echo "ERROR: The home folder does not exist"
  exit
fi


# Check home is set
if test -z "$GRABDISH_HOME"; then
  echo "ERROR: This script requires GRABDISH_HOME to be set"
  exit
fi


# Check if we are already done
if test -f $MY_HOME/output.env; then
  exit
fi


# Create SSL Certs
mkdir -p $MY_HOME/tls
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $MY_HOME/tls/tls.key -out $MY_HOME/tls/tls.crt -subj "/CN=grabdish/O=grabdish"


# Create OKE Namespace
kubectl create ns msdataworkshop


# Create SSL Secret
kubectl create secret tls ssl-certificate-secret --key $MY_HOME/tls/tls.key --cert $MY_HOME/tls/tls.crt -n msdataworkshop


# Create frontend load balancer
kubectl create -f $GRABDISH_HOME/frontend-helidon/frontend-service.yaml -n msdataworkshop; then


# Install Jaeger
kubectl create -f https://tinyurl.com/yc52x6q5 -n msdataworkshop; then


# Done
touch $MY_HOME/output.env