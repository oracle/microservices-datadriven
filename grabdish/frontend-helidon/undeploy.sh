#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


SCRIPT_DIR=$(dirname $0)
echo delete frontend deployment and service...

# Delete Frontend Ingress
kubectl delete -f $SCRIPT_DIR/frontend-ingress.yaml -n msdataworkshop

# Delete Frontend Service
kubectl delete -f $SCRIPT_DIR/frontend-service.yaml -n msdataworkshop


kubectl delete deployment frontend-helidon -n msdataworkshop