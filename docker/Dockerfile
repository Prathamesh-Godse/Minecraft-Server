# Use a lightweight Java base image
FROM eclipse-temurin:17-jre-jammy

# Set the user to root for initial setup to handle permissions
USER root

# Install dependencies and create user
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Create a non-root user to run the server
    useradd -r -m -U -d /minecraft -s /bin/bash minecraft && \
    # Create the server directory and set ownership
    mkdir -p /minecraft/server && \
    chown -R minecraft:minecraft /minecraft

# Switch to the non-root user for security
USER minecraft
WORKDIR /minecraft/server

# Copy the startup script and make it executable
COPY --chown=minecraft:minecraft scripts/start-server.sh .

# Expose the default Minecraft server port
EXPOSE 25565

# Set the default memory allocation (can be overridden)
ENV JVM_OPTS="-Xms2G -Xmx2G"

# Use the script as the entrypoint
ENTRYPOINT [ "./start-server.sh" ]
