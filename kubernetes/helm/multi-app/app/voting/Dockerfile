# Stage 1: Build the Spring Boot application
FROM maven:3.9.0-amazoncorretto-19 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the project's POM file for dependency resolution
COPY . .

# Build the application using Maven
RUN mvn package

# Stage 2: Create a smaller image for production
FROM amazoncorretto:19

# Set the working directory inside the container
WORKDIR /app

# Copy the JAR file built in the previous stage
COPY --from=build /app/target/voting-0.0.1-SNAPSHOT.jar app.jar

# Expose port 8080 for the Spring Boot application
EXPOSE 8080

# Define the command to run the Spring Boot application
CMD ["java", "-jar", "app.jar"]

