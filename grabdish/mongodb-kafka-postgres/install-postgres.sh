#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

kubectl create -f postgres-configmap.yaml -n msdataworkshop
kubectl create -f postgres-storage.yaml -n msdataworkshop
kubectl create -f postgres-deployment.yaml -n msdataworkshop
kubectl create -f postgres-service.yaml -n msdataworkshop
kubectl get svc postgres

