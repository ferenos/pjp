# Dockerfile for testing client modpack build
FROM openjdk:17-slim

# Install required tools
RUN apt-get update && \
    apt-get install -y curl git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install packwiz
RUN curl -L -o /usr/local/bin/packwiz https://github.com/packwiz/packwiz/releases/latest/download/packwiz-linux && \
    chmod +x /usr/local/bin/packwiz

# Set working directory
WORKDIR /modpack

# Copy modpack files
COPY pack.toml .
COPY index.toml .
COPY mods/ mods/
COPY kubejs/ kubejs/
COPY resourcepacks/ resourcepacks/
COPY shaderpacks/ shaderpacks/
COPY manual_mods/ manual_mods/

# Test: Build the modpack
RUN echo "Testing packwiz refresh..." && \
    packwiz refresh

# Test: Export to Modrinth pack
RUN echo "Testing Modrinth export..." && \
    packwiz mr export

# Verify the .mrpack file was created
RUN ls -lh *.mrpack && \
    echo "Client build test successful!"

# Keep container running for inspection if needed
CMD ["echo", "Client build tests passed!"]
