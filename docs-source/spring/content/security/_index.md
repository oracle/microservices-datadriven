The Oracle Backend for Spring Boot has the following security characteristics:

- All access to the database is done using Mutual TLS (Database Wallet). The username, password and URI are stored in Kuberentes secrets. 
- Accessing the dashboards can only be done using port forwarding.
- The only "public" exposure is the APISIX Gateway (note that the dashboard is not exposed publicly). 
- Services deployed to the platofrm are not exposed through the gateway automatically.
- The deployed platform services are using using self-signed certificates.
- A customer application can only access service running in the platform via the APISIX Gateway. The IP address for the gateway can be determined by executing the following command:


    ```
    kubectl -n ingress-nginx get svc ingress-nginx-controller
    ```

- The customer application can be secured using Spring Security, e.g., Spring OAuth 2.0 Resource Server. An external authorization server is recommended (for example Okta, Oauth0)


The diagram below provides an overview of the security architecture.

![Security Architecture](../ebaas-security-architecture.png)