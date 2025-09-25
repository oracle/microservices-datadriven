---
title: Apache APISIX
sidebar_position: 1
---
## Apache APISIX

[Apache APISIX](https://apisix.apache.org) is an open source cloud native API platform that supports the full lifecycle of API management including publishing, traffic management, deployment strategies, and circuit breakers.

### Installing APISIX

Apache APISIX will be installed if the `apisix.enabled` is set to `true` in the `values.yaml` file. The default namespace for Apache APISIX is `apisix`.

### Accessing Apache APISIX

Oracle Backend for Microservices and AI deploys the Apache APISIX Gateway and Dashboard in the `apisix` namespace by default. The gateway is exposed via an external load balancer and an ingress controller.

To access the Apache APISIX APIs, use kubectl port-forward to create a secure channel to `service/apisix-admin`. Run the following command to establish the secure tunnel (replace the example namespace `obaas-dev` with the namespace where APISIX is deployed):

```shell
kubectl port-forward -n obaas-dev svc/apisix-admin 9180
```

### Retrieving admin key

To access the APISIX APIs, you need the admin key. Retrieve it with the following command (replace the example namespace `obaas-dev` with the namespace where APISIX is deployed):

```shell
export admin_key=$(kubectl -n obaas-dev get configmap apisix -o yaml | yq '.data."config.yaml"' | yq '.deployment.admin.admin_key[] | select(.name == "admin") | .key')
```

Test the admin key by running a simple curl command; it should return the list of configured routes.

```shell
curl http://127.0.0.1:9180/apisix/admin/routes -H "X-API-key: $admin_key" -X GET
```
