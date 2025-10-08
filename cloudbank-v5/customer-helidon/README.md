# customer-helidon

Helidon MP version of the "customer" microservice built using the **Helidon MP profile** for enterprise Java applications with CDI, JPA, and microservices capabilities.

## Build and run

### Prerequisites
- JDK 21
- Maven 3.8+

### Building the Application

The build process creates a **thin JAR deployment package** as a ZIP file containing the application JAR and all dependencies:

```bash
mvn clean package
```

This creates:
- `target/customer-helidon.jar` - The thin application JAR
- `target/customer-helidon-deployment.zip` - Complete deployment package with structure:
  ```
  customer-helidon.jar          (main application)
  app/
    libs/                       (all dependency JARs)
  ```

### Building and Pushing Container Image

#### Environment Setup (macOS with Rancher Desktop)

```bash
# Set Docker host for JKube compatibility
export DOCKER_HOST=unix:///Users/$USER/.rd/docker.sock
```

#### Commands

```bash
# Build thin JAR and libs
mvn clean package

# Build container image
mvn k8s:build

# Push to Oracle Cloud Registry
docker push us-ashburn-1.ocir.io/maacloud/customer-helidon:5.0-SNAPSHOT
```

#### Output
- **JAR**: `target/customer-helidon.jar` (thin JAR)
- **Dependencies**: `target/libs/` (all dependencies)
- **Deployment**: `target/customer-helidon-deployment.zip`
- **Image**: Uses JKube Java base image with automatic Helidon configuration

### Running the Application

**Option 1: Using the thin JAR (requires dependencies in classpath):**
```bash
# Extract the deployment ZIP first
cd target
unzip customer-helidon-deployment.zip
java -jar customer-helidon.jar
```

**Option 2: Using Maven to run directly:**
```bash
mvn exec:java
```

## Quick Start with Local Oracle Database

To run against a local Oracle Docker container, simply:

1. **Start Oracle Database container:**
   ```bash
   docker run -d --name oracle-db -p 1521:1521 \
       -e ORACLE_PWD=Welcome12345 \
       container-registry.oracle.com/database/free:latest
   ```

2. **Uncomment database configuration** in `src/main/resources/application.yaml`:
   ```yaml
   javax.sql.DataSource.customer.URL = jdbc:oracle:thin:@//localhost:1521/freepdb1
   javax.sql.DataSource.customer.user = customer
   javax.sql.DataSource.customer.password = Welcome12345
   ```

3. **Rebuild and run:**
   ```bash
   mvn clean package
   cd target && unzip customer-helidon-deployment.zip
   java -jar customer-helidon.jar
   ```

The application will automatically create the necessary database tables on startup using Hibernate's DDL auto-generation.

### Basic:
```bash
curl -X GET http://localhost:8080/simple-greet
Hello World!
```

### JSON:
```bash
curl -X GET http://localhost:8080/greet
{"message":"Hello World!"}

curl -X GET http://localhost:8080/greet/Joe
{"message":"Hello Joe!"}

curl -X PUT -H "Content-Type: application/json" -d '{"greeting" : "Hola"}' http://localhost:8080/greet/greeting

curl -X GET http://localhost:8080/greet/Jose
{"message":"Hola Jose!"}
```

### Try health
```bash
curl -s -X GET http://localhost:8080/health
{"outcome":"UP",...
```

### Try metrics
```bash
# Prometheus Format
curl -s -X GET http://localhost:8080/metrics
# TYPE base:gc_g1_young_generation_count gauge
. . .

# JSON Format
curl -H 'Accept: application/json' -X GET http://localhost:8080/metrics
{"base":...
. . .
```

## Building a Native Image

The generation of native binaries requires an installation of GraalVM 22.1.0+.
You can build a native binary using Maven as follows:

```bash
mvn -Pnative-image install -DskipTests
```

The generation of the executable binary may take a few minutes to complete depending on your hardware and operating system. When completed, the executable file will be available under the `target` directory and be named after the artifact ID you have chosen during the project generation phase.

## Docker Support

### Building the Docker Image Locally

**Note:** The `Dockerfile.manual` must be renamed to `Dockerfile` before building locally, as JKube uses the Dockerfile when present.

```bash
# Rename Dockerfile for local build
git mv Dockerfile.manual Dockerfile

# Build the Docker image
docker build -t customer-helidon .

# Rename back to avoid conflicts with JKube builds
git mv Dockerfile Dockerfile.manual
```

### Running the Docker Image
```bash
docker run --rm -p 8080:8080 customer-helidon:latest
```

Exercise the application as described above.

## Configuration

### Application Properties (`application.yaml`)
```yaml
# Microprofile server properties
server.port=8080
server.host=0.0.0.0
# Change the following to true to enable the optional MicroProfile Metrics REST.request metrics
metrics.rest-request.enabled=false

# Application properties. This is the default greeting
app.greeting=Hello

# Database connection factory - specifies Oracle UCP driver for connection pooling
javax.sql.DataSource.customer.connectionFactoryClassName = oracle.jdbc.pool.OracleDataSource

# Local Oracle Database Configuration
# Uncomment the following lines to connect to a local Oracle Docker container out-of-the-box:
# javax.sql.DataSource.customer.URL = jdbc:oracle:thin:@//localhost:1521/freepdb1
# javax.sql.DataSource.customer.user = customer
# javax.sql.DataSource.customer.password = Welcome12345

# Hibernate/JPA Configuration
hibernate.hbm2ddl.auto=create
hibernate.show_sql=true
hibernate.format_sql=true
# Fix JTA transaction coordinator issue
hibernate.transaction.coordinator_class=jta

# Eureka service discovery configuration
server.features.eureka.client.base-uri=http://eureka.eureka:8761/eureka
server.features.eureka.instance.name=helidon-customer-service
server.features.eureka.instance.hostName=helidon.helidon
```

## Build Architecture

This project uses:
- **Helidon MP (MicroProfile)** - Enterprise Java microservices profile
- **Thin JAR deployment** - Application JAR + separate dependencies for optimal Docker layering
- **Maven Assembly Plugin** - Creates deployment ZIP with proper structure for containerization
- **Hibernate + JTA** - Database persistence with transaction management
- **Oracle UCP** - Connection pooling for Oracle Database
- **Eureka integration** - Service discovery support

## Dockerfile Structure

The included Dockerfile uses a **multi-stage build**:

```dockerfile
# 1st stage, build the app
FROM container-registry.oracle.com/java/jdk-no-fee-term:21 as build

# Install maven
WORKDIR /usr/share
RUN set -x && \
    curl -O https://archive.apache.org/dist/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz && \
    tar -xvf apache-maven-*-bin.tar.gz && \
    rm apache-maven-*-bin.tar.gz && \
    mv apache-maven-* maven && \
    ln -s /usr/share/maven/bin/mvn /bin/

WORKDIR /helidon

# Create a first layer to cache the "Maven World" in the local repository.
ADD pom.xml .
RUN mvn package -Dmaven.test.skip -Declipselink.weave.skip -DskipOpenApiGenerate

# Do the Maven build with fat JAR!
ADD src src
RUN mvn package -DskipTests

# 2nd stage, build the runtime image
FROM container-registry.oracle.com/java/jdk-no-fee-term:21
WORKDIR /helidon

# Copy ONLY the fat JAR (not libs directory)
COPY --from=build /helidon/target/*.jar app.jar

# Simple fat JAR execution
CMD ["java", "-jar", "app.jar"]
EXPOSE 8080
```
