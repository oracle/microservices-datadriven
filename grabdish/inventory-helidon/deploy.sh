#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


SCRIPT_DIR=$(dirname $0)

export IS_SUGGESTIVE_SALE_ENABLED=${1-}

if [ -z "$IS_SUGGESTIVE_SALE_ENABLED" ]; then
    echo "No argument for IS_SUGGESTIVE_SALE_ENABLED, defaulting to false..."
  export IS_SUGGESTIVE_SALE_ENABLED=false
fi

k8s-deploy "$SCRIPT_DIR" "$K8S_NAMESPACE" 'inventory-helidon-deployment.yaml inventory-service.yaml' 'DOCKER_REGISTRY INVENTORY_DB_ALIAS'
