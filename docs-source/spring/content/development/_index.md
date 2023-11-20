This section provides information about how to develop and deploy Spring Boot applications
with the Oracle Backend for Spring Boot and Microservices. 

Spring Boot applications can be developed the normal way, with no special requirements, and
be deployed into Oracle Backend for Spring Boot and Microservices.  However, if you do opt-in to the platform
services provides and the CLI, you can shorten your development time and avoid unnecessary
work.

Oracle Backend for Spring Boot provides the following services that applications can choose
to use: 

- An Oracle Autonomous Database instance in which applications can manage relational,
  document, spatial, graph and other types of data, use Transactional Event Queues for
  messaging and events using JMS, Kafka or REST interfaces, and even run ML models.
- A Kubernetes cluster that applications can run in, with namespaces pre-configured with
  Kubernetes Secrets and ConfigMaps for access to the Oracle Autonomous Database instance
  associated with the backend.
- An APISIX API Gateway that can be used to expose service endpoints outside the Kubernetes
  cluster, to the public internet.  All standard APISIX features like traffic management, 
  monitoring, authentication, and so on, are available for use.
- Spring Eureka Service Registry for service discovery.  The API Gateway and monitoring
  services are pre-configured to use this registry for service discovery.
- Spring Config Server to serve externalized configuration information to applications.
  This is configured to store the configuration data in the Oracle Autonomous Database
  instance associated with the backend.
- Netflix Conductor OSS for running workflows to orchestrate your services.
- Hashicorp Vault for storing sensitive information.
- Spring Admin for monitoring your services.
- Prometheus and Grafana for collecting and visualizing metrics and for alerting. 
- Jaeger for distributed tracing.  Applictions deployed with the Oracle Backend for
  Spring Boot CLI will have the Open Telemetry collector automatically added as a Java
  agent to provide tracing from the application into the Oracle Database. 

An integrated development environment is recommended for developing applications. Oracle
recommend Visual Studio Code or IntelliJ.

Java, Maven or Gradle, a version control system (Oracle recommends git), and other
tools may be required during development.
