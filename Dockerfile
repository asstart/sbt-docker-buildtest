FROM sbtscala/scala-sbt:eclipse-temurin-17.0.4_1.7.1_3.2.0

COPY project /app/project
COPY src /app/src
COPY build.sbt /app/

WORKDIR /app

RUN sbt update -verbose -debug

RUN sbt assembly