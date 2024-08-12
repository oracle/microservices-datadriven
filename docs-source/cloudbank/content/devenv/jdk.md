+++
archetype = "page"
title = "Install JDK"
weight = 3
+++

Oracle recommends the [Java SE Development Kit](https://www.oracle.com/java/technologies/downloads/#java21).
Themoduleis using Spring Boot 3.3.x so Java 21 is required.

1. Download and install the Java Development Kit

   Download the latest x64 Java 21 Development Kit from [Java SE Development Kit](https://www.oracle.com/java/technologies/downloads/#java21).

   Decompress the archive in your chosen location, e.g., your home directory and then add it to your path (the exact version of Java might differ in your environment):

    ```shell
    
    export JAVA_HOME=$HOME/jdk-21.0.3
    export PATH=$JAVA_HOME/bin:$PATH
    ```

2. Verify the installation

   Verify the Java Development Kit is installed with this command (the exact version of Java might differ in your environment):

    ```shell
    $ java -version
    java version "21.0.3" 2022-04-19 LTS
    Java(TM) SE Runtime Environment (build 21.0.3+8-LTS-111)
    Java HotSpot(TM) 64-Bit Server VM (build 21.0.3+8-LTS-111, mixed mode, sharing)
    ```

    > **Note: Native Images:** If you want to compile your Spring Boot microservices into native images, you must use GraalVM, which can be downloaded [from here](https://www.graalvm.org/downloads/).

