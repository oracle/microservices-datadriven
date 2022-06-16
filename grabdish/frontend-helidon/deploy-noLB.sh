#!/bin/bash
## Copyright (c) 2022 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

kubectl delete service ingress-nginx-controller -n msdataworkshop
kubectl apply -f frontend-helidon-deployment.yaml -n msdataworkshop
kubectl apply -f frontend-service-nodeport.yaml -n msdataworkshop
