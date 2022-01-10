FROM ghcr.io/graalvm/graalvm-ce:java11-21.3.0
MAINTAINER oracle.com
ENV JAVA_HOME=/opt/graalvm-ce-java11-21.2.0
COPY lib/java.security $JAVA_HOME/lib/security/java.security
COPY target/okafka-examples-0.0.1-SNAPSHOT.jar okafka-examples-0.0.1-SNAPSHOT.jar
ENTRYPOINT ["java","-classpath",".:okafka-examples-0.0.1-SNAPSHOT.jar", "Producer"]


