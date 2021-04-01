#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


echo deleting secrets in msdataworkshop namespace...
kubectl delete secret atp-demo-binding-inventory --namespace=msdataworkshop
kubectl delete secret atp-demo-binding-order --namespace=msdataworkshop


echo deleting generated-yaml dir...
rm -rf generated-yaml

echo deleting wallet dir...
rm -rf wallet