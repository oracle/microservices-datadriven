#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


echo deleting all secrets in msdataworkshop namespace...
kubectl delete --all secrets --namespace=msdataworkshop

echo deleting generated-yaml dir...
rm -rf generated-yaml

echo deleting wallet dirs...
rm -rf orderdbwallet
rm -rf inventorydbwallet
rm -rf tls