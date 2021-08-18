FROM openjdk:11-jre-slim
#FROM oracle/graalvm-ce:20.0.0-java11

ENTRYPOINT ["java", "-Doracle.jdbc.Trace=true", "-jar", "/usr/share/myservice/myservice.jar"]

# Add Maven dependencies
ADD target/libs           /usr/share/myservice/libs
# Add the service itself
ARG JAR_FILE
ADD target/${JAR_FILE} /usr/share/myservice/myservice.jar