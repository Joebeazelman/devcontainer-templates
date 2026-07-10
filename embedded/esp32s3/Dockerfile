ARG ADA_REGISTRY=docker.io
ARG ADA_TAG=latest
ARG ESP_IDF_VERSION=v5.2.1

FROM ${ADA_REGISTRY}/devcontainer-ada:${ADA_TAG}

# Define an optional build argument (defaults to "false")
ARG INSTALL_QEMU=false

USER root

# Install ESP32-S3 development dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake \
    ninja-build \
    python3-pip \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    libftdi1 \
    libftdi1-dev \
    udev \
    openssl \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install python3-full and pip-tools (required for Python 3.12+ system-wide installs)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-full \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install esptool via pip (with --break-system-packages for Ubuntu 24.04)
# Note: idf_monitor comes bundled with ESP-IDF
RUN pip3 install --no-cache-dir --break-system-packages \
    esptool \
    cryptography

# Set ESP-IDF version and installation path
ENV IDF_PATH="/opt/esp/esp-idf"
ENV IDF_TOOLS_PATH="${IDF_PATH}/tools"

# Create ESP installation directory (git clone requires it to not exist)
RUN mkdir -p /opt/esp

# Clone ESP-IDF repository with specified version
# Use --filter blob:none for lighter clone
RUN git clone --filter blob:none --sparse --branch ${ESP_IDF_VERSION} \
    https://github.com/espressif/esp-idf.git ${IDF_PATH} || \
    git clone --depth 50 https://github.com/espressif/esp-idf.git ${IDF_PATH} && \
    cd ${IDF_PATH} && git checkout ${ESP_IDF_VERSION}

RUN if [ "$INSTALL_QEMU" = "true" ] ; then \
    git clone --quiet https://github.com/espressif/qemu.git \
	&& cd qemu \
	&& mkdir -p build \
	&& cd build \
	&& ../configure --target-list=xtensa-softmmu --enable-debug --enable-sanitizers --disable-strip --disable-capstone --disable-vnc \
	&& make vga=no \
	&& make install \
	&& cd ../.. \ 
	&& rm -rf qemu \
    fi && \

RUN git clone --quiet https://github.com/espressif/qemu.git \
	&& cd qemu \
	&& mkdir -p build \
	&& cd build \
	&& ../configure --target-list=xtensa-softmmu --enable-debug --enable-sanitizers --disable-strip --disable-capstone --disable-vnc \
	&& make vga=no \
	&& make install \
	&& cd ../.. \ 
	&& rm -rf qemu

WORKDIR ${IDF_PATH}

# Run the IDF install script to download and extract tools
# This installs the toolchain for xtensa-esp32s3-elf target
RUN bash install.sh esp32s3

# Create udev rules for ESP32 USB access
RUN echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666"' > /etc/udev/rules.d/99-esp32.rules && \
    echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666"' >> /etc/udev/rules.d/99-esp32.rules && \
    echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55d4", MODE="0666"' >> /etc/udev/rules.d/99-esp32.rules

# Source IDF environment setup in bashrc and zshrc
RUN echo "source ${IDF_PATH}/export.sh" >> /root/.bashrc && \
    echo "source ${IDF_PATH}/export.sh" >> /root/.zshrc 2>/dev/null || true

# Install ESP32 GNAT cross-compiler via Alire (with assistant disabled)
RUN alr toolchain --disable-assistant && \
    alr toolchain --select gnat_xtensa_esp32_elf 

WORKDIR /workspace
