FROM openjdk:11-jre-slim

ENTRYPOINT ["java", "-jar", "/usr/share/oracle-db-appdev-monitoring.jar"]

#ARG JAR_FILE
#ADD target/${JAR_FILE} /usr/share/myservice/myservice.jar
ADD target/oracle-db-appdev-monitoring-0.1.jar /usr/share/oracle-db-appdev-monitoring.jar