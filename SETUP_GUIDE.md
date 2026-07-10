# Setup Guide - Repository Structure and Template Development

This guide covers the repository structure and how to develop, extend, or create new templates.

## Repository Structure

```
devcontainer-templates/
├── base/                          # Base template (Ubuntu 24.04)
│   ├── Dockerfile
│   └── devcontainer.json
├── ada/                           # Ada template (inherits from base)
│   ├── Dockerfile
│   └── devcontainer.json
├── embedded/
│   ├── rpi-pico/                  # RP2040 template (inherits from ada)
│   │   ├── Dockerfile
│   │   └── devcontainer.json
│   └── esp32s3/                   # ESP32-S3 template (inherits from ada)
│       ├── Dockerfile
│       └── devcontainer.json
├── build-images.sh                # Build and publish all images
├── README.md                      # Overview and quick links
├── USAGE_GUIDE.md                 # Using templates in projects
├── BUILD_GUIDE.md                 # Building and publishing images
└── SETUP_GUIDE.md                 # This file
```

## Template Hierarchy

Templates inherit from each other in a dependency chain:

```
base (Ubuntu 24.04)
  ↓ FROM base
ada (Ada + Alire)
  ↓ FROM ada
  ├─→ embedded/rpi-pico (Pico SDK)
  └─→ embedded/esp32s3 (ESP-IDF)
```

Each template's Dockerfile accepts build arguments for the parent image registry and tag:

```dockerfile
ARG BASE_REGISTRY=docker.io
ARG BASE_TAG=latest
FROM ${BASE_REGISTRY}/devcontainer-base:${BASE_TAG}
```

## Template Specifications

### base Template

**Purpose:** Foundation template with common development tools.

**Base Image:** `ubuntu:24.04`

**Includes:**
- Git, curl, wget, build-essential
- Docker-in-Docker (DinD)
- cmake, libusb-1.0-0-dev, pkg-config, xz-utils
- Non-root user `devuser` with passwordless sudo
- Multi-arch support (amd64, arm64)

**Dockerfile Location:** `base/Dockerfile`

**Build Arguments:** None

### ada Template

**Purpose:** Ada development environment.

**Base Image:** `${BASE_REGISTRY}/devcontainer-base:${BASE_TAG}`

**Includes:**
- Everything from base
- Alire 2.1.0 package manager
- gnat_native Ada compiler (host)
- gnat_arm_elf ARM embedded compiler
- VS Code extensions: AdaCore Ada, C++ tools

**Dockerfile Location:** `ada/Dockerfile`

**Build Arguments:**
- `BASE_REGISTRY` - Registry for base image (default: `docker.io`)
- `BASE_TAG` - Tag for base image (default: `latest`)

### embedded/rpi-pico Template

**Purpose:** Ada development for Raspberry Pi Pico (RP2040).

**Base Image:** `${ADA_REGISTRY}/devcontainer-ada:${ADA_TAG}`

**Includes:**
- Everything from ada
- Raspberry Pi Pico SDK (cloned from GitHub)
- picotool (built from source)
- GNAT ARM32 cross-compiler (via Alire)
- Environment: `PICO_SDK_PATH=/opt/pico/pico-sdk`
- VS Code extensions: AdaCore Ada, C++ tools, CMake tools

**Dockerfile Location:** `embedded/rpi-pico/Dockerfile`

**Build Arguments:**
- `ADA_REGISTRY` - Registry for ada image (default: `docker.io`)
- `ADA_TAG` - Tag for ada image (default: `latest`)

### embedded/esp32s3 Template

**Purpose:** Ada development for ESP32-S3.

**Base Image:** `${ADA_REGISTRY}/devcontainer-ada:${ADA_TAG}`

**Includes:**
- Everything from ada
- ESP-IDF (configurable version, default v5.2.1)
- esptool for flashing
- GNAT ESP32-S3 cross-compiler (via Alire)
- udev rules for USB device access
- Optional: QEMU for emulation
- Environment: `IDF_PATH=/opt/esp/esp-idf`, `IDF_TOOLS_PATH=/opt/esp/tools`
- Devices: `/dev/ttyUSB0`, `/dev/ttyUSB1`, `/dev/ttyACM0`
- VS Code extensions: AdaCore Ada, C++ tools, Espressif ESP-IDF

**Dockerfile Location:** `embedded/esp32s3/Dockerfile`

**Build Arguments:**
- `ADA_REGISTRY` - Registry for ada image (default: `docker.io`)
- `ADA_TAG` - Tag for ada image (default: `latest`)
- `ESP_IDF_VERSION` - ESP-IDF version to install (default: `v5.2.1`)
- `INSTALL_QEMU` - Install QEMU for emulation (default: `false`)

## Creating a New Template

To create a new embedded template (e.g., STM32), follow this pattern:

### Step 1: Create directory structure

```bash
mkdir -p embedded/stm32
cd embedded/stm32
touch Dockerfile devcontainer.json
```

### Step 2: Create Dockerfile

Inherit from ada (or base, depending on your needs):

```dockerfile
ARG ADA_REGISTRY=docker.io
ARG ADA_TAG=latest

FROM ${ADA_REGISTRY}/devcontainer-ada:${ADA_TAG}

USER root

# Install STM32-specific packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    stlink-tools \
    arm-none-eabi-gdb \
    arm-none-eabi-newlib \
    && rm -rf /var/lib/apt/lists/*

# Clone STM32 SDK or tools
RUN git clone --depth 1 https://github.com/STMicroelectronics/stm32cube.git /opt/stm32

# Set environment variables
ENV STM32_PATH=/opt/stm32

WORKDIR /workspace
```

**Guidelines:**
- Always use `ARG` and `FROM` with build arguments for parent images
- Use `USER root` at the start if you need to install packages
- Clean up apt cache: `rm -rf /var/lib/apt/lists/*`
- Set `WORKDIR /workspace` at the end
- Document environment variables

### Step 3: Create devcontainer.json

```json
{
  "name": "Ada + STM32 Development",
  "image": "ghcr.io/your-org/devcontainer-stm32:latest",
  "remoteUser": "devuser",
  "customizations": {
    "vscode": {
      "extensions": [
        "AdaCore.ada",
        "ms-vscode.cpptools-extension-pack"
      ],
      "settings": {
        "files.eol": "\n",
        "editor.formatOnSave": true,
        "[ada]": {
          "editor.defaultFormatter": "AdaCore.ada"
        }
      }
    }
  },
  "postCreateCommand": "alr version && st-info --version && echo 'STM32 environment ready'",
  "containerEnv": {
    "STM32_PATH": "/opt/stm32"
  },
  "runArgs": [
    "--cap-add=SYS_PTRACE",
    "--security-opt",
    "seccomp=unconfined",
    "--device=/dev/ttyUSB0"
  ],
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {
      "version": "latest"
    },
    "ghcr.io/devcontainers/features/git:1": {}
  }
}
```

**Guidelines:**
- Set `"image"` if using pre-built images, or use `"build"` for local builds
- Include relevant VS Code extensions for your platform
- Expose devices as needed for flashing
- Set environment variables for SDK paths
- Use `postCreateCommand` for verification

### Step 4: Update build-images.sh

Add the new template to the build script:

```bash
echo "========================================";
echo "# 5. Building STM32 image (Ada + STM32 tools)...";
echo "========================================";
docker build \
    --build-arg ADA_REGISTRY="${REGISTRY}" \
    --build-arg ADA_TAG="${BASE_TAG}" \
    -t "${REGISTRY}/devcontainer-stm32:${BASE_TAG}" \
    "embedded/stm32/"
echo "Pushing STM32 image..."
docker push "${REGISTRY}/devcontainer-stm32:${BASE_TAG}"
echo ""
```

Add to final success message:

```bash
echo "  - devcontainer-stm32:${BASE_TAG}"
```

### Step 5: Test locally

Build the image locally to verify it works:

```bash
# Build base
docker build -t devcontainer-base:test base/

# Build ada
docker build \
  --build-arg BASE_REGISTRY=docker.io \
  --build-arg BASE_TAG=test \
  -t devcontainer-ada:test \
  ada/

# Build stm32
docker build \
  --build-arg ADA_REGISTRY=docker.io \
  --build-arg ADA_TAG=test \
  -t devcontainer-stm32:test \
  embedded/stm32/
```

Test in VS Code by pointing to the local image:

```json
{
  "image": "devcontainer-stm32:test"
}
```

### Step 6: Publish

```bash
./build-images.sh ghcr.io/your-org v1.0.0
```

## Modifying Existing Templates

### Update Dockerfile

Edit the template's `Dockerfile` directly:

```dockerfile
# Example: Add a new package to base
RUN apt-get install -y --no-install-recommends \
    new-package
```

### Update devcontainer.json

Edit the template's `devcontainer.json`:

```json
{
  "postCreateCommand": "new-command"
}
```

### Rebuild and publish

```bash
./build-images.sh ghcr.io/your-org v1.0.1
```

## Layer Caching Strategy

Docker builds cache layers, which affects rebuild speed:

**First build:**
- base: Full build (~5-10 min)
- ada: Alire download and install (~3-5 min)
- rpi-pico: Pico SDK clone and build (~5-10 min)
- esp32s3: ESP-IDF download and install (~10-20 min)

**Subsequent builds (with no changes):**
- All layers cached, nearly instant

**Rebuild strategy:**
- Small changes to rpi-pico only? → Only rpi-pico rebuilds
- Changes to ada? → ada, rpi-pico, and esp32s3 rebuild
- Changes to base? → All templates rebuild

**Force rebuild without cache:**

```bash
docker build --no-cache -t image:tag path/
```

## Dockerfile Best Practices

1. **Use ARG for dependencies** - Makes templates composable
   ```dockerfile
   ARG BASE_REGISTRY=docker.io
   ARG BASE_TAG=latest
   FROM ${BASE_REGISTRY}/devcontainer-base:${BASE_TAG}
   ```

2. **Clean apt cache** - Reduces layer size
   ```dockerfile
   RUN apt-get update && apt-get install -y ... && rm -rf /var/lib/apt/lists/*
   ```

3. **Minimize layers** - Combine commands with `&&`
   ```dockerfile
   RUN apt-get update && \
       apt-get install -y package1 package2 && \
       rm -rf /var/lib/apt/lists/*
   ```

4. **Use non-root user** - Inherited from base
   ```dockerfile
   USER devuser  # Don't run as root unnecessarily
   ```

5. **Set WORKDIR** - For clarity
   ```dockerfile
   WORKDIR /workspace
   ```

6. **Document environment variables** - In comments
   ```dockerfile
   # Set SDK path
   ENV SDK_PATH=/opt/sdk
   ```

## Testing Templates

### Local test with VS Code

1. Copy template to a test project: `cp -r ada/ test-project/.devcontainer`
2. Open `test-project` in VS Code
3. Click remote indicator → "Reopen in Container"
4. Verify tools work: `alr version`, `gnat --version`, etc.

### Command-line test

```bash
# Start container with template
docker run -it devcontainer-ada:test bash

# Verify tools
alr version
gnat --version
```

## Further Reading

- [Dev Containers Specification](https://containers.dev/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Docker Build Best Practices](https://docs.docker.com/develop/dev-best-practices/)
