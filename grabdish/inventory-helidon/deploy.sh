#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

export IS_SUGGESTIVE_SALE_ENABLED=$1
IS_SUGGESTIVE_SALE_ENABLED=${IS_SUGGESTIVE_SALE_ENABLED-false}

# See docs/Deploy.md for details
k8s-deploy 'inventory-helidon-deployment.yaml inventory-service.yaml'
