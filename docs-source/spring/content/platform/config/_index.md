
Oracle Backend as a Service for Spring Cloud includes the Spring Config Server which allows applications to externalize their configuration
and to have the configuration injected at runtime. 

The Spring Config Server is pre-configured to work with the Spring Eureka Service Registry, and it is configured to store the configuration
in the Oracle Autonomous Database.  Configuration is stored in the `CONFIGSERVER` schema in the `PROPERTIES` table.

