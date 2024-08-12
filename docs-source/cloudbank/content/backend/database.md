+++
archetype = "page"
title = "Explore Oracle Autonomous Database"
weight = 3
+++

Oracle Backend for Spring Boot and Microservices includes an Oracle Autonomous Database instance.  You can manage and access the database from the OCI Console.

1. View details of the Oracle Autonomous Database

   In the OCI Console, in the main ("hamburger") menu navigate to the **Oracle Database** category and then **Oracle Autonomous Database**.  Make sure you have the correct region selected (in the top right corner) and the compartment where you installed Oracle Backend for Spring Boot and Microservices (on the left hand side pull down list).  You will a list of Oracle Autonomous Database instances (you will probably only have one):

   ![List of Oracle Autonomous Database instances](../images/obaas-adb-1.png " ")

   Click on the database name link to view more information about that instance.  ON this page, you can see important information about your Oracle Autonomous Database instance, and you can manage backups, access and so on.  You can also click on the **Performance Hub** button to access information about the performance of your database instance.

   ![Details of Oracle Autonomous Database instance](../images/obaas-adb-2.png " ")

   You can manage scaling from here by clicking on the **Manage resource allocation** button which will open this form where you can adjust the ECPU and storage for the Autonomous Database instance.  

   ![Manage scaling](../images/obaas-adb-2a.png " ")

2. Explore Oracle Backend for Spring Boot and Microservices database objects

   Click on the **Database Actions** button and select SQL to open a SQL Worksheet.  

   ![SQL](../images/db-action-sql.png)

   Depending on choices you made during installation, you may go straight to SQL Worksheet, or you may need to enter credentials first.  If you are prompted to login, use the username `ADMIN` and obtain the password from Kubernetes with this command (make sure to change the secret name to match the name you chose during installation):

    ```shell
    $  kubectl -n application get secret obaasdevdb-db-secrets -o jsonpath='{.data.db\.password}' | base64 -d
    ```

   ![Database Actions login page](../images/obaas-adb-3.png " ")

   In the SQL Worksheet, you can the first pull down list in the **Navigator** on the left hand side to see the users and schema in the database.  Choose the **CONFIGSERVER** user to view tables (or other objects) for that user.  This is the user associated with the Spring Config Server.

   Execute this query to view tables associated with various Spring Boot services and the CloudBank:

    ```sql
    select owner, table_name
   from dba_tables
   where owner in ('ACCOUNT', 'CUSTOMER', 'CONFIGSERVER', 'AZNSERVER')
    ```  

   ![Tables associated with Spring Boot services](../images/obaas-adb-5.png " ")

   Feel free to explore some of these tables to see the data.

