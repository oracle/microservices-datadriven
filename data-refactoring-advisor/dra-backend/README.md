## Data Refactoring Advisor Back End

A Spring Boot Service that provides Property Graph and Community Detection support. It connects to an Oracle Autonomous Database instance.


## Build

```
mvn compile
```

## Configure
Update resources/application.properties. 

```
# Oracle settings

spring.datasource.hostname=adb.us-ashburn-1.oraclecloud.com
spring.datasource.port=1521
spring.datasource.service.name=clouddbinstance_dbname_dbservicelevel.adb.oraclecloud.com

spring.datasource.url=jdbc:oracle:thin:@dbname_dbservicelevel?tns_admin=/Users/myuser/remotedb-wallet
spring.datasource.username=ADMIN
spring.datasource.password=Welcome12345
spring.datasource.driver-class=oracle.jdbc.driver.OracleDriver

dra.load.sts.sql.file.path=/Users/loacalpath/datarefactoringadvisor/dra-backend/src/main/resources/workload-simulate-queries.sql
```


This information can be found on the Database Connection window in the OCI Console. 

hostname and service.name come directly from the connection string.

datasource.url is a substring of the service name and tns_admin is the location of the wallet.

Modify local wallet! Edit sqlnet.ora and update DIRECTORY to the wallet
```
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY =/Users/myuser/remotedb-wallet ")))SSL_SERVER_DN_MATCH=yes
```

dra.load.sts.sql.file.path is the local path to a workload simulator SQL file called workload-simulate-queries.sql

## Run
```
./mvnw spring-boot:run 
```

## Success
```
2024-06-06 16:15:19 INFO  o.s.b.d.a.OptionalLiveReloadServer - LiveReload server is running on port 35729
2024-06-06 16:15:19 INFO  o.s.b.w.e.tomcat.TomcatWebServer - Tomcat started on port(s): 8080 (http) with context path ''
2024-06-06 16:15:19 INFO  com.example.dra.DraApplication - Started DraApplication in 5.855 seconds (process running for 6.326)
```