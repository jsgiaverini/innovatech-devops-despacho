FROM maven:3.9-eclipse-temurin-17-alpine AS build

WORKDIR /app

COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -q clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine

RUN addgroup -S spring && adduser -S spring -G spring

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

RUN chown spring:spring /app/app.jar

USER spring

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
