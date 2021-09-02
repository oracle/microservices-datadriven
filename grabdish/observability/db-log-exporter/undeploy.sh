#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

echo delete order deployment and service...

kubectl delete deployment db-log-exporter-orderpdb -n msdataworkshop
kubectl delete deployment db-log-exporter-inventorypdb -n msdataworkshop

kubectl delete service order -n msdataworkshop
