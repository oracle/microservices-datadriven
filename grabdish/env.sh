#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if ! (return 0 2>/dev/null); then
  echo "ERROR: Usage 'source env.sh'"
  exit
fi

# POSIX compliant find and replace
function sed_i(){
  local OP="$1"
  local FILE="$2"
  sed -e "$OP" "$FILE" >"/tmp/$FILE"
  mv -- "/tmp/$FILE" "$FILE"
}
export -f sed_i

# Set GRABDISH_HOME
export GRABDISH_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $GRABDISH_HOME
echo "GRABDISH_HOME: $GRABDISH_HOME"

# Java Home
if test -d ~/graalvm-ce-java11-20.1.0/Contents/Home/bin; then
  # We are on Mac doing local dev
  export JAVA_HOME=~/graalvm-ce-java11-20.1.0/Contents/Home;
else
  # Assume linux
  export JAVA_HOME=~/graalvm-ce-java11-20.1.0
fi
export PATH=$JAVA_HOME/bin:$PATH

# State directory
if test -d ~/grabdish-state; then
  export GRABDISH_STATE_HOME=~/grabdish-state
else
  export GRABDISH_STATE_HOME=$GRABDISH_HOME
fi

# Log directory
export GRABDISH_LOG=$GRABDISH_STATE_HOME/log
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
alias servicemonitors='kubectl get servicemonitors --all-namespaces'
alias configmaps='kubectl get configmaps --all-namespaces'
alias msdataworkshop='echo deployments... ; deployments|grep msdataworkshop ; echo pods... ; pods|grep msdataworkshop ; echo services... ; services | grep msdataworkshop ; echo secrets... ; secrets|grep msdataworkshop ; echo "other shortcut commands... most can take partial podname as argument, such as [logpod front] or [deletepod order]...  pods  services secrets deployments "'

export PATH=$PATH:$GRABDISH_HOME/utils/
