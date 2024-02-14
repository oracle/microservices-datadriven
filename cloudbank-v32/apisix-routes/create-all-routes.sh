#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

if [ $# -eq 0 ]; then
    echo "You must supply the API key as an argument"
    exit 1
fi

source ./create-accounts-route.sh $1
source ./create-creditscore-route.sh $1
source ./create-customer-route.sh $1
source ./create-testrunner-route.sh $1
source ./create-transfer-route.sh $1