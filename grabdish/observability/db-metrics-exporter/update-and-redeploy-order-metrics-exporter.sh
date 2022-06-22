#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

echo delete previous deployment so that deployment is reapplied/deployed after configmap changes for exporter are made...
kubectl delete deployment db-metrics-exporter-orderpdb -n msdataworkshop

./deploy-order-metrics-exporter.sh

