#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


echo delete frontend OAM Component and ApplicationConfiguration

kubectl delete applicationconfiguration inventory-nodejs-appconf -n msdataworkshop
kubectl delete component inventory-nodejs-component -n msdataworkshop
