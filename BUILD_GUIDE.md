# Build Guide - Building and Publishing Images

This guide explains how to build and publish dev container images to a registry for team use.

## Overview

The templates in this repository are designed to be built into Docker images and pushed to a registry (GHCR, Docker Hub, ACR, etc.). Your team can then pull these pre-built images for faster dev container startup.

## Prerequisites

- Docker installed and running
- Access to a container registry (GitHub Container Registry, Docker Hub, Azure Container Registry, etc.)
- Logged into your registry: `docker login <registry>`

## Building and Publishing All Images

Use the provided `build-images.sh` script:

```bash
./build-images.sh <REGISTRY> [TAG]
```

### Required Arguments

- `<REGISTRY>` - Your registry URL (required)
- `[TAG]` - Image tag (optional, defaults to `latest`)

### Examples

```bash
# Build with 'latest' tag
./build-images.sh ghcr.io/my-org

# Build with specific version tag
./build-images.sh ghcr.io/my-org v1.0.0

# Docker Hub
./build-images.sh docker.io/myusername

# Azure Container Registry
./build-images.sh myregistry.azurecr.io v2.0.0
```

The script validates that a registry URL is supplied and exits with an error if not.

### Build Order

The script builds images in dependency order:

1. **base** - Foundation template (Ubuntu 24.04)
2. **ada** - Depends on base
3. **embedded/rpi-pico** - Depends on ada
4. **embedded/esp32s3** - Depends on ada

Each image is built and immediately pushed to the registry.

### Output

On success:

```
========================================
✓ All images built and pushed successfully!
========================================

Images now available in registry: ghcr.io/my-org
  - devcontainer-base:v1.0.0
  - devcontainer-ada:v1.0.0
  - devcontainer-rpi-pico:v1.0.0
  - devcontainer-esp32s3:v1.0.0
```

## Building Individual Images

### Build base image only

```bash
docker build -t ghcr.io/my-org/devcontainer-base:v1.0.0 base/
docker push ghcr.io/my-org/devcontainer-base:v1.0.0
```

### Build Ada image (requires base)

```bash
docker build \
  --build-arg BASE_REGISTRY=ghcr.io/my-org \
  --build-arg BASE_TAG=v1.0.0 \
  -t ghcr.io/my-org/devcontainer-ada:v1.0.0 \
  ada/

docker push ghcr.io/my-org/devcontainer-ada:v1.0.0
```

### Build RP2040 image (requires ada)

```bash
docker build \
  --build-arg ADA_REGISTRY=ghcr.io/my-org \
  --build-arg ADA_TAG=v1.0.0 \
  -t ghcr.io/my-org/devcontainer-rpi-pico:v1.0.0 \
  embedded/rpi-pico/

docker push ghcr.io/my-org/devcontainer-rpi-pico:v1.0.0
```

### Build ESP32-S3 image (requires ada)

```bash
docker build \
  --build-arg ADA_REGISTRY=ghcr.io/my-org \
  --build-arg ADA_TAG=v1.0.0 \
  -t ghcr.io/my-org/devcontainer-esp32s3:v1.0.0 \
  embedded/esp32s3/

docker push ghcr.io/my-org/devcontainer-esp32s3:v1.0.0
```

## Registry Setup

### GitHub Container Registry (GHCR)

```bash
# Login with GitHub token
echo $GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin

# Build and push
./build-images.sh ghcr.io/your-org v1.0.0
```

### Docker Hub

```bash
# Login
docker login

# Build and push (use your username as the registry)
./build-images.sh docker.io/yourusername v1.0.0

# Or use Docker Hub shorthand
./build-images.sh yourusername v1.0.0
```

### Azure Container Registry (ACR)

```bash
# Login
az acr login --name myregistry

# Build and push
./build-images.sh myregistry.azurecr.io v1.0.0
```

## Build Arguments

Each Dockerfile accepts build arguments to customize the image:

### base/Dockerfile

No build arguments (inherits from Ubuntu 24.04).

### ada/Dockerfile

- `BASE_REGISTRY` - Registry for base image (default: `docker.io`)
- `BASE_TAG` - Tag for base image (default: `latest`)

### embedded/rpi-pico/Dockerfile

- `ADA_REGISTRY` - Registry for Ada image (default: `docker.io`)
- `ADA_TAG` - Tag for Ada image (default: `latest`)

### embedded/esp32s3/Dockerfile

- `ADA_REGISTRY` - Registry for Ada image (default: `docker.io`)
- `ADA_TAG` - Tag for Ada image (default: `latest`)
- `ESP_IDF_VERSION` - ESP-IDF version (default: `v5.2.1`)
- `INSTALL_QEMU` - Install QEMU for ESP32-S3 emulation (default: `false`)

## Image Sizes

Approximate sizes (with layer caching):

- **base** - ~700 MB
- **ada** - +200 MB (Alire + GNAT toolchains)
- **rpi-pico** - +400 MB (Pico SDK + picotool build)
- **esp32s3** - +500 MB (ESP-IDF + tools)

## Build Optimization

### Layer Caching

Docker caches layers, so:
- **First build** - Takes time (especially Pico SDK and ESP-IDF compilation)
- **Subsequent builds** - Much faster (cached layers reused)
- **Changes to rpi-pico only** - Rebuilds only that layer and dependents
- **Changes to ada** - Rebuilds ada, rpi-pico, and esp32s3

### Rebuild Strategy

To force a rebuild without cache:

```bash
./build-images.sh ghcr.io/my-org v1.0.1 --no-cache
```

Or manually:

```bash
docker build --no-cache -t ghcr.io/my-org/devcontainer-base:v1.0.1 base/
```

## Troubleshooting

### "REGISTRY URL is required"

Run the script with a registry argument:

```bash
./build-images.sh ghcr.io/my-org
```

### "Error response from daemon: unauthorized"

You're not logged into the registry. Log in first:

```bash
docker login ghcr.io
docker login docker.io
docker login myregistry.azurecr.io
```

### "failed to resolve reference to base image"

The base image tag doesn't exist in the registry. Check:

```bash
docker images | grep devcontainer-base
docker search ghcr.io/my-org/devcontainer-base
```

Ensure the registry/tag is correct in your build command.

### Build fails due to network errors

The build is downloading large files (Pico SDK, ESP-IDF). Retry:

```bash
./build-images.sh ghcr.io/my-org v1.0.0
```

Or build without pushing to debug:

```bash
docker build -t test-image ada/
```

### Disk space issues

Pico SDK and ESP-IDF compilation requires disk space:

```bash
# Check available space
df -h

# Clean up unused Docker resources
docker system prune
```

## Team Workflow

### Setup (One-time)

1. Clone this repository
2. Create a container registry (GHCR, Docker Hub, ACR, etc.)
3. Authenticate locally: `docker login <registry>`
4. Build and publish: `./build-images.sh <registry> v1.0.0`

### Developer Workflow

1. See [USAGE_GUIDE.md](./USAGE_GUIDE.md)
2. Copy template to project
3. Update `devcontainer.json` image reference to your registry/tag
4. Open in VS Code → Dev Containers extension pulls pre-built image
5. Container starts immediately (no local build needed)

### Updating Images

1. Modify Dockerfile(s) in this repository
2. Rebuild and push: `./build-images.sh <registry> v1.0.1`
3. Team updates their `devcontainer.json` image references to new tag
4. Next container open pulls the new image

## Further Reading

- [Docker Build Documentation](https://docs.docker.com/engine/reference/commandline/build/)
- [Docker Push Documentation](https://docs.docker.com/engine/reference/commandline/push/)
- [Docker Build Arguments](https://docs.docker.com/engine/reference/builder/#arg)
