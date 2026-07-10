ARG BASE_REGISTRY=docker.io
ARG BASE_TAG=latest

FROM ${BASE_REGISTRY}/library/ubuntu:24.04

# Build arguments for multi-arch support
ARG TARGETOS
ARG TARGETARCH

# Install common development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    git \
    gnupg \
    libusb-1.0-0-dev \
    openssh-client \
    pkg-config \
    tzdata \
    unzip \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Export build args as environment variables for child images
ENV TARGETOS=${TARGETOS}
ENV TARGETARCH=${TARGETARCH}

WORKDIR /workspace
