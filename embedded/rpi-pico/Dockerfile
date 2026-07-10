ARG ADA_REGISTRY=docker.io
ARG ADA_TAG=latest

FROM ${ADA_REGISTRY}/devcontainer-ada:${ADA_TAG}

USER root

# Pico SDK is already available from Ada template
# This template adds Ada-specific Pico development support

# Clone Pico SDK with shallow clone (if not already present)
WORKDIR /opt/pico

RUN if [ ! -d pico-sdk ]; then \
        git clone --depth 1 --branch master https://github.com/raspberrypi/pico-sdk.git && \
        cd pico-sdk && \
        git submodule update --init --depth 1; \
    fi

# Set PICO_SDK_PATH environment variable
ENV PICO_SDK_PATH=/opt/pico/pico-sdk

# Clone, build, and install picotool (if not already present)
RUN if [ ! -f /usr/local/bin/picotool ]; then \
        git clone --depth 1 --branch master https://github.com/raspberrypi/picotool.git && \
        cd picotool && \
        mkdir build && \
        cd build && \
        cmake .. -DPICO_SDK_PATH=${PICO_SDK_PATH} && \
        make -j$(nproc) && \
        make install && \
        cd /opt/pico && \
        rm -rf picotool; \
    fi

# Install latest GNAT ARM cross-compiler via Alire (as root)
RUN alr toolchain --select gnat_arm_elf 