---
title: Spring Boot Eureka Server
sidebar_position: 8
---
## Spring Boot Eureka Server

Oracle Backend for Microservices and AI includes the Spring Boot Eureka service registry, which stores information about client services. Typically, each microservice registers with Eureka at startup. Eureka maintains a list of all active service instances, including their IP addresses and ports. Other services can look up this information using a well-known key, enabling service-to-service communication without hardcoding addresses at development or deployment time.

### Installing Spring Boot Eureka Server

Spring Boot Eureka Server will be installed if the `eureka.enabled` is set to `true` in the `values.yaml` file. The default namespace for Spring Boot Eureka Server is `eureka`.

### Access Eureka Web User Interface

:::note Namespace Configuration
All `kubectl` commands in this guide use `-n eureka` as the default namespace. If the Spring Boot Eureka Server is installed in a different namespace, replace `eureka` with your actual namespace name in all commands.

To find your namespace, run:
```bash
kubectl get pods -A | grep eureka
```
:::

To access the Eureka Web User Interface, use kubectl port-forward to create a secure channel to `service/eureka`. Run the following command to establish the secure tunnel:

```shell
kubectl port-forward -n eureka svc/eureka 8761
```

Open the [Eureka web user interface](http://localhost:8761)

![Eureka Web User Interface](images/eureka-web.png)

### Enable a Spring Boot application for Eureka

To enable a Spring Boot application, you need to add the following dependency

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

And to configure the application to register with Eureka, add the following to the `application.yaml` file. The variables in this configuration are automatically injected into your deployment and pods when you deploy applications to Oracle Backend for Microservices and AI using the OBaaS deployment Helm chart.

```yaml
eureka:
  instance:
    hostname: ${spring.application.name}
    preferIpAddress: true
  client:
    service-url:
      defaultZone: ${eureka.service-url}
    fetch-registry: true
    register-with-eureka: true
    enabled: true
```

### Enable a Helidon application for Eureka

To enable a Helidon application, you need to add the following dependency

```xml
<dependency>
    <groupId>io.helidon.integrations.eureka</groupId>
    <artifactId>helidon-integrations-eureka</artifactId>
    <scope>runtime</scope>
</dependency>
```

And to configure the application to register with Eureka, add the following to the `application.yaml` file:

```properties
server.features.eureka.enabled=true
server.features.eureka.instance.name=${eureka.instance.hostname}
server.features.eureka.client.base-uri=${eureka.client.service-url.defaultZone}
server.features.eureka.client.register-with-eureka=true
server.features.eureka.client.fetch-registry=true
server.features.eureka.instance.preferIpAddress=true
```

## Testing and Debugging

### Verify Eureka Server is Running

Check that the Eureka server pod is running and healthy:

```bash
kubectl get pods -n eureka
```

Expected output:

```text
NAME                      READY   STATUS    RESTARTS   AGE
eureka-7b8f9d5c4d-x9k2m   1/1     Running   0          5m
```

Check the Eureka service:

```bash
kubectl get svc -n eureka
```

Expected output:

```text
NAME     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
eureka   ClusterIP   10.96.123.456   <none>        8761/TCP   5m
```

### Test Service Registration

After deploying an application configured to register with Eureka, verify it appears in the Eureka registry:

**Option 1: Using the Eureka Web UI**

1. Port-forward to Eureka:
   ```bash
   kubectl port-forward -n eureka svc/eureka 8761
   ```

2. Open [http://localhost:8761](http://localhost:8761) in your browser

3. Check the "Instances currently registered with Eureka" section. Your application should appear under "Application" with its name in uppercase

**Option 2: Using Eureka REST API**

Query the Eureka REST API to see all registered services:

```bash
kubectl port-forward -n eureka svc/eureka 8761 &
curl -s http://localhost:8761/eureka/apps | grep -i "<app>"
```

Or check a specific application:

```bash
curl -s http://localhost:8761/eureka/apps/YOUR-APPLICATION-NAME
```

### Common Issues and Debugging

#### Services Not Appearing in Eureka

**Check application logs for registration errors:**

```bash
kubectl logs -n <your-namespace> <your-pod-name> | grep -i eureka
```

**Common causes:**

1. **Incorrect Eureka URL:** Verify the `eureka.client.service-url.defaultZone` property points to the correct Eureka service URL (typically `http://eureka.eureka:8761/eureka`)

2. **Network connectivity:** Test connectivity from your application pod to Eureka:
   ```bash
   kubectl exec -n <your-namespace> <your-pod-name> -- curl -v http://eureka.eureka:8761/eureka/apps
   ```

3. **Missing dependencies:** Ensure the Eureka client dependency is included in your application

4. **Registration disabled:** Check that `eureka.client.register-with-eureka` is set to `true`

#### Service Registration Delays

Eureka uses a heartbeat mechanism with default intervals:
- **Registration delay:** Up to 30 seconds after application startup
- **Discovery delay:** Up to 30 seconds for other services to discover the new instance
- **Deregistration delay:** Up to 90 seconds after an instance goes down

To reduce these delays for development/testing, add to your application configuration:

```yaml
eureka:
  instance:
    lease-renewal-interval-in-seconds: 5
    lease-expiration-duration-in-seconds: 10
  client:
    registry-fetch-interval-seconds: 5
```

:::warning
Do not use these shortened intervals in production as they increase network traffic and server load.
:::

#### Check Eureka Server Logs

View Eureka server logs to diagnose registration or discovery issues:

```bash
kubectl logs -n eureka -l app=eureka --tail=100 -f
```

Look for:
- Registration events: `Registered instance ... with status UP`
- Heartbeat failures: `Lease expired for ...`
- Replication errors (if running multiple Eureka servers)

#### Verify Environment Variables

Check that the Eureka environment variables are correctly injected into your application pod:

```bash
kubectl exec -n <your-namespace> <your-pod-name> -- env | grep -i eureka
```

Expected variables:
```text
EUREKA_SERVICE_URL=http://eureka.eureka:8761/eureka
```

#### Application Shows as DOWN in Eureka

**Possible causes:**

1. **Health check endpoint failing:** Verify your application's health endpoint is responding:
   ```bash
   kubectl exec -n <your-namespace> <your-pod-name> -- curl http://localhost:<port>/actuator/health
   ```

2. **Incorrect health check URL:** Check the `eureka.instance.health-check-url-path` configuration

3. **Application startup incomplete:** The application may still be initializing

#### Multiple Instances Not Load Balancing

If you have multiple instances of a service but requests always go to the same instance:

1. **Verify all instances are registered:**
   ```bash
   curl -s http://localhost:8761/eureka/apps/YOUR-SERVICE-NAME | grep instanceId
   ```

2. **Check load balancer configuration:** Ensure your client is using a load-balanced RestTemplate or WebClient (for Spring Boot)

3. **Verify client-side load balancing:** Spring Cloud LoadBalancer should be on the classpath

### Enable Debug Logging

To get more detailed Eureka logs in your application, add to your `application.yaml`:

```yaml
logging:
  level:
    com.netflix.discovery: DEBUG
    com.netflix.eureka: DEBUG
```

For the Eureka server, edit the deployment and add environment variables:

```bash
kubectl set env deployment/eureka -n eureka LOGGING_LEVEL_COM_NETFLIX_EUREKA=DEBUG
```

## Getting Help

- [#oracle-db-microservices Slack channel](https://oracledevs.slack.com/archives/C06L9CDGR6Z) in the Oracle Developers slack workspace.
- [Open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).
