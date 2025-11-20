---
title: Apache APISIX
sidebar_position: 1
---
## Apache APISIX

[Apache APISIX](https://apisix.apache.org) is an open-source cloud-native API gateway that provides rich traffic management capabilities including load balancing, dynamic upstream, canary release, circuit breaking, authentication, observability, and more. It serves as the primary API gateway for Oracle Backend for Microservices and AI, routing external traffic to your microservices.

### Overview

Apache APISIX offers:
- **Dynamic Routing**: Configure routes in real-time without restarting Apache APISIX
- **Load Balancing**: Multiple load balancing algorithms including round-robin, consistent hashing, and weighted round-robin
- **Authentication**: Support for multiple authentication methods including API keys, JWT, OAuth2, and more
- **Rate Limiting**: Protect your services from overload with flexible rate limiting policies
- **Circuit Breaking**: Prevent cascading failures with automatic circuit breaker functionality
- **Observability**: Built-in support for metrics, logging, and tracing
- **Plugin Ecosystem**: Extensive [plugin system](https://apisix.apache.org/docs/apisix/plugins/batch-requests/) for extending functionality

---

## Table of Contents

- [Installing APISIX](#installing-apisix)
- [Prerequisites and Assumptions](#prerequisites-and-assumptions)
- [Accessing Apache APISIX](#accessing-apache-apisix)
  - [Port Forwarding to Admin API](#port-forwarding-to-admin-api)
  - [Retrieving the Admin Key](#retrieving-the-admin-key)
  - [Retrieving the Gateway IP](#retrieving-the-gateway-ip)
- [Working with APISIX REST API](#working-with-apisix-rest-api)
  - [Creating an Upstream](#creating-an-upstream)
  - [Creating a Route](#creating-a-route)
  - [Testing the Route](#testing-the-route)
  - [Updating a Route](#updating-a-route)
  - [Deleting a Route](#deleting-a-route)
  - [Listing All Routes](#listing-all-routes)
  - [Creating a Service](#creating-a-service)
- [Common Operations](#common-operations)
  - [Enable Authentication on a Route](#enable-authentication-on-a-route)
  - [Enable Rate Limiting](#enable-rate-limiting)
  - [Configure Load Balancing](#configure-load-balancing)
  - [Enable OpenTelemetry Tracing](#enable-opentelemetry-tracing)
  - [Configure Health Checks](#configure-health-checks)
- [Managing SSL/TLS Certificates](#managing-ssltls-certificates)
- [Accessing APISIX Dashboard](#accessing-apisix-dashboard)
- [Troubleshooting](#troubleshooting)
  - [Debugging Routes](#debugging-routes)
- [Additional Resources](#additional-resources)

---

### Installing APISIX

Apache APISIX will be installed if the `apisix.enabled` is set to `true` in the `values.yaml` file. The default namespace for Apache APISIX is `apisix`.

**Key Components Installed:**
- **Apache APISIX Gateway**: The main Apache APISIX gateway that handles incoming traffic
- **APISIX Dashboard**: Web UI for managing routes, upstreams, and plugins
- **etcd**: Distributed key-value store used by APISIX for configuration storage

### Prerequisites and Assumptions

This guide makes the following assumptions:

- **Namespace**: All examples use `YOUR-NAMESPACE` as a placeholder. Replace this with your actual target namespace (e.g., `obaas-dev`, `production`, `my-app`, etc.).
- **APISIX Namespace**: All APISIX-related commands in this guide use `apisix` as the namespace where Apache APISIX is deployed. **If you installed APISIX into a different namespace**, replace `apisix` with your actual APISIX namespace in all commands (e.g., `-n apisix` becomes `-n your-apisix-namespace`). You can verify your APISIX namespace with:
  ```bash
  kubectl get pods -A | grep apisix
  ```
- **Kubectl Access**: You have kubectl configured and authenticated to your Kubernetes cluster with appropriate permissions.
- **Command-line Tools**: The following tools are installed and available:
  - `kubectl` - Kubernetes command-line tool
  - `curl` - For testing API endpoints
  - `jq` - JSON processor (optional, for formatting responses)
  - `yq` - YAML processor (optional, for retrieving admin key)
- **Port Forwarding**: Examples assume you have an active port-forward to the APISIX admin service.

### Accessing Apache APISIX

Oracle Backend for Microservices and AI deploys the Apache APISIX Gateway and Dashboard in the configured namespace (default: `apisix`). Apache APISIX is exposed via an external load balancer and an ingress controller for production traffic, while the admin API is accessed through port forwarding for management operations.

#### Port Forwarding to Admin API

To access the Apache APISIX Admin APIs, use kubectl port-forward to create a secure channel to the `apisix-admin` service:

```shell
kubectl port-forward -n apisix svc/apisix-admin 9180
```

**Note:** Keep this terminal session open while working with the Admin API. The port-forward will terminate if the terminal is closed.

To run the port-forward in the background:

```shell
kubectl port-forward -n apisix svc/apisix-admin 9180 &
```

#### Retrieving the Admin Key

To access the APISIX Admin APIs, you need the admin key. The following commands will retrieve the key, store it in the `ADMIN_KEY` environment variable, and display it:

**Option 1 - Using yq:**

```bash
export ADMIN_KEY=$(kubectl -n apisix get configmap apisix -o yaml | yq '.data."config.yaml"' | yq '.deployment.admin.admin_key[] | select(.name == "admin") | .key') && echo "Admin Key: $ADMIN_KEY"
```

**Option 2 - Using kubectl and awk:**

```bash
export ADMIN_KEY=$(kubectl get configmap apisix -n apisix -o jsonpath='{.data.config\.yaml}' | awk '/admin_key:/,/role: admin/ {if ($1 == "key:") {print $2; exit}}') && echo "Admin Key: $ADMIN_KEY"
```

**Option 3 - Manual retrieval:**

If the commands above don't work:

1. Run: `kubectl get configmap apisix -n apisix -o yaml`
1. Look for the `config.yaml` section under `data`
1. Find `deployment.admin.admin_key` and locate the admin user's key value
1. Copy the key and export it:

```bash
export ADMIN_KEY="your-admin-key-here" && echo "Admin Key: $ADMIN_KEY"
```

**Test the admin key** by running a simple curl command to retrieve the list of available plugins:

```shell
curl -sS http://127.0.0.1:9180/apisix/admin/plugins/list -H "X-API-KEY: $ADMIN_KEY" -X GET | jq
```

Expected response if successful (shows available plugins):
```json
[
  "api-breaker",
  "authz-keycloak",
  "basic-auth",
  "batch-requests",
  "consumer-restriction",
  "cors",
  "jwt-auth",
  "key-auth",
  "limit-count",
  "limit-req",
  "prometheus",
  "proxy-rewrite",
  "..."
]
```

This confirms the admin key is valid and shows the plugins available in your APISIX installation.

#### Retrieving the Gateway IP

To test routes through the APISIX gateway, you need the external IP address of the ingress controller. The following command will retrieve the IP, store it in the `GATEWAY_IP` environment variable, and display it:

```bash
export GATEWAY_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}') && echo "Gateway IP: $GATEWAY_IP"
```

**Note:** If your load balancer uses a hostname instead of an IP address (common in AWS), use this command instead:

```bash
export GATEWAY_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') && echo "Gateway Hostname: $GATEWAY_IP"
```

**Verify Apache APISIX is accessible:**

```bash
curl -sS http://$GATEWAY_IP
```

You should receive a response (possibly a 404 if no routes are configured yet), confirming Apache APISIX is reachable.

---

### Working with APISIX REST API

The following examples demonstrate common operations using the APISIX Admin API. These operations allow you to manage routes, upstreams, and other Apache APISIX configurations programmatically. For complete API reference, see the [APISIX Admin API documentation](https://apisix.apache.org/docs/apisix/admin-api/).

**Understanding Routes, Services, and Upstreams**

APISIX uses three key concepts to route traffic from clients to backend services:

- **Route** - The entry point that matches incoming requests based on URI, host, method, headers, etc., and determines where to send them. Think of it as a traffic rule: "If the request matches this pattern, send it here."

- **Upstream** - Defines one or more backend service instances (nodes) and how to distribute traffic among them (load balancing, health checks). This is where your actual backend services run.

- **Service** (optional) - An abstraction that groups routes with shared configuration like plugins, upstreams, and common settings. Use services to avoid duplicating configuration across multiple routes.

**Relationship Diagram:**

```
┌─────────────┐
│   Client    │
│   Request   │
└──────┬──────┘
       │ HTTP/HTTPS
       ↓
┌──────────────────────────────────────────────────────────────┐
│                    APISIX Gateway                            │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Route: /api/users/*                                   │ │
│  │  ├─ Matches: URI, method, host, headers                │ │
│  │  ├─ Route-specific plugins (optional)                  │ │
│  │  └─ Points to: Service OR Upstream                     │ │
│  └────────────┬───────────────────────────────────────────┘ │
│               │                                              │
│               ↓                                              │
│  ┌────────────────────────────┐                             │
│  │  Service (Optional)        │  ← Multiple routes can      │
│  │  ├─ Shared plugins         │    share one service        │
│  │  ├─ Common configuration   │                             │
│  │  └─ Points to: Upstream    │                             │
│  └────────────┬───────────────┘                             │
│               │                                              │
│               ↓                                              │
│  ┌────────────────────────────┐                             │
│  │  Upstream                  │  ← Multiple routes/services │
│  │  ├─ Load balancing         │    can share one upstream   │
│  │  ├─ Health checks          │                             │
│  │  └─ Backend nodes:         │                             │
│  │     • Pod 1 (weight: 3)    │                             │
│  │     • Pod 2 (weight: 2)    │                             │
│  │     • Pod 3 (weight: 1)    │                             │
│  └────────────┬───────────────┘                             │
│               │                                              │
└───────────────┼──────────────────────────────────────────────┘
                │
       ┌────────┼────────┐
       │        │        │
       ↓        ↓        ↓
   ┌──────┐ ┌──────┐ ┌──────┐
   │ Pod1 │ │ Pod2 │ │ Pod3 │  ← Your backend services
   └──────┘ └──────┘ └──────┘
```

**Configuration Patterns:**

1. **Direct Route → Upstream** (Simple setup)
   ```
   Route ──→ Upstream ──→ Backend Pods
   ```

2. **Route → Service → Upstream** (Shared configuration)
   ```
   Route 1 ──┐
   Route 2 ──┼──→ Service ──→ Upstream ──→ Backend Pods
   Route 3 ──┘
   ```

3. **Multiple Routes → Same Upstream** (Shared backend)
   ```
   Route 1 (/api/users)   ──┐
   Route 2 (/api/orders)  ──┼──→ Upstream ──→ Backend Pods
   Route 3 (/api/products)──┘
   ```

**When to use each:**

- **Upstream only**: Simple deployments with unique backend services per route
- **Service + Upstream**: When multiple routes share common plugins or configuration (e.g., all API endpoints need rate limiting and authentication)
- **Shared Upstream**: When different routes need to reach the same backend service but with different matching rules or plugins

---

#### Creating an Upstream

An upstream defines the target service(s) that will handle the routed requests. Create an upstream before creating routes that reference it. For detailed upstream configuration options, see the [Upstream documentation](https://apisix.apache.org/docs/apisix/terminology/upstream/).

**Example: Create an upstream for a backend service**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/upstreams/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PUT \
  -d '{
    "type": "roundrobin",
    "nodes": {
      "backend-service.YOUR-NAMESPACE.svc.cluster.local:8080": 1
    },
    "timeout": {
      "connect": 6,
      "send": 6,
      "read": 6
    },
    "retries": 2,
    "keepalive_pool": {
      "size": 320,
      "idle_timeout": 60,
      "requests": 1000
    }
  }' | jq
```

**Understanding the configuration:**

- `type: "roundrobin"` - Load balancing algorithm (roundrobin, consistent hashing, weighted roundrobin, etc.)
- `nodes` - Backend service endpoints with weights (higher weight = more traffic)
- `timeout` - Connection and read/write timeouts in seconds
- `retries` - Number of retry attempts for failed requests
- `keepalive_pool` - Connection pool settings for performance optimization

**Expected response:**

```json
{
  "key": "/apisix/upstreams/1",
  "value": {
    "type": "roundrobin",
    "nodes": {
      "backend-service.YOUR-NAMESPACE.svc.cluster.local:8080": 1
    },
    "timeout": {
      "connect": 6,
      "send": 6,
      "read": 6
    },
    "retries": 2,
    "keepalive_pool": {
      "size": 320,
      "idle_timeout": 60,
      "requests": 1000
    },
    "create_time": 1234567890,
    "update_time": 1234567890
  }
}
```

**List all upstreams:**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/upstreams \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X GET | jq
```

**Delete an upstream:**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/upstreams/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X DELETE | jq
```

**Note:** You must delete or update all routes and services using an upstream before you can delete the upstream.

#### Creating a Route

Routes define how incoming requests are matched and forwarded to upstreams. You can match on URI, host, method, headers, and more. For advanced routing options, see the [Route documentation](https://apisix.apache.org/docs/apisix/terminology/route/).

**Example: Create a basic route**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PUT \
  -d '{
    "name": "my-api-route",
    "uri": "/api/v1/*",
    "methods": ["GET", "POST", "PUT", "DELETE"],
    "upstream_id": "1",
    "status": 1,
    "desc": "Route for my API service"
  }' | jq
```

**Understanding the configuration:**

- `name` - Descriptive name for the route
- `uri` - URI pattern to match (supports wildcards and regex)
- `methods` - HTTP methods allowed for this route
- `upstream_id` - Reference to the upstream created earlier
- `status` - 1 (enabled) or 0 (disabled)
- `desc` - Optional description

**Example: Create a route with host matching**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/2 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PUT \
  -d '{
    "name": "api-example-com",
    "uri": "/api/*",
    "host": "api.example.com",
    "methods": ["GET", "POST"],
    "upstream_id": "1",
    "status": 1,
    "desc": "Route for api.example.com host"
  }' | jq
```

**Example: Create a route with inline upstream (no separate upstream resource)**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/3 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PUT \
  -d '{
    "name": "quick-route",
    "uri": "/health",
    "methods": ["GET"],
    "upstream": {
      "type": "roundrobin",
      "nodes": {
        "backend-service.YOUR-NAMESPACE.svc.cluster.local:8080": 1
      }
    },
    "status": 1
  }' | jq
```

#### Testing the Route

After creating a route, test it to ensure it's working correctly. Make sure you have retrieved the [Gateway IP](#retrieving-the-gateway-ip) and stored it in the `GATEWAY_IP` environment variable.

**Test the route through Apache APISIX:**

```bash
# Using the Apache APISIX gateway IP/hostname
curl -sS http://$GATEWAY_IP/api/v1/users | jq

# Or port-forward to the Apache APISIX gateway for local testing
kubectl port-forward -n apisix svc/apisix-gateway 9080
curl -sS http://127.0.0.1:9080/api/v1/users | jq
```

**Verify the route exists:**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X GET | jq
```

#### Updating a Route

Routes can be updated in place using PUT or PATCH methods.

**Example: Update a route to add more methods**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "methods": ["GET", "POST", "PUT", "DELETE", "PATCH"]
  }' | jq
```

**Example: Disable a route temporarily**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "status": 0
  }' | jq
```

**Example: Update route URI pattern**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "uri": "/api/v2/*"
  }' | jq
```

#### Deleting a Route

Remove a route when it's no longer needed.

**Example: Delete a specific route**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X DELETE | jq
```

**Expected response:**

```json
{
  "deleted": "1",
  "key": "/apisix/routes/1"
}
```

**Example: Delete multiple routes**

```bash
# Delete route 1
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X DELETE | jq

# Delete route 2
curl -sS http://127.0.0.1:9180/apisix/admin/routes/2 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X DELETE | jq

# Delete route 3
curl -sS http://127.0.0.1:9180/apisix/admin/routes/3 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X DELETE | jq
```

**Verify deletion:**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X GET | jq
```

Expected response when route doesn't exist:
```json
{
  "error_msg": "failed to find route"
}
```

#### Listing All Routes

View all configured routes to understand your current Apache APISIX configuration.

**List all routes:**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X GET | jq
```

**List routes with formatted output:**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X GET | jq '.list[] | {id: .value.id, name: .value.name, uri: .value.uri, status: .value.status}'
```

**Count total routes:**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X GET | jq '.total'
```

#### Creating a Service

A Service is an abstraction that groups routes with shared configuration such as plugins, upstream settings, and other common properties. Services help organize large deployments by allowing you to configure common behaviors once and reuse them across multiple routes. For more details, see the [Service documentation](https://apisix.apache.org/docs/apisix/terminology/service/).

**Example: Create a service with common plugin configuration**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/services/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PUT \
  -d '{
    "name": "my-api-service",
    "desc": "Shared configuration for my API endpoints",
    "upstream_id": "1",
    "plugins": {
      "limit-count": {
        "count": 100,
        "time_window": 60,
        "rejected_code": 429
      },
      "prometheus": {}
    }
  }' | jq
```

**Understanding the configuration:**

- `name` - Descriptive name for the service
- `desc` - Optional description
- `upstream_id` - Reference to an upstream (alternatively, you can inline the upstream configuration)
- `plugins` - Plugins that will be applied to all routes using this service

**Example: Create a route that uses the service**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/10 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PUT \
  -d '{
    "name": "api-endpoint",
    "uri": "/api/users/*",
    "methods": ["GET", "POST"],
    "service_id": "1"
  }' | jq
```

This route inherits all configuration from the service (upstream, plugins, etc.). You can still add route-specific plugins that will be merged with the service plugins.

**List all services:**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/services \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X GET | jq
```

**Delete a service:**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/services/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X DELETE | jq
```

**Note:** You must delete or update all routes using a service before you can delete the service.

---

### Common Operations

#### Enable Authentication on a Route

Protect your routes with various authentication methods. APISIX supports multiple authentication plugins including:

- **key-auth** - API key authentication (shown in example below)
- **jwt-auth** - JSON Web Token authentication
- **basic-auth** - HTTP Basic authentication
- **oauth2** - OAuth 2.0 authentication
- **hmac-auth** - HMAC authentication
- **ldap-auth** - LDAP authentication

For complete authentication options, see the [Authentication Plugins documentation](https://apisix.apache.org/docs/apisix/plugins/key-auth/).

**Example: Enable API Key authentication**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "plugins": {
      "key-auth": {}
    }
  }' | jq
```

**Create a consumer with an API key:**

```bash
# Create consumer
curl -sS http://127.0.0.1:9180/apisix/admin/consumers \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PUT \
  -d '{
    "username": "my-app",
    "plugins": {
      "key-auth": {
        "key": "my-secret-api-key-12345"
      }
    }
  }' | jq
```

**Test the authenticated route:**

```bash
# Without API key (should fail with 401 error)
curl -sS http://$GATEWAY_IP/api/v1/users | jq

# With API key (should succeed)
curl -sS http://$GATEWAY_IP/api/v1/users -H "apikey: my-secret-api-key-12345" | jq
```

#### Enable Rate Limiting

Protect your services from overload with rate limiting. For advanced rate limiting configurations and distributed rate limiting with Redis, see the [limit-count plugin documentation](https://apisix.apache.org/docs/apisix/plugins/limit-count/).

**Example: Limit to 10 requests per minute**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "plugins": {
      "limit-count": {
        "count": 10,
        "time_window": 60,
        "rejected_code": 429,
        "rejected_msg": "Too many requests",
        "policy": "local"
      }
    }
  }' | jq
```

**Understanding the configuration:**

- `count` - Maximum number of requests allowed
- `time_window` - Time window in seconds
- `rejected_code` - HTTP status code when limit is exceeded
- `rejected_msg` - Custom error message
- `policy` - "local" (single node) or "redis" (distributed)

#### Configure Load Balancing

Distribute traffic across multiple backend instances. APISIX supports multiple load balancing algorithms. For more details on available algorithms and health checks, see the [Load Balancing documentation](https://apisix.apache.org/docs/apisix/terminology/upstream/#load-balancing).

**Example: Weighted round-robin load balancing**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/upstreams/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "type": "roundrobin",
    "nodes": {
      "backend-1.YOUR-NAMESPACE.svc.cluster.local:8080": 3,
      "backend-2.YOUR-NAMESPACE.svc.cluster.local:8080": 2,
      "backend-3.YOUR-NAMESPACE.svc.cluster.local:8080": 1
    }
  }' | jq
```

This configuration sends 50% of traffic to backend-1, 33% to backend-2, and 17% to backend-3.

**Example: Consistent hashing (sticky sessions)**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/upstreams/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "type": "chash",
    "key": "remote_addr",
    "nodes": {
      "backend-1.YOUR-NAMESPACE.svc.cluster.local:8080": 1,
      "backend-2.YOUR-NAMESPACE.svc.cluster.local:8080": 1
    }
  }' | jq
```

This ensures requests from the same IP address always go to the same backend.

#### Enable OpenTelemetry Tracing

Enable distributed tracing with OpenTelemetry to track requests across your microservices. APISIX can export traces to OpenTelemetry collectors for observability and debugging. For complete configuration options, see the [opentelemetry plugin documentation](https://apisix.apache.org/docs/apisix/plugins/opentelemetry/).

**Example: Enable OpenTelemetry on a route**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "plugins": {
      "opentelemetry": {
        "sampler": {
          "name": "always_on"
        },
        "additional_attributes": [
          "http_user_agent",
          "http_host"
        ]
      }
    }
  }' | jq
```

**Understanding the configuration:**

- `sampler.name` - Sampling strategy, available options:
  - `always_on` - Sample all requests
  - `always_off` - Don't sample any requests
  - `trace_id_ratio_based` - Sample based on a fraction (e.g., 0.1 = 10%)
  - `parent_base` - Use parent span's sampling decision
- `additional_attributes` - Extra attributes to include in traces (from request headers or APISIX variables)

**Example: Configure sampling rate (10% of requests)**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "plugins": {
      "opentelemetry": {
        "sampler": {
          "name": "trace_id_ratio_based",
          "options": {
            "fraction": 0.1
          }
        }
      }
    }
  }' | jq
```

**Note:** The OpenTelemetry collector endpoint is configured globally in the APISIX config (typically pointing to your observability stack like SigNoz or Jaeger).

#### Configure Health Checks

Configure active and passive health checks to automatically detect and remove unhealthy backend nodes from your upstream. This improves reliability by ensuring traffic only goes to healthy services. For detailed health check options, see the [Health Check documentation](https://apisix.apache.org/docs/apisix/tutorials/health-check/).

**Example: Configure active HTTP health checks**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/upstreams/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "checks": {
      "active": {
        "type": "http",
        "http_path": "/health",
        "timeout": 2,
        "healthy": {
          "interval": 5,
          "successes": 2
        },
        "unhealthy": {
          "interval": 5,
          "http_failures": 3
        }
      }
    }
  }' | jq
```

**Understanding the configuration:**

- `active.type` - Health check type: `http`, `https`, or `tcp`
- `http_path` - Endpoint to check for HTTP/HTTPS health checks
- `timeout` - Health check timeout in seconds
- `healthy.interval` - How often to check healthy nodes (seconds)
- `healthy.successes` - Number of successful checks to mark a node as healthy
- `unhealthy.interval` - How often to check unhealthy nodes (seconds)
- `unhealthy.http_failures` - Number of failures to mark a node as unhealthy

**Example: Configure passive health checks**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/upstreams/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "checks": {
      "passive": {
        "type": "http",
        "healthy": {
          "http_statuses": [200, 201, 202, 204, 301, 302],
          "successes": 3
        },
        "unhealthy": {
          "http_statuses": [500, 502, 503, 504],
          "http_failures": 3,
          "tcp_failures": 3
        }
      }
    }
  }' | jq
```

**Understanding passive health checks:**

- Passive checks monitor actual production traffic (no additional health check requests)
- `healthy.http_statuses` - HTTP status codes considered healthy
- `unhealthy.http_statuses` - HTTP status codes considered unhealthy
- Nodes are marked unhealthy after consecutive failures and automatically recover after consecutive successes

**Example: Combine active and passive health checks**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/upstreams/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "checks": {
      "active": {
        "type": "http",
        "http_path": "/health",
        "timeout": 2,
        "healthy": {
          "interval": 10,
          "successes": 2
        },
        "unhealthy": {
          "interval": 5,
          "http_failures": 2
        }
      },
      "passive": {
        "type": "http",
        "healthy": {
          "http_statuses": [200, 201],
          "successes": 3
        },
        "unhealthy": {
          "http_statuses": [500, 502, 503, 504],
          "http_failures": 3
        }
      }
    }
  }' | jq
```

This configuration provides comprehensive health monitoring with both proactive checks and real-time traffic monitoring.

---

### Managing SSL/TLS Certificates

APISIX supports HTTPS routes by managing SSL/TLS certificates. You can upload certificates and associate them with routes to enable secure communication. For advanced SSL configuration, see the [SSL documentation](https://apisix.apache.org/docs/apisix/terminology/ssl/).

**Example: Upload an SSL certificate**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/ssls/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PUT \
  -d '{
    "cert": "-----BEGIN CERTIFICATE-----\nMIIDST...\n-----END CERTIFICATE-----",
    "key": "-----BEGIN PRIVATE KEY-----\nMIIEv...\n-----END PRIVATE KEY-----",
    "snis": ["api.example.com", "*.example.com"]
  }' | jq
```

**Understanding the configuration:**

- `cert` - The SSL certificate in PEM format (newlines must be escaped as `\n`)
- `key` - The private key in PEM format (newlines must be escaped as `\n`)
- `snis` - Server Name Indication (SNI) domains this certificate applies to (supports wildcards)

**Example: Create an HTTPS route**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PUT \
  -d '{
    "name": "https-route",
    "uri": "/api/*",
    "methods": ["GET", "POST"],
    "host": "api.example.com",
    "upstream_id": "1"
  }' | jq
```

**Note:** HTTPS routes automatically use the SSL certificate that matches the route's `host` SNI. Ensure your Apache APISIX gateway is listening on port 9443 (or your configured HTTPS port).

**List all SSL certificates:**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/ssls \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X GET | jq
```

**Delete an SSL certificate:**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/ssls/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X DELETE | jq
```

**Tip:** For production environments, consider using cert-manager with APISIX for automatic certificate management and renewal.

---

### Accessing APISIX Dashboard

:::note
Note that all functionality is not available in the dashboard. You might need to use the REST APIs for advanced configurations.
:::

The APISIX Dashboard provides a web-based interface for visual management of routes, upstreams, consumers, and plugins. It offers an alternative to the Admin REST API for users who prefer graphical configuration over command-line operations, making it easier to visualize and manage your Apache APISIX gateway setup at a glance.

**Prerequisites:**

1. Ensure you have the [port-forward tunnel](#port-forwarding-to-admin-api) to the APISIX admin service running
2. Retrieve the admin key using the instructions in [Retrieving the Admin Key](#retrieving-the-admin-key)

**Accessing the Dashboard:**

With the tunnel established, open your browser and navigate to:

**URL:** [http://localhost:9180/ui](http://localhost:9180/ui)

**Login Credentials:**
- **Username**: `admin`
- **API Key**: Use the admin key retrieved from the previous step

![APISIX Dashboard](images/apisix-dashboard.png)

---

### Troubleshooting

**Problem: Admin API returns "401 Unauthorized"**

Solution: Verify your admin key is correct and properly set in the X-API-KEY header.

```bash
# Verify the admin key
kubectl get configmap apisix -n apisix -o yaml | grep -A 10 "admin_key"
```

**Problem: Route not working - returns 404**

Solution: Check the route configuration and verify the URI pattern matches your request:

```bash
# List all routes
curl -sS http://127.0.0.1:9180/apisix/admin/routes -H "X-API-KEY: $ADMIN_KEY" | jq

# Check specific route
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 -H "X-API-KEY: $ADMIN_KEY" | jq
```

**Problem: Route exists but returns 502 Bad Gateway**

Solution: The upstream service may be unavailable. Verify the backend service is running:

```bash
# Check if backend pods are running
kubectl get pods -n YOUR-NAMESPACE

# Test direct connectivity to the service
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl http://backend-service.YOUR-NAMESPACE.svc.cluster.local:8080/health
```

**Problem: Changes to routes not taking effect**

Solution: APISIX updates are near real-time, but you can verify etcd synchronization:

```bash
# Check APISIX pods for errors
kubectl logs -n apisix -l app.kubernetes.io/name=apisix --tail=50

# Verify etcd is healthy
kubectl get pods -n apisix -l app.kubernetes.io/name=etcd
```

**Problem: Port-forward keeps disconnecting**

Solution: Run port-forward in the background with auto-reconnect:

```bash
while true; do kubectl port-forward -n apisix svc/apisix-admin 9180; sleep 1; done &
```

#### Debugging Routes

When troubleshooting routing issues, use these techniques to understand how APISIX is processing requests and which routes are matching.

**Check which route matched a request:**

Enable the server-info plugin globally to get detailed information about request processing:

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/global_rules/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PUT \
  -d '{
    "plugins": {
      "server-info": {}
    }
  }' | jq
```

Then check the response headers when making a request to Apache APISIX. APISIX will include `X-APISIX-Upstream-Status` and other debugging headers.

**View route matching order and priority:**

Routes are matched based on priority. Higher priority routes are matched first. List routes with their priorities:

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X GET | jq '.list[] | {id: .value.id, name: .value.name, uri: .value.uri, priority: .value.priority, status: .value.status}'
```

**Note:** Routes without an explicit priority have a default priority of 0. Routes with the same priority are matched in an undefined order.

**Set route priority explicitly:**

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PATCH \
  -d '{
    "priority": 100
  }' | jq
```

**Test route matching without sending real traffic:**

Use the `echo` plugin to inspect how APISIX sees the request:

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/routes/999 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X PUT \
  -d '{
    "name": "debug-route",
    "uri": "/debug/*",
    "plugins": {
      "echo": {
        "before_body": "matched debug route\n"
      }
    }
  }' | jq
```

Then test:

```bash
curl -sS http://$GATEWAY_IP/debug/test
```

This will return "matched debug route" confirming the route mat





hed.

**Check upstream health status:**

View the current health status of upstream nodes:

```bash
curl -sS http://127.0.0.1:9180/apisix/admin/upstreams/1 \
  -H "X-API-KEY: $ADMIN_KEY" \
  -X GET | jq '.value.checks'
```

**Enable verbose logging for debugging:**

Temporarily increase APISIX logging to debug level by editing the APISIX ConfigMap and restarting the pods (use with caution in production).

---

### Additional Resources

**Official APISIX Documentation:**
- [Getting Started Guide](https://apisix.apache.org/docs/apisix/getting-started/)
- [Admin API Reference](https://apisix.apache.org/docs/apisix/admin-api/)
- [Complete Plugins List](https://apisix.apache.org/docs/apisix/plugins/batch-requests/)
- [Terminology and Concepts](https://apisix.apache.org/docs/apisix/terminology/api-gateway/)
- [Architecture Overview](https://apisix.apache.org/docs/apisix/architecture-design/apisix/)

**Development and Community:**
- [APISIX GitHub Repository](https://github.com/apache/apisix)
- [Dashboard Documentation](https://apisix.apache.org/docs/dashboard/USER_GUIDE/)
- [Community Slack Channel](https://join.slack.com/t/the-asf/shared_invite/zt-vlfbf7ch-HkbNHiU_uDlcH_RvaHv9gQ)

**Oracle Resources:**
- [Oracle Backend for Microservices and AI Documentation](https://oracle.github.io/microservices-datadriven/)
