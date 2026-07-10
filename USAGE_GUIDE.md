# Usage Guide - Using Templates in Your Projects

This guide explains how to use dev container templates in your own projects.

## Quick Start

### 1. Copy a template to your project

```bash
# For general Ada development
cp -r ada/ your-project/.devcontainer

# For Raspberry Pi Pico (RP2040) development
cp -r embedded/rpi-pico/ your-project/.devcontainer

# For ESP32-S3 development
cp -r embedded/esp32s3/ your-project/.devcontainer
```

### 2. Update the image reference (if using pre-built images)

If your organization has built and published images to a registry, update `devcontainer.json` to reference the registry image.

For example, if using GHCR with pre-built Ada image:

```json
{
  "image": "ghcr.io/your-org/devcontainer-ada:v1.0.0"
}
```

If you want VS Code to build the image locally instead, keep the `build` section in `devcontainer.json` as-is (see below).

### 3. Open in VS Code

1. Install the **Dev Containers** extension in VS Code
2. Open your project folder
3. Click the remote indicator (bottom-left corner) → "Reopen in Container"
4. VS Code builds the container and opens your workspace inside it

## Local Builds vs. Pre-built Images

### Local Builds (Default)

The copied template includes a `build` section in `devcontainer.json`:

```json
{
  "build": {
    "dockerfile": "Dockerfile",
    "context": "."
  }
}
```

This tells VS Code to build the image locally using the Dockerfile in your `.devcontainer` folder.

**Advantages:**
- Works offline
- No registry setup needed
- Full control over the image

**Disadvantages:**
- Slower on first use (builds locally)
- Subsequent opens are fast (cached layers)

### Pre-built Images

If your organization publishes images to a registry, update `devcontainer.json` to use the `image` field:

```json
{
  "image": "ghcr.io/your-org/devcontainer-ada:v1.0.0"
}
```

Replace `ghcr.io/your-org` with your actual registry and image name.

**Advantages:**
- Fast to open (image already built)
- Consistent across the team
- No local build overhead

**Disadvantages:**
- Requires registry login
- Team dependency on published images

## Template Customization in Your Project

### Add project-specific tools

Edit `.devcontainer/devcontainer.json`:

```json
{
  "postCreateCommand": "alr version && alr describe && echo 'Project ready'"
}
```

Or create a setup script (`.devcontainer/post-create.sh`):

```bash
#!/bin/bash
set -e
echo "Setting up project..."
alr toolchain --select gnat_arm_elf
npm install          # if your project uses Node
echo "Setup complete!"
```

Then reference it in `devcontainer.json`:

```json
{
  "postCreateCommand": "bash .devcontainer/post-create.sh"
}
```

### Add VS Code extensions

Edit `.devcontainer/devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "AdaCore.ada",
        "ms-vscode.cpptools-extension-pack",
        "eamodio.gitlens"
      ]
    }
  }
}
```

### Add environment variables

Edit `.devcontainer/devcontainer.json`:

```json
{
  "containerEnv": {
    "MY_VAR": "value",
    "DEBUG": "true"
  }
}
```

### Mount additional volumes

Edit `.devcontainer/devcontainer.json`:

```json
{
  "mounts": [
    "type=bind,source=/dev/ttyUSB0,target=/dev/ttyUSB0",
    "type=volume,source=project-cache,target=/home/devuser/.cache"
  ]
}
```

### Change the base image

Edit `.devcontainer/Dockerfile` and modify the `FROM` line:

```dockerfile
FROM ghcr.io/your-org/devcontainer-ada:v2.0.0
```

## Device Access (Embedded Development)

For embedded projects (RP2040, ESP32-S3), you may need access to USB devices for flashing.

The templates include device mappings in `runArgs`:

```json
{
  "runArgs": [
    "--device=/dev/ttyUSB0",
    "--device=/dev/ttyUSB1",
    "--device=/dev/ttyACM0"
  ]
}
```

If your device appears at a different port, add it:

```json
{
  "runArgs": [
    "--device=/dev/ttyUSB0",
    "--device=/dev/ttyUSB1",
    "--device=/dev/ttyACM0",
    "--device=/dev/ttyUSB3"
  ]
}
```

## Troubleshooting

### "Command 'devcontainer' not found"

Install the Dev Containers extension in VS Code:
1. Open Extensions (Ctrl+Shift+X / Cmd+Shift+X)
2. Search "Dev Containers"
3. Install by Microsoft

### Container fails to build

**Error:** `failed to resolve reference to base image`

This happens if:
- You're using a `FROM` line referencing a non-existent image
- The registry is not logged in

Solution:
- If using local build: Verify the `FROM` line in `.devcontainer/Dockerfile`
- If using pre-built images: Verify your registry login (`docker login ghcr.io` etc.)

### Tools missing in container

Verify the template includes what you need:

```bash
# Inside the container
alr version              # Ada templates
picotool version        # RP2040 template
idf_monitor --version   # ESP32-S3 template
```

If missing, you may need to:
1. Use a different template
2. Customize `postCreateCommand` to install additional tools
3. Extend the Dockerfile

## Further Reading

- [Dev Containers Specification](https://containers.dev/)
- [VS Code Dev Containers Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [devcontainer.json Reference](https://containers.dev/implementors/json_reference/)
