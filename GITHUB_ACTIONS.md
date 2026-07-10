# GitHub Actions Workflow - Automated Image Builds

This workflow automatically builds and pushes dev container images to GitHub Container Registry (GHCR) when you push to the repository or manually trigger a build.

## Setup

### 1. Enable GitHub Container Registry

The workflow uses GHCR, which requires minimal setup:

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Packages and registries**
3. Verify that GitHub Container Registry is available (it should be by default)

### 2. Verify Repository Permissions

The workflow requires `packages:write` permission:

1. Go to **Settings** → **Actions** → **General**
2. Under "Workflow permissions," ensure:
   - ✓ "Read repository contents permission"
   - ✓ "Allow GitHub Actions to create and approve pull requests"
3. Click **Save**

Alternatively, the workflow file includes explicit permissions:
```yaml
permissions:
  contents: read
  packages: write
```

### 3. First Push

Push to your main branch to trigger the first build:

```bash
git add .
git commit -m "Add dev container templates and CI/CD"
git push origin main
```

## Automatic Builds

The workflow triggers automatically on:

- **Push to main/master branch** - When Dockerfile, `.devcontainer.json`, or build scripts change
- **Any push to template files** - Paths monitored:
  - `base/**`
  - `ada/**`
  - `embedded/**`
  - `build-images.sh`
  - `.github/workflows/build-images.yml`

When triggered automatically, images are tagged with `latest`.

### View Build Results

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Find the "Build and Push Dev Container Images" workflow
4. Click the run to see build logs and results

## Manual Builds

Trigger a build manually anytime with a custom tag:

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Find "Build and Push Dev Container Images" workflow
4. Click **Run workflow** (top right)
5. Enter an optional tag (e.g., `v1.0.0`, `dev`, `stable`)
6. Click **Run workflow**

If you don't specify a tag, `latest` is used.

## Image Naming

Images are named based on your GitHub username and repository:

```
ghcr.io/{GITHUB_USERNAME}/devcontainer-base:{TAG}
ghcr.io/{GITHUB_USERNAME}/devcontainer-ada:{TAG}
ghcr.io/{GITHUB_USERNAME}/devcontainer-rpi-pico:{TAG}
ghcr.io/{GITHUB_USERNAME}/devcontainer-esp32s3:{TAG}
```

Example (if username is `john` and repo is `devcontainer-templates`):

```
ghcr.io/john/devcontainer-base:latest
ghcr.io/john/devcontainer-ada:latest
ghcr.io/john/devcontainer-rpi-pico:latest
ghcr.io/john/devcontainer-esp32s3:latest
```

## Using Built Images

After a successful build, use the images in your projects by updating `.devcontainer/devcontainer.json`:

```json
{
  "image": "ghcr.io/your-username/devcontainer-ada:latest"
}
```

Replace `your-username` with your actual GitHub username.

### Authentication

To pull from GHCR in your projects:

**Option 1: Personal Access Token (PAT)**

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
```

**Option 2: Using GitHub App or Actions**

GitHub Actions automatically authenticates when pulling images within workflows.

**Option 3: Public Images**

If your repository is public, GHCR images are automatically public and don't require authentication to pull.

## Build Features

### Layer Caching

The workflow uses GitHub Actions cache (`type=gha`) for Docker layers:

- **First build** - Pulls base images, installs packages, builds tools
- **Subsequent builds** - Reuses layers from cache (much faster)
- **Build time** - Typically 5-15 minutes depending on network and changes

### Dependency Order

Images are built in order:

1. **base** - Foundation template
2. **ada** - Depends on base
3. **rpi-pico** - Depends on ada
4. **esp32s3** - Depends on ada

Each subsequent build uses the previously built image as its parent.

### Multi-platform Builds

To build for multiple architectures (amd64, arm64), add to the workflow:

```yaml
- name: Build and push base image
  uses: docker/build-push-action@v5
  with:
    context: ./base
    platforms: linux/amd64,linux/arm64
    push: true
    tags: ${{ env.REGISTRY }}/${{ env.IMAGE_BASE_NAME }}-base:${{ steps.tag.outputs.tag }}
```

This requires a builder instance (automatic with setup-buildx-action).

## Build Results Summary

After each build, a summary is posted to the workflow run showing:

- Registry URL
- Image tag used
- All four built images

View the summary by clicking the workflow run in the **Actions** tab.

## Troubleshooting

### Workflow fails to run

**Possible causes:**

1. Workflow file not in correct location: `.github/workflows/build-images.yml`
2. Permissions not set: Verify **Settings** → **Actions** → **General** permissions
3. GitHub Token missing: GHCR login uses `secrets.GITHUB_TOKEN` (automatic)

**Solution:** Check the workflow file path and repository settings, then retry manually.

### "Unauthorized" error when pushing

**Cause:** GitHub Token permissions missing.

**Solution:**
1. Go to **Settings** → **Actions** → **General**
2. Under "Workflow permissions," select **Read and write permissions**
3. Click **Save**
4. Retry the workflow

### Build fails with "failed to resolve reference"

**Cause:** Parent image (base or ada) not found in GHCR.

**Solution:**
- Ensure base builds successfully first
- Check that build-args reference the correct registry and tag
- Workflow automatically uses the same tag for all images, so they're in sync

### No workflow appears in Actions tab

**Cause:** Workflow file has syntax errors.

**Solution:**
1. Go to **.github/workflows/build-images.yml** in your repository
2. Check file for YAML syntax errors
3. Common issues: incorrect indentation, missing colons, invalid selectors
4. Commit and push to update

Use a YAML validator like [yamllint.com](https://www.yamllint.com/) if unsure.

### Images build but don't push to registry

**Cause:** `push: true` missing or authentication failed.

**Verify:**
- Workflow file has `push: true` in build steps
- Check workflow logs for authentication errors
- Verify GHCR is accessible: `docker login ghcr.io`

## Customization

### Change branch triggers

Edit `.github/workflows/build-images.yml`:

```yaml
on:
  push:
    branches:
      - main
      - master
      - develop    # Add more branches
```

### Change file path triggers

Edit `.github/workflows/build-images.yml`:

```yaml
paths:
  - 'base/**'
  - 'ada/**'
  - 'embedded/**'
  - 'custom/**'     # Add new template paths
  - 'build-images.sh'
```

### Add schedule-based builds

Rebuild daily or weekly:

```yaml
on:
  push:
    branches: [main, master]
  workflow_dispatch:
  schedule:
    - cron: '0 2 * * 0'  # Every Sunday at 2 AM UTC
```

### Change registry

To use Docker Hub instead of GHCR:

1. Edit `.github/workflows/build-images.yml`
2. Change `REGISTRY: ghcr.io` to `REGISTRY: docker.io`
3. Update login action for Docker Hub credentials
4. Update `IMAGE_BASE_NAME` logic

For Docker Hub:

```yaml
env:
  REGISTRY: docker.io
  IMAGE_BASE_NAME: ${{ github.repository_owner }}/devcontainer

steps:
  - name: Log in to Docker Hub
    uses: docker/login-action@v3
    with:
      username: ${{ secrets.DOCKERHUB_USERNAME }}
      password: ${{ secrets.DOCKERHUB_TOKEN }}
```

## Next Steps

1. **Test locally** - Verify templates work before committing
2. **Push to main** - Trigger automatic build
3. **Monitor workflow** - Check Actions tab for build status
4. **Update projects** - Use new images in `.devcontainer/devcontainer.json`
5. **Share images** - Team members can pull from your GHCR registry

## Further Reading

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [docker/build-push-action](https://github.com/docker/build-push-action)
- [GitHub Container Registry Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
