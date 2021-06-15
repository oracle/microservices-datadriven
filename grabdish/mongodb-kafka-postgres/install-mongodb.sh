#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

kubectl create -f mongodata-persistentvolumeclaim.yaml -n msdataworkshop
kubectl create -f mongodb-deployment.yaml -n msdataworkshop
kubectl create -f mongodb-service.yaml -n msdataworkshop
