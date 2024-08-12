+++
archetype = "page"
title = "Build CloudBank"
weight = 3
+++


1. Create application JAR files

    In the directory (root) where you cloned (or unzipped) the application and build the application JARs using the following command:

    ```shell
    mvn clean package
    ```

    The output should be similar to this:

    ```text
    [INFO] ------------------------------------------------------------------------
    [INFO] Reactor Summary for CloudBank 0.0.1-SNAPSHOT:
    [INFO]
    [INFO] CloudBank .......................................... SUCCESS [  0.916 s]
    [INFO] account ............................................ SUCCESS [  2.900 s]
    [INFO] checks ............................................. SUCCESS [  1.127 s]
    [INFO] customer ........................................... SUCCESS [  1.106 s]
    [INFO] creditscore ........................................ SUCCESS [  0.908 s]
    [INFO] transfer ........................................... SUCCESS [  0.455 s]
    [INFO] testrunner ......................................... SUCCESS [  0.942 s]
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    [INFO] Total time:  9.700 s
    [INFO] Finished at: 2024-01-18T15:52:56-06:00
    [INFO] ------------------------------------------------------------------------
    ```

