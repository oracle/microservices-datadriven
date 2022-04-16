#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

echo delete inventory-micronaut-native-image deployment and service...

kubectl delete service inventory -n msdataworkshop

kubectl delete deployment inventory-micronaut-native-image -n msdataworkshop