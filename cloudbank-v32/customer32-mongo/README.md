# Example of "customer32" reimplemented to use the Oracle Database API for MongoDB

This directory provides an example of the [customer32](../customer32/) service reimplmented using [Oracle Database API for MongoDB](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/mongo-using-oracle-database-api-mongodb.html) and [Spring Data MongoDB](https://docs.spring.io/spring-data/mongodb/reference/index.html).

To run this application, you need to perform some initial setup:

- Create an instance of Oracle Autonomous Database in Oracle Cloud Infrastructure

- [Configure access for MongoDB](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/mongo-using-oracle-database-api-mongodb.html#GUID-49018B09-9712-44DC-A950-B8129E7DA0D2)

- [Enable MongoDB API](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/mongo-using-oracle-database-api-mongodb.html#ADBSB-GUID-2D3D792B-416A-4B3B-A8B6-F888AFA7B9CC)

- Create a user with the necessary permissions to use the MongoDB API as described [here](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/mongo-using-oracle-database-api-mongodb.html#ADBSB-GUID-613DD3CE-6E84-4D8E-B614-2CFC18A41784) and [here](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/mongo-using-oracle-database-api-mongodb.html#ADBSB-GUID-C161A1F8-12CD-4F74-9F7C-423ABF892D8C)

- Navigate to the Autonomous Database details page for your database in the OCI Console and copy the MongoDB API "Access URL" from the "Tool Configuration" page.

- Update the [Spring application configuration](./src/main/resources/application.yaml) to set the correct connection string.  Note that you will have to set the USER, PASSWORD, hostname and region.  You must also set the database name in that file to match the USER.

Once that configuration is done, you can run the application using `mvn spring-boot:run` and try the various APIs, for example:

- Create a customer

    ```shell
    curl -i -X POST -H 'Content-Type: application/json' \
      -d '{"name":"Bob Jones","email":"bob@job.com"}' \
      http://localhost:8080/api/v1mongo/customer
    ```

- List customers

    ```shell
    curl -s http://localhost:8080/api/v1mongo/customer | jq .
    ```

- Update a customer - make sure you use the correct ID from the output of the previous example

    ```shell
    curl -i -X PUT -H 'Content-Type: application/json' \
      -d '{"name":"Bob Jackson","email":"bob@jackson.com"}' \
      http://localhost:8080/api/v1mongo/customer/65cb9ad3d0538471e9fb5f27
    ```

- Find a customer by email

    ```shell
    curl -i http://localhost:8080/api/v1mongo/customer/email/bob@jackson.com
    ```

## Notes on the MongoDB connection

Please refer to the [Spring Data MongoDB documentation](https://docs.spring.io/spring-data/mongodb/reference/mongodb/configuration.html) for details of how to configure the connection and database.  

This example follows the examples provided in that documentation, in particular, the [AppConfig class](./src/main/java/com/example/customer32mongo/config/AppConfig.java) creates a `MongoClient` bean and a `MongoDatabaseFactory` bean as described in the Spring Data MongoDB documentation.