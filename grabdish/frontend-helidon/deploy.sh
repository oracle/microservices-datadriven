#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


SCRIPT_DIR=$(dirname $0)
export DOCKER_REGISTRY=$(state_get DOCKER_REGISTRY)

echo create frontend deployment and service...
export CURRENTTIME=$( date '+%F_%H:%M:%S' )
echo CURRENTTIME is $CURRENTTIME  ...this will be appended to generated deployment yaml
echo DOCKER_REGISTRY is $DOCKER_REGISTRY

cp frontend-helidon-deployment.yaml frontend-helidon-deployment-$CURRENTTIME.yaml

#may hit sed incompat issue with mac
sed_i "s|%DOCKER_REGISTRY%|${DOCKER_REGISTRY}|g" frontend-helidon-deployment-$CURRENTTIME.yaml

if [ -z "$1" ]; then
    kubectl apply -f $SCRIPT_DIR/frontend-helidon-deployment-$CURRENTTIME.yaml -n msdataworkshop
else
    kubectl apply -f <(istioctl kube-inject -f $SCRIPT_DIR/frontend-helidon-deployment-$CURRENTTIME.yaml) -n msdataworkshop
fi

# Provision Frontend Service
kubectl create -f $SCRIPT_DIR/frontend-service.yaml -n msdataworkshop

# Provision Frontend Ingress
kubectl create -f $SCRIPT_DIR/frontend-ingress.yaml -n msdataworkshop

# Provision Frontend Service
#while ! state_done LB; do
#  if kubectl create -f $GRABDISH_HOME/frontend-helidon/frontend-service.yaml -n msdataworkshop; then
#    state_set_done LB
#  else
#    echo "Frontend Service creation failed.  Retrying..."
#    sleep 10
#  fi
#done

# Provision Frontend Ingress
#while ! state_done FRONTEND_INGRESS; do
#  if kubectl create -f $GRABDISH_HOME/ingress/nginx/grabdish-frontend-ingress.yaml -n msdataworkshop; then
#    state_set_done FRONTEND_INGRESS
#  else
#    echo "Frontend Ingress creation failed.  Retrying..."
#    sleep 10
#  fi
#done


