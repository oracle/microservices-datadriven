#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates. 
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

if [ $# -eq 0 ]; then
    echo "You must supply the API key as an argument"
    exit 1
fi

curl http://localhost:9180/apisix/admin/routes \
  -H "X-API-KEY: $1" 