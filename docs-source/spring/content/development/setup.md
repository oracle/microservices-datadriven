---
title: "Development Environment Setup"
description: "How to set up your development environment to build Spring Boot applications with the Oracle Backend for Spring Boot and Microservices"
keywords: "development environment setup spring springboot microservices oracle backend java maven gradle ide tools"
---

This page provides details on how to set up your development environment to work with Oracle Backend for Spring Boot and Microservices.

The following platforms are recommended for a development environment:

- Microsoft Windows 10 or 11, preferably with Windows Subsystem for Linux 2
- macOS (11 or later recommended) on Intel or Apple silicon
- Linux, for example Oracle Linux, Ubuntu, and so on.

The following tools are recommended for a development environment:

- Integrated Development Environment, for example Visual Studio Code
- Java Development Kit, for example Oracle, OpenJDK, or GraalVM
- Maven or Gradle for build and testing automation

If you wish to test locally or offline, then the following additional tools are recommended:

- A container platform, for example Rancher Desktop
- An Oracle database (in a container)

## Integrated Development Environment

Oracle recommends Visual Studio Code, which you can download [here](https://code.visualstudio.com/), and the following extensions to make it easier to write and build your code:

- [Spring Boot Extension Pack](https://marketplace.visualstudio.com/items?itemName=pivotal.vscode-boot-dev-pack)
- [Extension Pack for Java](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-java-pack)
- [Oracle Developer Tools](https://marketplace.visualstudio.com/items?itemName=Oracle.oracledevtools)

You can install these by opening the extensions tab (Ctrl-Shift-X or equivalent) and using the search bar at the top to find and install them.

## Java Development Kit

Oracle recommends the [Java SE Development Kit](https://www.oracle.com/java/technologies/downloads/#java17) or [GraalVM](https://www.graalvm.org/downloads/#). Java 17 or 21 are recommended, note that Spring Boot 3.0 requires at least Java 17. If you want to use JVM Virtual Threads, then Java 21 is required.

**Note**: If you are using Spring Boot 2.x, then Oracle encourages you to use at least Java 17, unless you have a specific reason to stay on Java 11. Refer to the [Spring Boot Support](https://spring.io/projects/spring-boot#support) page for information on support dates for Spring Boot 2.x.

You can download the latest x64 Java 17 Development Kit from
[this permalink](https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz).

Decompress the archive in your chosen location (for example your home directory) and then add it to your path:

```bash
export JAVA_HOME=$HOME/jdk-17.0.3
export PATH=$JAVA_HOME/bin:$PATH
```

Use the following command to verify it is installed:

```bash
$ java -version
java version "17.0.3" 2022-04-19 LTS
Java(TM) SE Runtime Environment (build 17.0.3+8-LTS-111)
Java HotSpot(TM) 64-Bit Server VM (build 17.0.3+8-LTS-111, mixed mode, sharing)
```

**Note: Native Images:** If you want to compile your Spring Boot microservices into native
images (which was officially supported from Spring Boot 3.0), then you must use GraalVM, which can be
downloaded [from here](https://www.graalvm.org/downloads/).

## Maven

You can use either Maven or Gradle to build your Spring Boot applications. If you prefer Maven, then follow the steps in this section. If you prefer Gradle, then refer to the next section.

Download Maven from the [Apache Maven website](https://maven.apache.org/download.cgi).

Decompress the archive in your chosen location (for example your home directory) and then add it to your path:

```bash
$ export PATH=$HOME/apache-maven-3.8.6/bin:$PATH
```

Use the following command to verify it is installed (note that your version may give slightly different output):

```bash
$ mvn -v
Apache Maven 3.8.6 (84538c9988a25aec085021c365c560670ad80f63)
Maven home: /home/mark/apache-maven-3.8.6
Java version: 17.0.3, vendor: Oracle Corporation, runtime: /home/mark/jdk-17.0.3
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "5.10.102.1-microsoft-standard-wsl2", arch: "amd64", family: "unix"
```

## Gradle

Download Gradle using the [instructions on the Gradle website](https://gradle.org/install/). Spring Boot is compatible with Gradle version 7.5 or later.

Run the following command to verify that Gradle is installed correctly

```bash
$ gradle -v

------------------------------------------------------------
Gradle 7.6
------------------------------------------------------------

Build time:   2022-11-25 13:35:10 UTC
Revision:     daece9dbc5b79370cc8e4fd6fe4b2cd400e150a8

Kotlin:       1.7.10
Groovy:       3.0.13
Ant:          Apache Ant(TM) version 1.10.11 compiled on July 10 2021
JVM:          17.0.3 (Oracle Corporation 17.0.3+8-LTS-111)
OS:           Linux 5.10.102.1-microsoft-standard-WSL2 amd64
```

## Oracle Database in a container for local testing

If you want to run an instance of Oracle Database locally for development and testing, then Oracle recommends Oracle Database 23c Free.  You can start the database in a container with this
command specifying a secure password:

```bash
docker run --name free23c -d \
   -p 1521:1521 \
   -e ORACLE_PWD=Welcome12345 \
   container-registry.oracle.com/database/free:latest
```

**Note**: If you are using testcontainers, then add the following dependency to your application:

```xml
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>oracle-free</artifactId>
    <version>1.19.2</version>
    <scope>test</scope>
</dependency>
```
