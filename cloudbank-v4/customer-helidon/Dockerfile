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
# Incremental docker builds will always resume after that, unless you update the pom
ADD pom.xml .
RUN mvn package -Dmaven.test.skip -Declipselink.weave.skip -DskipOpenApiGenerate

# Do the Maven build!
# Incremental docker builds will resume here when you change sources
ADD src src
RUN mvn package -DskipTests
RUN echo "done!"

# 2nd stage, build the runtime image
FROM container-registry.oracle.com/java/jdk-no-fee-term:21
WORKDIR /helidon

# Copy the dependencies
COPY --from=build /helidon/target/libs ./libs/

# Copy ALL the classes including META-INF directory with config files
COPY --from=build /helidon/target/classes/ ./

# Debug: Show what was copied
RUN ls -la . && echo "=== META-INF contents ===" && ls -la META-INF/ || echo "META-INF not found"

# Use the correct classpath that includes current directory (.) for classes and META-INF
CMD ["java", "-cp", ".:libs/*", "io.helidon.microprofile.cdi.Main"]

EXPOSE 8080