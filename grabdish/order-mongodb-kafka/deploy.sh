#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


# See docs/Deploy.md for details
k8s-deploy 'order-mongodb-kafka-deployment.yaml order-service.yaml'
