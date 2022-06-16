#!/bin/bash
## Copyright (c) 2022 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

kubectl delete service ingress-nginx-controller -n msdataworkshop
k8s-deploy 'frontend-helidon-deployment.yaml frontend-service-nodeport.yaml'
