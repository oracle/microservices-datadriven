FROM maven:3.6.3-openjdk-11 AS maven_build
COPY pom.xml /tmp/
COPY src /tmp/src/
WORKDIR /tmp/
RUN mvn package
FROM openjdk
EXPOSE 8080
CMD java -jar /data/inventory-springboot-0.1.0.jar
COPY --from=maven_build /tmp/target/inventory-springboot-0.1.0.jar /data/inventory-springboot-0.1.0.jar
