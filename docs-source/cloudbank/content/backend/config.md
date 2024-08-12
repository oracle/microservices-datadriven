+++
archetype = "page"
title = "Explore Spring Config Server"
weight = 7
+++

The Spring Config Server can be used to store configuration information for Spring Boot applications, so that the configuration can be injected at runtime.  It organized the configuration into properties, which are essentially key/value pairs.  Each property can be assigned to an application, a moduleel, and a profile.  This allows a running application to be configured based on metadata which it will send to the Spring Config Server to obtain the right configuration data.

The configuration data is stored in a table in the Oracle Autonomous Database instance associated with the backend.

1. Look at the configuration data

    Execute the query below by pasting it into the SQL worksheet in Database Actions (which you learned how to open in Task 2 above) and clicking on the green circle "play" icon.  This query shows the externalized configuration data stored by the Spring Config Server.

    ```sql
    select * from configserver.properties
    ```  

   ![Configuration data](../images/obaas-config-server-table.png " ")

   In this example you can see there is an application called `fraud`, which has two configuration properties for the profile `kube` and moduleel `latest`.
