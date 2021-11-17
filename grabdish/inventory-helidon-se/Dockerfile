FROM ghcr.io/graalvm/graalvm-ce:21.3.0

ENTRYPOINT ["java", "-jar", "/usr/share/myservice/myservice.jar"]

# Add Maven dependencies
ADD target/libs           /usr/share/myservice/libs
# Add the service itself
ARG JAR_FILE
ADD target/${JAR_FILE} /usr/share/myservice/myservice.jar