#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates. 
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

if [ $# -eq 0 ]; then
    echo "You must supply the API key as an argument"
    exit 1
fi

curl http://localhost:9180/apisix/admin/routes \
  -H "X-API-KEY: $1" \
  -X POST \
  -i \
  --data-binary @- << EOF
{
    "name": "accounts",
    "labels": { 
        "version": "1.0" 
    },
    "uri": "/api/v1/account*",
    "upstream": {
        "service_name": "application/account:spring",
        "type": "roundrobin",
        "discovery_type": "kubernetes"
    },
    "plugins": {
        "zipkin": {
            "disable": false,
            "endpoint": "http://jaegertracing-collector.observability.svc.cluster.local:9411/api/v2/spans",
            "sample_ratio": 1,
            "service_name": "APISIX"
        }
    }
}
EOF