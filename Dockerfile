FROM openjdk:17-alpine


CMD java ${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom -jar /app.jar

EXPOSE 8080

ADD *.jar /app.jar
