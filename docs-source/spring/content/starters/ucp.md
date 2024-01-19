---
title: "Oracle Spring Boot Starter for Universal Connection Pool"
keywords: "starter springboot datasource ucp spring development microservices development oracle database"
---

This starter provides a connection (data source) to an Oracle Database using Universal Connection Pool, which provides an efficient way
to use database connections.

To add this starter to your project, add this Maven dependency:

```xml
<dependency>
    <groupId>com.oracle.database.spring</groupId>
    <artifactId>oracle-spring-boot-starter-ucp</artifactId>
    <version>23.4.0</version>
</dependency>
```

For Gradle projects, add this dependency:

```gradle
implementation 'com.oracle.database.spring:oracle-spring-boot-starter-ucp:23.4.0'
```

An Oracle data source is injected into your application and can be used normally. You must configure
the data source as shown below, and you should also add either Spring Data JDBC or Spring Data JPA to your project.

To configure the data source, provide a `spring.datasource` object in your Spring `application.yaml`,
or equivalent, as shown in the following example.  The `oracleucp` entry is optional, and can be used
to fine tune the configuration of the connection pool, if desired.  For details of available settings,
refer to the [JavaDoc](https://docs.oracle.com/en/database/oracle/oracle-database/21/jjuar/oracle/ucp/jdbc/UCPDataSource.html).

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.dialect.OracleDialect
        format_sql: true
    show-sql: true
  datasource:
    url: jdbc:oracle:thin:@//myhost:1521/pdb1
    username: account
    password: account
    driver-class-name: oracle.jdbc.OracleDriver
    type: oracle.ucp.jdbc.PoolDataSource
    oracleucp:
      connection-factory-class-name: oracle.jdbc.pool.OracleDataSource
      connection-pool-name: AccountConnectionPool
      initial-pool-size: 15
      min-pool-size: 10
      max-pool-size: 30
```

The `spring.datasource.url` can be in the basic format (as previously shown), or in TNS format if your application
uses Transparent Network Substrate (TNS).

Note that the connections to the database use the `DEDICATED` server by default.  If you wish to use `SHARED` or `POOLED`, you can append that to the basic URL, or add it to the TNS names entry.  For example, to use database resident pooled connections, you would change the URL shown in the previous example to the following:

```yaml
  datasource:
    url: jdbc:oracle:thin:@//myhost:1521/pdb1:pooled
```

If you are using TNS, add `server=pooled` to the `connect_data`. For example:

```text
mydb_tp = (description=
 (retry_count=20)
 (retry_delay=3)
 (address=(protocol=tcps)(port=1521)(host=myhost))
 (connect_data=(service_name=pdb1)(server=pooled))
 (security=(ssl_server_dn_match=yes)))
```

If you prefer to use Java configuration, the data source can be configured as shown in the following example:

```java
import oracle.jdbc.pool.OracleDataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;
import java.sql.SQLException;

@Configuration
public class DataSourceConfiguration {

    @Bean
    public DataSource dataSource() throws SQLException {
        OracleDataSource dataSource = new OracleDataSource();
        dataSource.setUser("account");
        dataSource.setPassword("account");
        dataSource.setURL("jdbc:oracle:thin:@//myhost:1521/pdb1");
        dataSource.setDataSourceName("AccountConnectionPool");
        return dataSource;
    }
}
```
