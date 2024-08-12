+++
archetype = "page"
title = "Install Maven"
weight = 4
+++

You can use either Maven or Gradle to build your Spring Boot applications. If you prefer Maven, follow the steps in this task.  If you prefer Gradle, skip to the next task instead.

1. Download Maven

   Download Maven from the [Apache Maven website](https://maven.apache.org/download.cgi).  

2. Install Maven

   Decompress the archive in your chosen location, e.g., your home directory and then add it to your path (the exact version of maven might differ in your environment):

    ```shell
    $ export PATH=$HOME/apache-maven-3.8.6/bin:$PATH
    ```

3. Verify installation

   You can verify it is installed with this command (note that your version may give slightly different output):

    ```shell
    $ mvn -v
    Apache Maven 3.8.6 (84538c9988a25aec085021c365c560670ad80f63)
    Maven home: /home/mark/apache-maven-3.8.6
    Java version: 21.0.3, vendor: Oracle Corporation, runtime: /home/mark/jdk-21.0.3
    Default locale: en, platform encoding: UTF-8
    OS name: "linux", version: "5.10.102.1-microsoft-standard-wsl2", arch: "amd64", family: "unix"
    ```

