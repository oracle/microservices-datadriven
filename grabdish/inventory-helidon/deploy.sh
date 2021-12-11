#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


SCRIPT_DIR=$(dirname $0)

export IS_SUGGESTIVE_SALE_ENABLED=${1-false}

k8s-deploy "$SCRIPT_DIR" "$K8S_NAMESPACE" 'inventory-helidon-deployment.yaml inventory-service.yaml' 'DOCKER_REGISTRY INVENTORY_DB_ALIAST IS_SUGGESTIVE_SALE_ENABLED'
