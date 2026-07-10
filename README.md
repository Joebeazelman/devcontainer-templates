# Dev Container Templates - Ada & Embedded

Reusable dev container templates for Ada development and embedded systems (RP2040, ESP32-S3).

Uses a modular template hierarchy:

```
base (Ubuntu 24.04 + common tools)
  ↓
  └─→ ada (Alire + GNAT toolchains)
        ↓
        ├─→ embedded/rpi-pico (Pico SDK + tools for RP2040)
        │
        └─→ embedded/esp32s3 (ESP-IDF + tools for ESP32-S3)
```

## Available Templates

| Template | Use Case | Includes |
|----------|----------|----------|
| `base/` | Foundation for custom templates | Ubuntu 24.04, Docker-in-Docker, cmake, libusb |
| `ada/` | Ada desktop or embedded development | Alire 2.1.0, GNAT native + ARM compilers |
| `embedded/rpi-pico/` | Ada development for Raspberry Pi Pico (RP2040) | Pico SDK, picotool, GNAT ARM32 cross-compiler |
| `embedded/esp32s3/` | Ada development for ESP32-S3 | ESP-IDF, esptool, GNAT ESP32S3 cross-compiler |

## Getting Started

**To use templates in your project:** See [USAGE_GUIDE.md](./USAGE_GUIDE.md)

**To build and publish images to a registry:** See [BUILD_GUIDE.md](./BUILD_GUIDE.md)

**To set up automated GitHub Actions builds:** See [GITHUB_ACTIONS.md](./GITHUB_ACTIONS.md)

**To develop or extend templates:** See [SETUP_GUIDE.md](./SETUP_GUIDE.md)

## Key Features

- ✓ Multi-arch support (amd64, arm64)
- ✓ Non-root user (`devuser`) for security
- ✓ Docker-in-Docker enabled
- ✓ Registry-based image inheritance
- ✓ Modular templates (use what you need)
- ✓ Pre-configured VS Code extensions

## Quick Example

Copy the Ada template to your project:

```bash
cp -r ada/ your-project/.devcontainer
```

Then open your project in VS Code with the Dev Containers extension to build and run the container.

See [USAGE_GUIDE.md](./USAGE_GUIDE.md) for complete instructions.

## Further Reading

- [Dev Containers Specification](https://containers.dev/)
- [VS Code Dev Containers Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [Raspberry Pi Pico Documentation](https://www.raspberrypi.com/documentation/microcontrollers/raspberry-pi-pico.html)
- [Alire Package Manager](https://alire.ada.dev/)
