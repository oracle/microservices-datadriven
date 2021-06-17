#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

echo un-install kafka...
kubectl delete -f ./kafka-all.yaml -n msdataworkshop

echo un-install mongodb...
kubectl delete -f mongodb-service.yaml -n msdataworkshop
kubectl delete -f mongodb-deployment.yaml -n msdataworkshop
kubectl delete -f mongodata-persistentvolumeclaim.yaml -n msdataworkshop

echo un-install postgres
kubectl delete -f postgres-service.yaml -n msdataworkshop
kubectl delete -f postgres-deployment.yaml -n msdataworkshop
kubectl delete -f postgres-storage.yaml -n msdataworkshop

