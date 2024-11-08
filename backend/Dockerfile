#
# Build and package the application using Maven
#
FROM maven:3-amazoncorretto-21 AS maven_builder

# Copy the source code
WORKDIR /app
COPY . ./

# Build the application
RUN mvn package

#
# Main app image
#
FROM amazoncorretto:21.0.5-al2

# Copy the built jar file
WORKDIR /app
COPY --from=maven_builder /app/target/interview-1.0-SNAPSHOT.jar /app/interview-app.jar

# Expose default HTTP port
EXPOSE 8080/tcp

# Run the application
CMD ["java", "-jar", "/app/interview-app.jar"]
