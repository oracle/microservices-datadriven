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
      [INFO] CloudBank .......................................... SUCCESS [  1.212 s]
      [INFO] account ............................................ SUCCESS [  3.881 s]
      [INFO] chatbot ............................................ SUCCESS [  0.997 s]
      [INFO] checks ............................................. SUCCESS [  1.697 s]
      [INFO] customer ........................................... SUCCESS [  1.393 s]
      [INFO] creditscore ........................................ SUCCESS [  1.134 s]
      [INFO] transfer ........................................... SUCCESS [  0.589 s]
      [INFO] testrunner ......................................... SUCCESS [  1.179 s]
      [INFO] ------------------------------------------------------------------------
      [INFO] BUILD SUCCESS
      [INFO] ------------------------------------------------------------------------
      [INFO] Total time:  12.439 s
      [INFO] Finished at: 2024-10-10T15:29:41-05:00
      [INFO] ------------------------------------------------------------------------
    ```

