FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip python3 python3-pil openjdk-17-jdk-headless \
    libasound2t64 libgl1 libx11-6 libxcursor1 libxi6 libxinerama1 libxrandr2 \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
