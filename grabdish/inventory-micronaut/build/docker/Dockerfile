FROM openjdk:17-alpine
WORKDIR /home/app
COPY layers/libs /home/app/libs
COPY layers/resources /home/app/resources
COPY layers/application.jar /home/app/application.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/home/app/application.jar"]
