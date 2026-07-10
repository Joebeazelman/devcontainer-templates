ARG BASE_REGISTRY=docker.io
ARG BASE_TAG=latest

FROM ${BASE_REGISTRY}/devcontainer-base:${BASE_TAG}

USER root

# Map Docker TARGETARCH to Alire's architecture naming 
# amd64 -> x86_64, arm64 -> aarch64
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        echo "x86_64" > /tmp/arch; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        echo "aarch64" > /tmp/arch; \
    else \
        echo "x86_64" > /tmp/arch; \
    fi

# Define Alire version and installation path
ENV ALIRE_VERSION=2.1.0
ENV ALIRE_INSTALL_PATH=/opt/alire

# Download, extract, and install Alire
RUN ARCH=$(cat /tmp/arch) && \
    ALIRE_ZIP_ARCHIVE="https://github.com/alire-project/alire/releases/download/v${ALIRE_VERSION}/alr-${ALIRE_VERSION}-bin-${ARCH}-${TARGETOS}.zip" && \
    echo "Downloading Alire from ${ALIRE_ZIP_ARCHIVE}" && \
    mkdir -p ${ALIRE_INSTALL_PATH}/bin && \
    curl -fsSL ${ALIRE_ZIP_ARCHIVE} -o /tmp/alr.zip && \
    unzip -q /tmp/alr.zip -d ${ALIRE_INSTALL_PATH} && \
    chmod +x ${ALIRE_INSTALL_PATH}/bin/alr && \
    rm -f /tmp/alr.zip /tmp/arch

# Add Alire to PATH
ENV PATH=${ALIRE_INSTALL_PATH}/bin:${PATH}

# Install dependencies required by Alire toolchain management
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    gprbuild \
    && rm -rf /var/lib/apt/lists/*

# Install latest GNAT toolchain via Alire (as root)
RUN alr toolchain --disable-assistant && \
    alr toolchain --select gnat && \
    alr toolchain --select gprbuild

# Verify Alire installation (can run as root or any user)
RUN alr version
