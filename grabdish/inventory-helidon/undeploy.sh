#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

echo delete inventory-helidon deployment and service...

# Delete inventory-helidon Service
kubectl delete service inventory -n msdataworkshop

# Delete inventory-helidon Deployment
kubectl delete deployment inventory-helidon -n msdataworkshop