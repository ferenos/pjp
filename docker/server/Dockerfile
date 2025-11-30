# Dockerfile for testing server build and startup
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Java 17 and required tools
RUN apt-get update && \
    apt-get install -y \
    openjdk-17-jre-headless \
    curl \
    wget \
    git \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install packwiz-installer
RUN mkdir -p /opt/packwiz && \
    curl -L -o /opt/packwiz/packwiz-installer-bootstrap.jar \
    https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar

# Create server directory
WORKDIR /server

# Copy pack metadata
COPY pack.toml .
COPY index.toml .

# Download and setup Forge server
ARG MINECRAFT_VERSION=1.20.1
ARG FORGE_VERSION=47.4.12

# Download Forge installer
RUN wget -q https://maven.minecraftforge.net/net/minecraftforge/forge/${MINECRAFT_VERSION}-${FORGE_VERSION}/forge-${MINECRAFT_VERSION}-${FORGE_VERSION}-installer.jar && \
    java -jar forge-${MINECRAFT_VERSION}-${FORGE_VERSION}-installer.jar --installServer && \
    rm -f forge-${MINECRAFT_VERSION}-${FORGE_VERSION}-installer.jar

# Install mods using packwiz-installer
RUN java -jar /opt/packwiz/packwiz-installer-bootstrap.jar -g -s server pack.toml

# Create eula.txt to accept EULA
RUN echo "eula=true" > eula.txt

# Create server.properties with minimal settings for testing
RUN echo "server-port=25565" > server.properties && \
    echo "online-mode=false" >> server.properties && \
    echo "max-players=1" >> server.properties && \
    echo "motd=NutAndJamPack Test Server" >> server.properties && \
    echo "level-type=minecraft:normal" >> server.properties && \
    echo "difficulty=peaceful" >> server.properties

# Create a startup script
RUN echo '#!/bin/bash\n\
echo "Starting Minecraft Server for build test..."\n\
timeout 180 java -Xms2G -Xmx4G -jar libraries/net/minecraftforge/forge/*/unix_args.txt nogui &\n\
PID=$!\n\
echo "Server started with PID: $PID"\n\
echo "Waiting for server to finish loading..."\n\
sleep 120\n\
echo "Checking if server is still running..."\n\
if ps -p $PID > /dev/null; then\n\
    echo "Server is running successfully!"\n\
    kill $PID\n\
    wait $PID\n\
    echo "Server stopped gracefully"\n\
    exit 0\n\
else\n\
    echo "Server failed to start or crashed!"\n\
    exit 1\n\
fi\n' > /server/test-server.sh && \
    chmod +x /server/test-server.sh

# Expose server port (for future use)
EXPOSE 25565

CMD ["/server/test-server.sh"]
