# ct-template

A GitHub Actions CI template that automatically builds a container image from a `Dockerfile` (or `Containerfile`) and pushes it to the [GitHub Container Registry](https://ghcr.io) (`ghcr.io`).

## How It Works

The workflow in [`.github/workflows/build-container.yml`](.github/workflows/build-container.yml) is triggered on:

- **Push** to `main` or `master` branches → builds **and pushes** the image.
- **Push** of a version tag (e.g. `v1.2.3`) → builds and pushes the image with semantic version tags.
- **Pull Request** targeting `main` or `master` → builds the image only (no push), to validate the `Dockerfile`.

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
2. **Edit the `Dockerfile`** at the root of the repository to build your own application.
3. **Push to `main`** – the workflow will build your image and push it to:
   ```
   ghcr.io/<your-github-username>/<your-repo-name>:<tag>
   ```
4. **Pull the image:**
   ```bash
   docker pull ghcr.io/<your-github-username>/<your-repo-name>:<tag>
   ```

## Requirements

- No additional secrets are needed. The workflow uses the built-in `GITHUB_TOKEN` to authenticate with `ghcr.io`.
- Ensure the repository's **Packages** visibility is set appropriately (public or private) in your GitHub settings.

## Customisation

- To change the base image or build steps, edit the `Dockerfile`.
- To trigger on additional branches or tags, update the `on.push` section of the workflow file.
- To always push on pull requests (e.g. to a staging registry), change `push: ${{ github.event_name != 'pull_request' }}` to `push: true` in the workflow.
