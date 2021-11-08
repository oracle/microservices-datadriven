#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

echo delete inventory-micronaut deployment and service...

# Delete inventory-micronaut Service
kubectl delete service inventory -n msdataworkshop

# Delete inventory-micronaut Deployment
kubectl delete deployment inventory-micronaut -n msdataworkshop