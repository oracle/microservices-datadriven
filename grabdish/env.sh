#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if ! (return 0 2>/dev/null); then
  echo "ERROR: Usage 'source env.sh'"
  exit
fi

# Set GRABDISH_HOME
export GRABDISH_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $GRABDISH_HOME
echo "GRABDISH_HOME: $GRABDISH_HOME"

# Java Home
export JAVA_HOME=~/graalvm-ce-java11-20.1.0
export PATH=$JAVA_HOME/bin:$PATH

# Log directory
export GRABDISH_LOG=$GRABDISH_HOME/log
mkdir -p $GRABDISH_LOG

# Source the state functions
source $GRABDISH_HOME/utils/state-functions.sh

# SHORTCUT ALIASES AND UTILS...
alias k='kubectl'
alias kt='kubectl --insecure-skip-tls-verify'
alias pods='kubectl get po --all-namespaces'
alias services='kubectl get services --all-namespaces'
alias configmaps='kubectl get configmaps --all-namespaces'
alias gateways='kubectl get gateways --all-namespaces'
alias secrets='kubectl get secrets --all-namespaces'
alias ingresssecret='kubectl get secrets --all-namespaces | grep istio-ingressgateway-certs'
alias virtualservices='kubectl get virtualservices --all-namespaces'
alias deployments='kubectl get deployments --all-namespaces'

export PATH=$PATH:$GRABDISH_HOME/utils/