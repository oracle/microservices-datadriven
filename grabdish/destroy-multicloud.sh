#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# The following uninstall of Verrazzano is taken directly from https://verrazzano.io/docs/setup/quickstart/

echo Deleting the Verrazzano custom resource....
kubectl delete verrazzano example-verrazzano

echo Set verrazzano-managed=false istio-injection=disabled ...
kubectl label namespace msdataworkshop verrazzano-managed=false istio-injection=disabled --overwrite

echo Viewing the uninstall logs...
kubectl logs -f $(kubectl get pod -l job-name=uninstall-example-verrazzano -o jsonpath="{.items[0].metadata.name}")