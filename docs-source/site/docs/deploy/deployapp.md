---
title: Deploy the Application
sidebar_position: 4
---
## Deploy the application

:::important
This content is TBD
:::

## Modify the `Chart.yaml`

Modify the `Chart.yaml` file to reflect your application.

```yaml
apiVersion: v2
name: <your application name>       # Replace with your application name
```

## Modify the `values.yaml`

Modify the `values.yaml` file to match your application’s requirements—for example, set image.repository and pullPolicy, configure a service account, enable ingress, define resources and autoscaling, and specify volumes and volumeMounts etc.

The `obaas` section is unique for Oracle Backed for Microservices and AI. It has the following settings:

```yaml
# Oracle Backend for Microservices and AI Settings.
obaas:
  namespace: obaas-dev                      # Replace with your namespace 
  database:
    enabled: true                           # If true variables with DB secret content will be created
    credentialsSecret: account-db-secrets   # Replace with your secret name
    walletSecret: obaas-adb-tns-admin-1     # Replace with your wallet secret name
  otel:
    enabled: true                           # Enable OpenTelemetry
  # MicroProfile LRA
  mp_lra:
    enabled: true                          # Enable OTMM
  # Spring Boot applications
  springboot:
    enabled: true                           # Enable Spring Boot specific variables
  eureka:
    enabled: true                           # Enable Eureka client
```

- OBaaS supports both `SPRING_BOOT` and `HELIDON`. This is set via the `obaas.framework` parameter.
- When `otel.enabled` is true, the `OTEL_EXPORTER_OTLP_ENDPOINT` environment variable is set to the appropriate value and injected into the deployment for application use. This is the URL of the OpenTelemetry (OTLP protocol) collector which can be used by your application to send observability data to the SigNoz platform.
- When `mp_lra.enabled` is true, the following environment variables are set to the appropriate value and injected into the deployment for application use:
  - `MP_LRA_COORDINATOR_URL` This is the URL for the *transaction manager* which is required when using Eclipse Microprofile Long Running Actions in your application.
  - `MP_LRA_PARTICIPANT_URL` This is the *participant* URL which is required when using Eclipse Microprofile Long Running Actions in your application.
- When `springboot.enabled` is true, the following environment variables are set to the appropriate value and injected into the deployment for application use:
  - `SPRING_PROFILES_ACTIVE` This sets the Spring profiles that will be active in the application. The default value is `default`.
  - `SPRING_DATASOURCE_URL` This sets the data source URL for your application to use to connect to the database, for example `jdbc:oracle:thin:@$(DB_SERVICE)?TNS_ADMIN=/oracle/tnsadmin`.
  - `SPRING_DATASOURCE_USERNAME` Set to the value of the key `username` in secret you may have created for your application.
  - `SPRING_DATASOURCE_PASSWORD` Set to the value of the key `password` in secret you may have created for your application.
  - `DB_SERVICE` Set to the value of the key `service` in secret you may have created for your application.
- When `eureka.enabled` is true, the following environment variables are set to the appropriate value and injected into the deployment for the application and the application will register with Eureka.
  - `EUREKA_INSTANCE_PREFER_IP_ADDRESS`
  - `EUREKA_CLIENT_REGISTER_WITH_EUREKA`
  - `EUREKA_CLIENT_FETCH_REGISTRY`
  - `EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE`
  - `EUREKA_INSTANCE_HOSTNAME`
