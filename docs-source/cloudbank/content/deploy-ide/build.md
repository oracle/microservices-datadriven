+++
archetype = "page"
title = "Build CloudBank"
weight = 3
+++


1. Create application JAR files

    In the directory where you cloned (or unzipped) the application and build the application JARs using the following command:

    ```shell
    <copy>mvn clean package</copy>
    ```

    The output should be similar to this:

    ```text
    [INFO] ------------------------------------------------------------------------
    [INFO] Reactor Summary for cloudbank 0.0.1-SNAPSHOT:
    [INFO]
    [INFO] cloudbank .......................................... SUCCESS [  0.972 s]
    [INFO] account ............................................ SUCCESS [  2.877 s]
    [INFO] chatbot ............................................ SUCCESS [  0.997 s]
    [INFO] customer ........................................... SUCCESS [  1.064 s]
    [INFO] creditscore ........................................ SUCCESS [  0.922 s]
    [INFO] transfer ........................................... SUCCESS [  0.465 s]
    [INFO] testrunner ......................................... SUCCESS [  0.931 s]
    [INFO] checks ............................................. SUCCESS [  0.948 s]
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    [INFO] Total time:  12.439 s
    [INFO] Finished at: 2024-10-10T15:29:41-05:00
    [INFO] ------------------------------------------------------------------------
    ```

