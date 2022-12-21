### Creating Database Objects Using the CLI

Setup and start the CLI using the [following instructions](../development/cli/). You need to do the following steps following the CLI Instructions:

* Download the binaries
* Expose the Oracle Spring Admin Server using `port-forward`
* Start the CLI
* Connect to the Oracle Spring Admin Server

#### Create a namespace

```text
oracle-spring:>create
appName (defaults to cloudbank): ataeltest
application/namespace created successfully and image pull secret (registry-auth) created successfully
```

#### Create Database Schema, Users and k8s secrets

```text
oracle-spring:>bind
appName (defaults to cloudbank): ataeltest
database user/serviceName (defaults to bankb): customer
database password/servicePassword (defaults to Welcome12345):
using default value...
springBindingPrefix (defaults to spring.datasource):
using default value...
schema created successfully for customer and database secret (customer-db-secrets) created successfully
```

```text
oracle-spring:>bind
appName (defaults to cloudbank): ataeltest
database user/serviceName (defaults to bankb): fraud
database password/servicePassword (defaults to Welcome12345):
using default value...
springBindingPrefix (defaults to spring.datasource):
using default value...
schema created successfully for fraud and database secret (fraud-db-secrets) created successfully
```

```text
oracle-spring:>bind
appName (defaults to cloudbank): ataeltest
database user/serviceName (defaults to bankb): notification
database password/servicePassword (defaults to Welcome12345):
using default value...
springBindingPrefix (defaults to spring.datasource):
using default value...
schema created successfully for notification and database secret (notification-db-secrets) created successfully
```

The fraud application requires that you execute the `db-03-notifications-db-queue.sql` script using the `ADMIN` user. Connect to the Oracle Autonmous Database instance using (using [these instructions](../database)).

### Create Config Server entries using the CLI

Go the the OCI Console and find out the database name, you're going to need this when creating the Config Server entries. Setup and start the CLI using the [following instructions](../development/cli/) if you haven't done this already. You need to do the following steps following the CLI Instructions:

* Download the binaries
* Expose the Oracle Spring Admin Server using `port-forward`
* Start the CLI
* Connect to the Oracle Spring Admin Server
* Add entries for the Config Server

#### Customer Entries

Replace the DB_NAME in the value field with your daatabase name.

```text
oracle-spring:>config
command ([c]reate, [r]ead all, [u]pdate, [d]elete): c
application: customer
label: latest
profile: kube
propKey: spring.datasource.url
value: jdbc:oracle:thin:@DB_NAME?TNS_ADMIN=/oracle/tnsadmin
{"id":3,"application":"customer","profile":"latest","label":"kube","propKey":"spring.datasource.url","value":"jdbc:oracle:thin:@DB_NAME?TNS_ADMIN=/oracle/tnsadmin","createdOn":"2022-12-21T18:46:25.000+00:00","createdBy":"CONFIGSERVER"}
```

```text
oracle-spring:>config
command ([c]reate, [r]ead all, [u]pdate, [d]elete): c
application: customer
label: latest
profile: kube
propKey: spring.datasource.driver-class-name
value: oracle.jdbc.OracleDriver
{"id":4,"application":"customer","profile":"latest","label":"kube","propKey":"spring.datasource.driver-class-name","value":"oracle.jdbc.OracleDriver","createdOn":"2022-12-21T18:47:42.000+00:00","createdBy":"CONFIGSERVER"}
```

#### Fraud Entries

Replace the DB_NAME in the value field with your daatabase name.

```text
oracle-spring:>config
command ([c]reate, [r]ead all, [u]pdate, [d]elete): c
application: fraud
label: latest
profile: kube
propKey: spring.datasource.url
value: jdbc:oracle:thin:@DB_NAME?TNS_ADMIN=/oracle/tnsadmin
{"id":5,"application":"fraud","profile":"latest","label":"kube","propKey":"spring.datasource.url","value":"jdbc:oracle:thin:@DB_NAME?TNS_ADMIN=/oracle/tnsadmin","createdOn":"2022-12-21T18:49:46.000+00:00","createdBy":"CONFIGSERVER"}
```

```text
oracle-spring:>config
command ([c]reate, [r]ead all, [u]pdate, [d]elete): c
application: fraud
label: latest
profile: kube
propKey: spring.datasource.driver-class-name
value: oracle.jdbc.OracleDriver
{"id":6,"application":"fraud","profile":"latest","label":"kube","propKey":"spring.datasource.driver-class-name","value":"oracle.jdbc.OracleDriver","createdOn":"2022-12-21T18:50:22.000+00:00","createdBy":"CONFIGSERVER"}
```

#### Notification Entries

Replace the DB_NAME in the value field with your daatabase name.

```text
oracle-spring:>config
command ([c]reate, [r]ead all, [u]pdate, [d]elete): c
application: notification
label: latest
profile: kube
propKey: spring.datasource.url
value: jdbc:oracle:thin:@DB_NAME?TNS_ADMIN=/oracle/tnsadmin
{"id":7,"application":"notification","profile":"latest","label":"kube","propKey":"spring.datasource.url","value":"jdbc:oracle:thin:@DB_NAME?TNS_ADMIN=/oracle/tnsadmin","createdOn":"2022-12-21T18:51:47.000+00:00","createdBy":"CONFIGSERVER"}
```

```text
oracle-spring:>config
command ([c]reate, [r]ead all, [u]pdate, [d]elete): c
application: notification
label: latest
profile: kube
propKey: spring.datasource.driver-class-name
value: oracle.jdbc.OracleDriver
{"id":8,"application":"notification","profile":"latest","label":"kube","propKey":"spring.datasource.driver-class-name","value":"oracle.jdbc.OracleDriver","createdOn":"2022-12-21T18:52:20.000+00:00","createdBy":"CONFIGSERVER"}
```

#### Verify the entries

```text
oracle-spring:>config
command ([c]reate, [r]ead all, [u]pdate, [d]elete): r
[{"id":1,"application":"atael","profile":"dev","label":"latest","propKey":"test-property","value":"This is the test-property value","createdOn":"2022-12-21T16:14:44.000+00:00","createdBy":"ADMIN"},{"id":2,"application":"atael","profile":"dev","label":"latest","propKey":"test-property-2","value":"This is the test-property-2 value","createdOn":"2022-12-21T16:14:44.000+00:00","createdBy":"ADMIN"},{"id":3,"application":"customer","profile":"latest","label":"kube","propKey":"spring.datasource.url","value":"jdbc:oracle:thin:@DB_NAME?TNS_ADMIN=/oracle/tnsadmin","createdOn":"2022-12-21T18:46:25.000+00:00","createdBy":"CONFIGSERVER"},{"id":4,"application":"customer","profile":"latest","label":"kube","propKey":"spring.datasource.driver-class-name","value":"oracle.jdbc.OracleDriver","createdOn":"2022-12-21T18:47:42.000+00:00","createdBy":"CONFIGSERVER"},{"id":5,"application":"fraud","profile":"latest","label":"kube","propKey":"spring.datasource.url","value":"jdbc:oracle:thin:@DB_NAME?TNS_ADMIN=/oracle/tnsadmin","createdOn":"2022-12-21T18:49:46.000+00:00","createdBy":"CONFIGSERVER"},{"id":6,"application":"fraud","profile":"latest","label":"kube","propKey":"spring.datasource.driver-class-name","value":"oracle.jdbc.OracleDriver","createdOn":"2022-12-21T18:50:22.000+00:00","createdBy":"CONFIGSERVER"},{"id":7,"application":"notification","profile":"latest","label":"kube","propKey":"spring.datasource.url","value":"jdbc:oracle:thin:@DB_NAME?TNS_ADMIN=/oracle/tnsadmin","createdOn":"2022-12-21T18:51:47.000+00:00","createdBy":"CONFIGSERVER"},{"id":8,"application":"notification","profile":"latest","label":"kube","propKey":"spring.datasource.driver-class-name","value":"oracle.jdbc.OracleDriver","createdOn":"2022-12-21T18:52:20.000+00:00","createdBy":"CONFIGSERVER"}]
```

### Deploy the applications using the CLI

Assuming that you alreay have the CLI running you need to do the following to deploy the applications:

### Customer Application

```text
oracle-spring:>deploy
isRedeploy (has already been deployed) (defaults to true): false
serviceName (defaults to bankb): customer
appName (defaults to cloudbank): ataeltest
jarLocation (defaults to target/bankb-0.0.1-SNAPSHOT.jar): /Users/atael/Documents/GitHub/microservices-datadriven/mbaas-developer-preview/sample-spring-apps/customer/target/customer-0.0.1-SNAPSHOT.jar
imageVersion (defaults to 0.1):
using default value...
javaVersion (defaults to 11): 17
uploading... upload successful
building and pushing image... 500 : "{"timestamp":"2022-12-21T20:28:08.115+00:00","status":500,"error":"Internal Server Error","path":"/dockerBuildAndPush"}"
Details of the error have been omitted. You can use the stacktrace command to print the full stacktrace.
```