The Oracle Backend for Spring Boot has the following security characteristics:

- All access to the database is done using Mutual Transport Layer Security (mTLS) database wallet. The user name, password, and URL are stored in Kubernetes secrets.
- Accessing the dashboards can only be done using port-forwarding.
- The only "public" exposure is the Apache APISIX Gateway (note that the dashboard is not exposed publicly).
- Services deployed to the platform are not exposed through the Apache APISIX Gateway automatically.  If you want to expose the service through the gateway, you must define a route in the APISIX dashboard.
- The deployed platform services are using using self-signed certificates.
- A customer application can only access services running in the platform using the Apache APISIX Gateway. The IP address for the gateway can be determined by using this command:


    ```bash
    kubectl -n ingress-nginx get svc ingress-nginx-controller
    ```

- The customer application can be secured using Spring Security (for example, Spring OAuth 2.0 Resource Server). An external authorization server is recommended (for example Okta or Auth0).

The following diagram provides an overview of the Spring Security architecture:

![Security Architecture](../ebaas-security-architecture.png)