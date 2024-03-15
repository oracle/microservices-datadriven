#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates. 
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

if [ $# -eq 0 ]; then
    echo "You must supply the API key as an argument"
    exit 1
fi

curl http://localhost:9180/apisix/admin/routes/1000 \
  -H "X-API-KEY: $1" \
  -X PUT \
  -i \
  --data-binary @- << EOF
{
    "name": "accounts",
    "labels": { 
        "version": "1.0" 
    },
    "desc": "ACCOUNT Service",
    "uri": "/api/v1/account*",
    "methods": [
      "GET",
      "POST",
      "PUT",
      "DELETE",
      "OPTIONS",
      "HEAD"
    ],
    "upstream": {
        "service_name": "ACCOUNT",
        "type": "roundrobin",
        "discovery_type": "eureka"
    },
    "plugins": {
        "opentelemetry": {
           "sampler": {
               "name": "always_on"
           }
        },
        "prometheus": {
            "prefer_name": true
        }
    }
}
EOF
