#!/bin/bash
set -e

# Build and push dev container images to a registry
# Usage: ./build-images.sh [REGISTRY] [TAG]
# Examples:
#   ./build-images.sh ghcr.io/your-org         # GHCR
#   ./build-images.sh docker.io/yourusername   # Docker Hub
#   ./build-images.sh ghcr.io/my-org v1.0.0

# Validate that REGISTRY is supplied
if [ -z "${1}" ]; then
    echo "Error: REGISTRY URL is required."
    echo ""
    echo "Usage: ./build-images.sh REGISTRY [TAG]"
    echo ""
    echo "Examples:"
    echo "  ./build-images.sh ghcr.io/your-org              # GHCR (uses 'latest' tag)"
    echo "  ./build-images.sh ghcr.io/your-org v1.0.0       # GHCR with specific tag"
    echo "  ./build-images.sh docker.io/yourusername        # Docker Hub (uses 'latest' tag)"
    echo "  ./build-images.sh myregistry.azurecr.io v1.0.0  # ACR with specific tag"
    echo ""
    exit 1
fi

REGISTRY="${1}"
BASE_TAG="${2:-latest}"

# Convert to lowercase for GHCR and other registries (required for compatibility)
REGISTRY=$(echo "$REGISTRY" | tr '[:upper:]' '[:lower:]')
BASE_TAG=$(echo "$BASE_TAG" | tr '[:upper:]' '[:lower:]')

echo "Building devcontainer templates..."
echo ""
echo "Registry: $REGISTRY"
echo "Tag: $BASE_TAG"
echo ""

# Build and push base image
echo "========================================";
echo "# 1. Building base image..."
echo "========================================";
docker build -t "${REGISTRY}/devcontainer-base:${BASE_TAG}" base/
echo "Pushing base image..."
docker push "${REGISTRY}/devcontainer-base:${BASE_TAG}"
echo ""

# Build and push Ada image
echo "========================================";
echo "# 2. Building Ada image..."
echo "========================================";
docker build \
    --build-arg BASE_REGISTRY="${REGISTRY}" \
    --build-arg BASE_TAG="${BASE_TAG}" \
    -t "${REGISTRY}/devcontainer-ada:${BASE_TAG}" \
    "ada/"
echo "Pushing Ada image..."
docker push "${REGISTRY}/devcontainer-ada:${BASE_TAG}"
echo ""

# Build and push RP2040 image (Ada + Pico SDK)
echo "========================================";
echo "# 3. Building RP2040 image (Ada + Pico SDK)..."
echo "========================================";
docker build \
    --build-arg ADA_REGISTRY="${REGISTRY}" \
    --build-arg ADA_TAG="${BASE_TAG}" \
    -t "${REGISTRY}/devcontainer-rpi-pico:${BASE_TAG}" \
    "embedded/rpi-pico/"
echo "Pushing RP2040 image..."
docker push "${REGISTRY}/devcontainer-rpi-pico:${BASE_TAG}"
echo ""

# Build and push ESP32-S3 image (Ada + ESP-IDF)
echo "========================================";
echo "# 4. Building ESP32-S3 image (Ada + ESP-IDF)..."
echo "========================================";
docker build \
    --build-arg ADA_REGISTRY="${REGISTRY}" \
    --build-arg ADA_TAG="${BASE_TAG}" \
    -t "${REGISTRY}/devcontainer-esp32s3:${BASE_TAG}" \
    "embedded/esp32s3/"
echo "Pushing ESP32-S3 image..."
docker push "${REGISTRY}/devcontainer-esp32s3:${BASE_TAG}"
echo ""

echo "========================================";
echo "✓ All images built and pushed successfully!"
echo "========================================";
echo ""
echo "Images now available in registry: ${REGISTRY}"
echo "  - devcontainer-base:${BASE_TAG}"
echo "  - devcontainer-ada:${BASE_TAG}"
echo "  - devcontainer-rpi-pico:${BASE_TAG}"
echo "  - devcontainer-esp32s3:${BASE_TAG}"
