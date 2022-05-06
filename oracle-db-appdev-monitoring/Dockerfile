FROM maven:3.6.3-openjdk-11 AS maven_build
COPY pom.xml /tmp/
COPY src /tmp/src/
WORKDIR /tmp/
FROM openjdk
EXPOSE 8080
ARG JAR_FILE=target/oracle-db-appdev-monitoring-0.1.0-spring-boot.jar
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
