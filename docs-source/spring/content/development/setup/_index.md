
This page provides details on how to set up your development environment to work with
Oracle Backend for Spring Boot. 

The following platforms are recommended for a development environment:

- Windows 10 or 11, preferrably with Windows Subsystem for Linux 2
- macOS (11 or later recommended) on Intel or Apple silicon
- Linux, e.g., Oracle Linux, Ubuntu, etc.

The following tools are recommended for a development environment:

- Integrated Development Environment, e.g., Visual Studio Code
- Java Development Kit, e.g., Oracle, OpenJDK, or GraalVM 
- Maven or Gradle for build and testing automation

If you wish to test locally or offline, the following additional tools are recommended:

- A container platform, e.g., Rancher Desktop
- An Oracle Database (in a container)

## Integrated Development Environment

Oracle recommends Visual Studio Code, which you can download [here](https://code.visualstudio.com/), and
the following extensions to make it easier to write and build your code:

- [Spring Boot Extension Pack](https://marketplace.visualstudio.com/items?itemName=pivotal.vscode-boot-dev-pack)
- [Extension Pack for Java](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-java-pack)
- [Oracle Developer Tools](https://marketplace.visualstudio.com/items?itemName=Oracle.oracledevtools)

You can install these by opening the extensions tab (Ctrl-Shift-X or equivalent) and using the
search bar at the top to find and install them.

## Java Development Kit

Oracle recommends the [Java SE Development Kit](https://www.oracle.com/java/technologies/downloads/#java17).
If you are using Spring Boot version 2.x, then Java 11 is recommended.
If you are using Spting Boot version 3.x, then Java 17 is recommended, not that Spring Boot
3.0 requires at least Java 17.

Even if you are using Spring Boot 2.x, Oracle encourages you to use at least Java 17, unless
you have a specific reason to stay on Java 11. 

You can download the latest x64 Java 17 Development Kit from
[this permalink](https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz).

Decompress the archive in your chosen location, e.g., your home directory and then add it to your path:

```
export JAVA_HOME=$HOME/jdk-17.0.3
export PATH=$JAVA_HOME/bin:$PATH
```

You can verify it is installed with this command:

```
$ java -version
java version "17.0.3" 2022-04-19 LTS
Java(TM) SE Runtime Environment (build 17.0.3+8-LTS-111)
Java HotSpot(TM) 64-Bit Server VM (build 17.0.3+8-LTS-111, mixed mode, sharing)
```

**Note: Native Images:** If you want to compile your Spring Boot microservices into native
images (which was officially supported from Spring Boot 3.0), you must use GraalVM, which can be
downloaded [from here](https://www.graalvm.org/downloads/).

## Maven

words here
