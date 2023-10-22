---
title: "Configuration Server"
---

Oracle Backend for Spring Boot and Microservices includes Spring Cloud Config which provides server- and client-side support for externalized
configurations in a distributed system. The Spring Cloud Config server provides a central place to manage external properties for applications
across all environments.

The Spring Cloud Config server is pre-configured to work with the Spring Boot Eureka service registry, and it is configured to store the
configuration in the Oracle Autonomous Database, so it easily supports labelled versions of configuration
environments, as well as being accessible to a wide range of tools for managing the content.
Configuration is stored in the `CONFIGSERVER` schema in the `PROPERTIES` table.

For example, the Spring Cloud Config client's Spring `application.yaml` configuration file could include ([Spring Cloud Config Documentation](https://spring.io/projects/spring-cloud-config)):

```yaml
spring:
  application:
    name: application-a

  profiles:
    active: jdbc

  config:
    import: optional:configserver:http://config-server.config-server.svc.cluster.local:8080
```

Managing the data for the Spring Cloud Config server should be done using the CLI or via the REST API endpoints. If you prefer, you can also work directly with the `CONFIGSERVER.PROPERTIES` table in the database. ([Accessing the database](../../database/)).

During setup of Oracle Backend for SPring Boot and Microservices the following data is loaded into `CONFIGSERVER.PROPERTIES`. This data can be deleted.

```code
| APPLICATION     | PROFILE        | LABEL    | PROP_KEY            | VALUE
|-----------------|----------------|----------|---------------------|-----------------------------------|
| atael           | dev            | latest   | test-property       | This is the test-property value   |  
| atael           | dev            | latest   | test-property-2     | This is the test-property-2 value |
| application-a   | production     | 12c      | db-name             | databasename-a-prod               |
| application-a   | production     | 12c      | db-connection       | connectionstring-a-prod           |
| application-a   | development    | 23cbeta  | db-dev-name         | databasename-a-dev                |
| application-a   | development    | 23cbeta  | db-dev-connection   | connectionstring-a-dev            |
| application-b   | production     | 19c      | db-name             | databasename-b-prod               |
| application-b   | production     | 19c      | db-connection       | connectionstring-b-prod           |
| application-b   | development    | 23cbeta  | db-dev-name         | databasename-b-dev                |
| application-b   | development    | 23cbeta  | db-dev-connection   | connectionstring-b-dev            |
| application-c   | secret         | 23.4     | json-db             | 23c-json-db                       |
| application-c   | secret         | 23.4     | json-sdb-conn       | 23c-mongo-conn                    |
| application-c   | secret         | 23.4     | txenventq           | 23c-conn-string                   |
| application-c   | secret         | 23.4     | txeventq            | 23c-kafka-name                    |
```

## Config Server REST endpoints overview

The following REST Endpoints are available to Config Server entries. The table lists which minimum required role that is needed to perform the operation. `N/A` in the table below means that endpoint doesn't require authentication to be accessed.

| End point                     | Method | Description                                             | Minimum Required Role |
|-------------------------------|--------|---------------------------------------------------------|-----------------------|
| /srv/config/all               | GET    | Get all distinct properties for a service (application) | N/A                   |
| /srv/config/properties        | GET    | Get all distinct properties with filters (see examples) | N/A                   |
| /srv/config/properties/add    | POST   | Create properties from a file                           | ROLE_USER             |
| /srv/config/property/add      | POST   | Create a property                                       | ROLE_USER             |
| /srv/config/property/update   | PUT    | Update a property                                       | ROLE_USER             |
| /srv/config/properties/delete | DELETE | Delete properties with filters (see examples)           | ROLE_ADMIN            |

### Config Server REST endpoints examples

In all examples below you need to replace `<username>:<password>` with your username and password when necessary. ([Getting User information](../../security/azn-server/)). The examples are using `curl` to interact with the REST endpoints. They also requires that you have opened a tunnel on port 8080 to either the `config-server` or `obaas-admin` service. For example:

```shell
kubectl port-forward -n obaas-admin svc/obaas-admin 8080
```

#### /srv/config/all

Get all distinct application services.

```shell
curl -s http://localhost:8080/srv/config/all
```

Example of data returned:

```json
[
  {
    "name": "application-a",
    "label": "",
    "profile": ""
  },
  {
    "name": "application-b",
    "label": "",
    "profile": ""
  },
  {
    "name": "application-c",
    "label": "",
    "profile": ""
  },
  {
    "name": "atael",
    "label": "",
    "profile": ""
  }
]
```

#### /srv/config/all?service-profile=\<profile-name\>

Get all distinct services filtered on profile(service-profile).

```shell
curl -s http://localhost:8080/srv/config/all? \
  service-profile=dev
```

Example of data returned:

```json
[
  {
    "name": "atael",
    "label": "latest",
    "profile": "dev"
  }
]
```

#### /srv/config/properties?service-name=\<service-name\>

Get all properties for a service-name(application).

```shell
curl -s http://localhost:8080/srv/config/properties? \
  service-name=application-a
```

Example of data returned:

```json
[
  {
    "id": 3,
    "application": "application-a",
    "profile": "production",
    "label": "12c",
    "propKey": "db-name",
    "value": "databasename-a-prod",
    "createdOn": "2023-10-19T16:50:07.000+00:00",
    "createdBy": "ADMIN"
  },
  {
    "id": 4,
    "application": "application-a",
    "profile": "production",
    "label": "12c",
    "propKey": "db-connection",
    "value": "connectionstring-a-prod",
    "createdOn": "2023-10-19T16:50:07.000+00:00",
    "createdBy": "ADMIN"
  },
  {
    "id": 5,
    "application": "application-a",
    "profile": "development",
    "label": "23cbeta",
    "propKey": "db-dev-name",
    "value": "databasename-a-dev",
    "createdOn": "2023-10-19T16:50:07.000+00:00",
    "createdBy": "ADMIN"
  },
  {
    "id": 6,
    "application": "application-a",
    "profile": "development",
    "label": "23cbeta",
    "propKey": "db-dev-connection",
    "value": "connectionstring-a-dev",
    "createdOn": "2023-10-19T16:50:07.000+00:00",
    "createdBy": "ADMIN"
  }
]
```

#### /srv/config/properties?service-name=\<service-name\>&service-label=\<service-label\>

Get all properties for a service-name(application) filtered on service-label(label).

```shell
curl -s http://localhost:8080/srv/config/properties? \
  service-name=application-b& \
  service-label=19c
```

Example of data returned:

```json
[
  {
    "id": 7,
    "application": "application-b",
    "profile": "production",
    "label": "19c",
    "propKey": "db-name",
    "value": "databasename-b-prod",
    "createdOn": "2023-10-19T16:50:07.000+00:00",
    "createdBy": "ADMIN"
  },
  {
    "id": 8,
    "application": "application-b",
    "profile": "production",
    "label": "19c",
    "propKey": "db-connection",
    "value": "connectionstring-b-prod",
    "createdOn": "2023-10-19T16:50:07.000+00:00",
    "createdBy": "ADMIN"
  }
]
```

#### /srv/config/properties?service-name=\<service-name\>&service-label=\<service-label\>&service-profile=\<service-profile\>

Get all properties for a service-name(application) filtered on service-profile(profile) and service-profile(profile).

```shell
curl -s http://localhost:8080/srv/config/properties? \
  service-name=application-b& \
  service-label=19c& \
  service-profile=production
```

Example of data returned:

```json
[
  {
    "id": 7,
    "application": "application-b",
    "profile": "production",
    "label": "19c",
    "propKey": "db-name",
    "value": "databasename-b-prod",
    "createdOn": "2023-10-19T16:50:07.000+00:00",
    "createdBy": "ADMIN"
  },
  {
    "id": 8,
    "application": "application-b",
    "profile": "production",
    "label": "19c",
    "propKey": "db-connection",
    "value": "connectionstring-b-prod",
    "createdOn": "2023-10-19T16:50:07.000+00:00",
    "createdBy": "ADMIN"
  }
]
```

#### /srv/config/properties?service-name=\<service-name\>&service-label=\<service-label\>&service-profile=\<service-profile\>&property-key=\<property-key\>

Get all properties for a service-name(application) filtered on service-profile(profile), service-profile(profile) and property-key(prop_key).

```shell
curl -s http://localhost:8080/srv/config/properties? \
  service-name=application-c& \
  service-label=23.4& \
  service-profile=secret& \
  property-key=txeventq
```

Example of data returned.

```json
[
  {
    "id": 14,
    "application": "application-c",
    "profile": "secret",
    "label": "23.4",
    "propKey": "txeventq",
    "value": "23c-kafka-name",
    "createdOn": "2023-10-19T16:50:07.000+00:00",
    "createdBy": "ADMIN"
  }
]
```

#### /srv/config/property/add

Create a property.

```shell
  curl -u <username>:<password> -s -X POST \
    -d "service-name=application-d&service-label=1.0&service-profile=AI&property-key=url-to-host&property-value=hostname" \
    http://localhost:8080/srv/config/property/add
```

Successful creation of a property returns

```text
Property added successfully.
```

#### /srv/config/property/update

Update a property.

```shell
curl -u <username>:<password> -s -X PUT \
  -d "service-name=application-d&service-label=1.0&service-profile=AI&property-key=url-to-host&property-value=new-hostname" \
   http://localhost:8080/srv/config/property/update
```

Successful update of a property returns

```text
Property successful modified.
```

#### /srv/config/properties/delete?service-name\<service-name\>

Delete all properties from a service (application).

```Shell
curl -u <username>:<password> -s -X DELETE http://localhost:8080/srv/config/properties/delete? \
  service-name=atael
```

Successful delete of properties returns:

```text
Property(ies) successfully deleted.
```

#### /srv/config/delete?service-profile=\<profile-name\>&service-profile=\<service-profile\>

Delete all properties with a service profile.

```Shell
curl -u <username>:<password> -s -X DELETE http://localhost:8080/srv/config/properties/delete? \
  service-name=application-d& \
  service-profile=AI
```

Successful delete of properties returns:

```text
Property(ies) successfully deleted.
```

#### /srv/config/delete?service-profile=\<profile-name\>&service-profile=\<service-profile\>&service-label=\<service-label\>

Delete all properties from a service with a profile and a label.

```Shell
curl -u <username>:<password> -s -X DELETE http://localhost:8080/srv/config/properties/delete? \
  service-name=application-a& \
  service-profile=development& \
  service-label=12c
```

Successful delete of properties returns:

```text
Property(ies) successfully deleted.
```

#### /srv/config/delete?service-profile=\<profile-name\>&service-profile=\<service-profile\>&service-label=\<service-label\>&property-key=\<property-key\>

Delete all properties from a service with a profile and a label.

```Shell
curl -u <username>:<password> -s -X DELETE http://localhost:8080/srv/config/properties/delete? \
  service-name=application-b& \
  service-profile=development& \
  service-label=23cbeta& \
  property-key=db-dev-name
```

Successful delete of properties returns:

```text
Property(ies) successfully deleted.
```

## Recreate test data

The initially created config server data can be created using the following SQL Statements:

```sql
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('atael','dev','latest','test-property','This is the test-property value');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('atael','dev','latest','test-property-2','This is the test-property-2 value');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('application-a','production','12c','db-name','databasename-a-prod');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('application-a','production','12c','db-connection','connectionstring-a-prod');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('application-a','development','23cbeta','db-dev-name','databasename-a-dev');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('application-a','development','23cbeta','db-dev-connection','connectionstring-a-dev');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('application-b','production','19c','db-name','databasename-b-prod');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('application-b','production','19c','db-connection','connectionstring-b-prod');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('application-b','development','23cbeta','db-dev-name','databasename-b-dev');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('application-b','development','23cbeta','db-dev-connection','connectionstring-b-dev');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('application-c','secret','23.4','json-db','23c-json-db');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('application-c','secret','23.4','json-sdb-conn','23c-mongo-conn');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('application-c','secret','23.4','txenventq','23c-conn-string');
INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE) VALUES ('application-c','secret','23.4','txeventq','23c-kafka-name');
```
