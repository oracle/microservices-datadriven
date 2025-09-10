# OBaaS 2.0 Container Image Build Guide

## Overview

This guide documents the client-side container image building approach for OBaaS 2.0's hybrid architecture. Each framework uses different tooling to build and push container images to Oracle Cloud Registry, while maintaining a consistent developer experience.

## Prerequisites

- Java 17 or later
- Maven 3.8 or later
- Docker or Podman
- Oracle Cloud Registry access and authentication
- kubectl configured with cluster access

## Registry Configuration

All services use these common properties:

```xml
<properties>
    <obaas.registry>us-phoenix-1.ocir.io/tenancy</obaas.registry>
    <obaas.image.version>0.0.1</obaas.image.version>
</properties>
```

## Spring Boot Services (Account Service)

### Technology Stack
- **Framework**: Spring Boot 3.x
- **Build Tool**: Spring Boot Maven Plugin with Cloud Native Buildpacks
- **Package Type**: Fat JAR
- **Container Strategy**: Buildpacks (automatic optimization)

### POM Configuration

```xml
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <configuration>
        <image>
            <name>${obaas.registry}/${project.artifactId}:${obaas.image.version}</name>
            <publish>false</publish>
        </image>
    </configuration>
</plugin>
```

### Commands

```bash
# Build JAR and container image
mvn clean package spring-boot:build-image

# Push to Oracle Cloud Registry
docker push us-phoenix-1.ocir.io/tenancy/account:0.0.1
```

### Output
- **JAR**: `target/account-0.0.1-SNAPSHOT.jar` (fat JAR with all dependencies)
- **Image**: Uses optimized buildpacks base image with automatic JVM tuning

## Helidon Services (Customer Service)

### Technology Stack
- **Framework**: Helidon MP 4.2.3
- **Build Tool**: Eclipse JKube Kubernetes Maven Plugin
- **Package Type**: Thin JAR + libs directory
- **Container Strategy**: JKube generator with Helidon detection

### POM Configuration

```xml
<properties>
    <jkube.version>1.14.0</jkube.version>
</properties>

<plugin>
    <groupId>org.eclipse.jkube</groupId>
    <artifactId>kubernetes-maven-plugin</artifactId>
    <version>${jkube.version}</version>
    <configuration>
        <images>
            <image>
                <name>${obaas.registry}/${project.artifactId}:${obaas.image.version}</name>
                <build>
                    <from>quay.io/jkube/jkube-java:0.0.19</from>
                </build>
            </image>
        </images>
    </configuration>
</plugin>
```

### Environment Setup (macOS with Rancher Desktop)

```bash
# Set Docker host for JKube compatibility
export DOCKER_HOST=unix:///Users/$USER/.rd/docker.sock
```

### Commands

```bash
# Build thin JAR and libs
mvn clean package

# Build container image
mvn k8s:build

# Push to Oracle Cloud Registry
docker push us-phoenix-1.ocir.io/tenancy/customer-helidon:1.0-SNAPSHOT
```

### Output
- **JAR**: `target/customer-helidon.jar` (thin JAR)
- **Dependencies**: `target/libs/` (all dependencies)
- **Deployment**: `target/customer-helidon-deployment.zip`
- **Image**: Uses JKube Java base image with automatic Helidon configuration

## Alternative: Helidon with Jib

For environments where JKube has Docker connectivity issues:

### POM Configuration

```xml
<plugin>
    <groupId>com.google.cloud.tools</groupId>
    <artifactId>jib-maven-plugin</artifactId>
    <version>3.4.0</version>
    <configuration>
        <to>
            <image>${obaas.registry}/${project.artifactId}:${obaas.image.version}</image>
        </to>
        <container>
            <mainClass>io.helidon.microprofile.cdi.Main</mainClass>
            <ports>
                <port>8080</port>
            </ports>
        </container>
    </configuration>
</plugin>
```

### Commands

```bash
# Build and push directly (no Docker daemon required)
mvn compile jib:build
```



## Authentication

### Oracle Cloud Registry Login

```bash
docker login us-phoenix-1.ocir.io
# Username: <tenancy-namespace>/<username>
# Password: <auth-token>
```

## Troubleshooting

### Common Issues

#### Spring Boot: Buildpacks Authentication Issues
**Symptom**: "Anonymous users are only allowed read access"
**Solution**: Use separate build and push:
```bash
mvn clean package spring-boot:build-image
docker push <image-name>
```

#### Helidon: Docker Connectivity Issues
**Symptom**: "No DOCKER_HOST given"
**Solution**: Export Docker host for Rancher Desktop:
```bash
export DOCKER_HOST=unix:///Users/$USER/.rd/docker.sock
```

#### JKube: Wrong Image Name
**Symptom**: Image tagged as `example/customer-helidon:latest`
**Solution**: Add build configuration to JKube plugin as shown above

## OBaaS 2.0 Hybrid Workflow

### Phase 1: Client-Side (Build & Push)

```bash
# Spring Boot
mvn clean package spring-boot:build-image
docker push us-phoenix-1.ocir.io/tenancy/account:0.0.1

# Helidon
mvn clean package k8s:build
docker push us-phoenix-1.ocir.io/tenancy/customer-helidon:1.0-SNAPSHOT
```

### Phase 2: Server-Side (Deploy)

```bash
# Orchestrated deployment via OBaaS server
mvn obaas:deploy
```

## Benefits by Framework

### Spring Boot
- **Mature Tooling**: Built-in buildpacks support
- **Automatic Optimization**: JVM tuning, security updates
- **Cross-Platform**: Works on any OS
- **Layer Caching**: Efficient rebuilds

### Helidon
- **Thin JAR Benefits**: Better Docker layer caching
- **Framework Support**: JKube has native Helidon detection
- **Flexibility**: Choice between JKube and Jib
- **Lightweight**: Smaller base images

## Performance Comparison

| Aspect | Spring Boot | Helidon |
|--------|-------------|---------|
| **Build Time** | ~30-60 seconds | ~30-45 seconds |
| **Image Size** | ~150-200 MB | ~120-150 MB |
| **Startup Time** | ~3-5 seconds | ~2-4 seconds |
| **Memory Usage** | Higher (fat JAR) | Lower (thin JAR) |
| **Layer Caching** | Good | Excellent |

Both approaches provide fast, reliable container image building suitable for enterprise CI/CD pipelines and local development workflows.