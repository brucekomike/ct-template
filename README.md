# ct-template

A GitHub Actions CI template that automatically builds container images from all `Dockerfile*` files found in the repository and pushes them to the [GitHub Container Registry](https://ghcr.io) (`ghcr.io`).

## How It Works

The workflow in [`.github/workflows/build-container.yml`](.github/workflows/build-container.yml) is triggered on:

- **Push** to `main` or `master` branches → builds **and pushes** all images.
- **Push** of a version tag (e.g. `v1.2.3`) → builds and pushes all images with semantic version tags.
- **Pull Request** targeting `main` or `master` → builds all images (no push), to validate every `Dockerfile`.

### Multiple Image Support

The workflow automatically discovers every `Dockerfile*` file in the repository and builds a separate image for each one. The image name is derived from the filename:

| Dockerfile         | Image name                                |
|--------------------|-------------------------------------------|
| `Dockerfile`       | `ghcr.io/<owner>/<repo>`                 |
| `Dockerfile.foo`   | `ghcr.io/<owner>/<repo>-foo`             |
| `Dockerfile.bar`   | `ghcr.io/<owner>/<repo>-bar`             |

Each image is built in parallel using a matrix strategy.

### Multi-Architecture Builds

By default, each image is built for:

- `linux/amd64`
- `linux/arm64`

If a specific Dockerfile is amd64-only, set the workflow env var `AMD64_ONLY_DOCKERFILES` to a comma-separated list of Dockerfile paths or filenames (for example `Dockerfile.legacy,services/api/Dockerfile`).
Those entries will be built only for `linux/amd64`.

## Image Tags

Images are automatically tagged using the following scheme:

| Event          | Tag example                     |
|----------------|---------------------------------|
| Branch push    | `main`, `master`                |
| Pull request   | `pr-42`                         |
| Version tag    | `1.2.3`, `1.2`                  |
| Commit SHA     | `a1b2c3d`                       |

## Usage

1. **Fork or use this repository as a template.**
2. **Edit the `Dockerfile`** at the root of the repository to build your own application, or add additional `Dockerfile.<name>` files for more images.
3. **Push to `main`** – the workflow will build each image and push it to:
   ```
   ghcr.io/<your-github-username>/<your-repo-name>:<tag>
   ghcr.io/<your-github-username>/<your-repo-name>-<name>:<tag>
   ```
4. **Pull an image:**
   ```bash
   docker pull ghcr.io/<your-github-username>/<your-repo-name>:<tag>
   ```

## Requirements

- No additional secrets are needed. The workflow uses the built-in `GITHUB_TOKEN` to authenticate with `ghcr.io`.
- Ensure the repository's **Packages** visibility is set appropriately (public or private) in your GitHub settings.

## Customisation

- To change the base image or build steps, edit `Dockerfile`.
- To add a new image variant, create a new file named `Dockerfile.<name>` – it will be picked up automatically.
- To mark specific Dockerfiles as amd64-only, set `.github/workflows/build-container.yml` env `AMD64_ONLY_DOCKERFILES`.
- To trigger on additional branches or tags, update the `on.push` section of the workflow file.
- To always push on pull requests (e.g. to a staging registry), change `push: ${{ github.event_name != 'pull_request' }}` to `push: true` in the workflow.
