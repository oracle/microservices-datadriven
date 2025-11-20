---
title: Spring Boot Admin Server
sidebar_position: 10
---
## Spring Boot Admin Server

Spring Boot Admin works by registering Spring Boot applications that expose Actuator endpoints. Each application's health and metrics data is polled by Spring Boot Admin Server, which aggregates and displays this information in a web dashboard. The registered applications can either self-register or be discovered using service discovery tools like Eureka or Consul. Through the dashboard, users can monitor the health, memory usage, logs, and more for each application, and even interact with them via management endpoints for tasks like restarting or updating configurations.

[Spring Boot Admin Documentation](https://docs.spring-boot-admin.com/3.5.5/docs/installation-and-setup/)

### Installing Spring Boot Admin

Spring Boot Admin will be installed if the `admin-server.enabled` is set to `true` in the `values.yaml` file. The default namespace for Spring Boot Admin is `admin-server`.

### Access Spring Boot Admin Web Interface

:::note Namespace Configuration
All `kubectl` commands in this guide use `-n admin-server` as the default namespace. If the Spring Boot Admin Server is installed in a different namespace, replace `admin-server` with your actual namespace name in all commands.

To find your namespace, run:
```bash
kubectl get pods -A | grep admin-server
```
:::

To access the Spring Boot Admin Web Interface, use kubectl port-forward to create a secure channel to `service/admin-server`. Run the following command to establish the secure tunnel:

```shell
kubectl port-forward -n admin-server svc/admin-server 8989
```

Open the [Spring Boot Admin dashboard](http://localhost:8989)

![Spring Boot Admin Server](images/admin-server.png)

### Enable a Spring Boot Application for Spring Boot Admin

To enable a Spring Boot application to register with Spring Boot Admin, add the following dependency:

```xml
<dependency>
    <groupId>de.codecentric</groupId>
    <artifactId>spring-boot-admin-starter-client</artifactId>
</dependency>
```

Add the following configuration to your `application.yaml` file:

```yaml
spring:
  boot:
    admin:
      client:
        url: ${spring.boot.admin.client.url}
        instance:
          prefer-ip: true
management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: always
```

The `spring.boot.admin.client.url` variable is automatically injected into your deployment when you deploy applications to Oracle Backend for Microservices and AI using the OBaaS deployment Helm chart. It typically points to `http://admin-server.admin-server:8989`.

## Testing and Debugging

### Verify Spring Boot Admin Server is Running

Check that the Spring Boot Admin Server pod is running and healthy:

```bash
kubectl get pods -n admin-server
```

Expected output:

```text
NAME                            READY   STATUS    RESTARTS   AGE
admin-server-7b8f9d5c4d-x9k2m   1/1     Running   0          5m
```

Check the Spring Boot Admin service:

```bash
kubectl get svc -n admin-server
```

Expected output:

```text
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
admin-server   ClusterIP   10.96.123.456   <none>        8989/TCP   5m
```

### Test Application Registration

After deploying an application configured to register with Spring Boot Admin, verify it appears in the dashboard:

**Option 1: Using the Spring Boot Admin Web UI**

1. Port-forward to Spring Boot Admin:
   ```bash
   kubectl port-forward -n admin-server svc/admin-server 8989
   ```

2. Open [http://localhost:8989](http://localhost:8989) in your browser

3. Check the "Applications" section on the wallboard. Your application should appear with:
   - Application name
   - Number of instances
   - Health status (UP/DOWN)

4. Click on the application to see detailed information:
   - Health indicators
   - Metrics
   - Environment properties
   - Log files
   - JVM information
   - Threads

**Option 2: Using Spring Boot Admin REST API**

Query the Spring Boot Admin REST API to see all registered applications:

```bash
kubectl port-forward -n admin-server svc/admin-server 8989 &
curl -s http://localhost:8989/applications | jq
```

Check a specific application:

```bash
curl -s http://localhost:8989/applications/<application-name> | jq
```

### Verify Actuator Endpoints

Spring Boot Admin requires actuator endpoints to be exposed. Test that your application's actuator endpoints are accessible:

```bash
kubectl port-forward -n <your-namespace> <your-pod-name> 8080 &
curl http://localhost:8080/actuator
```

Expected output should list available endpoints:

```json
{
  "_links": {
    "self": { "href": "http://localhost:8080/actuator" },
    "health": { "href": "http://localhost:8080/actuator/health" },
    "info": { "href": "http://localhost:8080/actuator/info" },
    "metrics": { "href": "http://localhost:8080/actuator/metrics" }
  }
}
```

### Common Issues and Debugging

#### Applications Not Appearing in Spring Boot Admin

**Check application logs for registration errors:**

```bash
kubectl logs -n <your-namespace> <your-pod-name> | grep -i "admin"
```

Look for registration messages like:
- `Application registered itself as <instance-id>`
- `Failed to register application`

**Common causes:**

1. **Incorrect Spring Boot Admin URL:** Verify the `spring.boot.admin.client.url` property points to the correct URL (typically `http://admin-server.admin-server:8989`)

2. **Network connectivity:** Test connectivity from your application pod to Spring Boot Admin:
   ```bash
   kubectl exec -n <your-namespace> <your-pod-name> -- curl -v http://admin-server.admin-server:8989/applications
   ```

3. **Missing dependencies:** Ensure the `spring-boot-admin-starter-client` dependency is included in your application

4. **Actuator endpoints not exposed:** Verify that management endpoints are exposed in your `application.yaml`

5. **Security blocking registration:** If Spring Boot Admin has security enabled, ensure your application provides the correct credentials

#### Application Shows as DOWN or OFFLINE

**Possible causes:**

1. **Health endpoint failing:** Check your application's health endpoint:
   ```bash
   kubectl exec -n <your-namespace> <your-pod-name> -- curl http://localhost:8080/actuator/health
   ```

2. **Health endpoint not accessible:** Spring Boot Admin must be able to reach the health endpoint. Verify network policies allow traffic between Spring Boot Admin and your application

3. **Incorrect service URL registered:** Check the registered instance URL in Spring Boot Admin. It should be accessible from within the cluster

4. **Application restarting:** If the application is in a restart loop, it will appear as DOWN

#### No Metrics or Limited Data Available

**Check exposed endpoints:**

```bash
curl http://localhost:8080/actuator | jq '._links | keys'
```

If endpoints are missing, update your `application.yaml`:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: "*"  # Expose all endpoints (use cautiously in production)
```

For production, explicitly list required endpoints:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,env,loggers,threaddump,heapdump
```

#### Cannot View Application Logs

Spring Boot Admin can display application logs if the logfile endpoint is exposed:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: logfile
  endpoint:
    logfile:
      external-file: /path/to/application.log
```

If using console logging only, logs won't be available through Spring Boot Admin. Consider:
- Configuring file-based logging
- Using centralized logging (e.g., via SigNoz/observability stack)

#### Check Spring Boot Admin Server Logs

View Spring Boot Admin server logs to diagnose registration or connection issues:

```bash
kubectl logs -n admin-server -l app=admin-server --tail=100 -f
```

Look for:
- Registration events: `New application ... registered`
- Connection errors: `Failed to connect to ...`
- Authentication issues

#### Verify Environment Variables

Check that the Spring Boot Admin environment variables are correctly injected into your application pod:

```bash
kubectl exec -n <your-namespace> <your-pod-name> -- env | grep -i admin
```

Expected variables:
```text
SPRING_BOOT_ADMIN_CLIENT_URL=http://admin-server.admin-server:8989
```

#### Registration Delays

Applications may take up to 30-60 seconds to appear in Spring Boot Admin after startup due to:
- Application startup time
- Initial registration attempt timing
- Health check intervals

To speed up registration for development/testing:

```yaml
spring:
  boot:
    admin:
      client:
        period: 5000  # Check every 5 seconds (default: 10000ms)
```

### Enable Debug Logging

**For your application (client-side):**

Add to your `application.yaml`:

```yaml
logging:
  level:
    de.codecentric.boot.admin.client: DEBUG
```

**For Spring Boot Admin Server:**

Enable debug logging in the Spring Boot Admin server:

```bash
kubectl set env deployment/admin-server -n admin-server LOGGING_LEVEL_DE_CODECENTRIC_BOOT_ADMIN=DEBUG
```

Or by editing the deployment:

```bash
kubectl edit deployment admin-server -n admin-server
```

Add environment variable:
```yaml
env:
- name: LOGGING_LEVEL_DE_CODECENTRIC_BOOT_ADMIN
  value: DEBUG
```

### Test Data Flow

To verify the complete flow from application to Spring Boot Admin:

1. **Check application registers successfully:**
   ```bash
   kubectl logs -n <your-namespace> <your-pod-name> | grep "Application registered"
   ```

2. **Verify Spring Boot Admin receives registration:**
   ```bash
   kubectl logs -n admin-server -l app=admin-server | grep "New application"
   ```

3. **Confirm health checks are working:**
   ```bash
   kubectl logs -n admin-server -l app=admin-server | grep "health"
   ```

4. **Access the dashboard and verify metrics are updating**

## Getting Help

- [#oracle-db-microservices Slack channel](https://oracledevs.slack.com/archives/C06L9CDGR6Z) in the Oracle Developers slack workspace.
- [Open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).
