---
title: Build and Push the application
sidebar_position: 3
---
## Build and Push the application

:::important
This content is TBD
:::

This section explains how to build and push the container image for deployment on OBaaS. The following are required:

- Access to a container image repository (e.g., OCIR or another approved registry)
- Docker running locally (and authenticated to your registry)

## Add JKube to the `pom.xml`

The image will be built using JKube and Maven. Add the following plugin into the `pom.xml` for the application.

The following needs to be updated to reflect your environment:

- Image configuration: a mandatory, unique Docker repository name. This can include registry and tag parts, but also placeholder parameters. The example below has the following value: `region/tenancy/repository/phonebook:${project.version}`
- The base image which should be used for this image. In this example, `ghcr.io/oracle/openjdk-image-obaas:21` is used.
- Assembly mode: how the assembled files should be collected. In this example, files are simply copied (`dir`).
- Command: A command to execute by default. In the example below, `java -jar /deployments/${project.artifactId}-${project.version}.jar` will be executed.

Refer to the [documentation for JKube](https://eclipse.dev/jkube/docs/kubernetes-maven-plugin/) for more configuration options.

```xml
<plugin>
  <groupId>org.eclipse.jkube</groupId>
  <artifactId>kubernetes-maven-plugin</artifactId>
  <version>1.18.1</version>
  <configuration>
    <images>
      <image>
        <name>sjc.ocir.io/maacloud/repository/phonebook:${project.version}</name>
        <build>
          <from>ghcr.io/oracle/openjdk-image-obaas:21</from>
          <assembly>
            <mode>dir</mode>
            <targetDir>/deployments</targetDir>
          </assembly>
          <cmd>java -jar /deployments/${project.artifactId}-${project.version}.jar</cmd>
        </build>
      </image>
    </images>
  </configuration>
</plugin>
```

## Build and push the application

To build and push the application execute the following command:

```shell
mvn clean package k8s:build k8s:push
```

If the build and push is successful, you should get a message similar to this:

```log
[INFO] k8s: Pushed sjc.ocir.io/maacloud/phonebook/phonebook:0.0.1-SNAPSHOT in 4 minutes and 2 seconds 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  04:07 min
[INFO] Finished at: 2025-09-24T12:18:53-05:00
[INFO] ------------------------------------------------------------------------
```
