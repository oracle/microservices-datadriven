#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

echo delete order deployment and service...

kubectl delete deployment order-mongodb-kafka -n msdataworkshop

kubectl delete service order -n msdataworkshop
