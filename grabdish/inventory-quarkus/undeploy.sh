#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

echo delete inventory-quarkus deployment and service...

# Delete inventory-quarkus Service
kubectl delete service inventory -n msdataworkshop

# Delete inventory-quarkus Deployment
kubectl delete deployment inventory-quarkus -n msdataworkshop