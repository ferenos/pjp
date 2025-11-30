# Dockerfile for testing client modpack build
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required tools
RUN apt-get update && \
    apt-get install -y \
    openjdk-17-jre-headless \
    curl \
    git \
    wget \
    golang-go && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install packwiz
RUN go install github.com/packwiz/packwiz@latest

# Add Go bin to PATH
ENV PATH="/root/go/bin:${PATH}"

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
