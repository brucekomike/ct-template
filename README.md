# ct-template

A GitHub Actions CI template that automatically builds container images from all `Dockerfile*` files found in the repository and pushes them to the [GitHub Container Registry](https://ghcr.io) (`ghcr.io`).

## How It Works

The workflow in [`.github/workflows/build-container.yml`](.github/workflows/build-container.yml) is triggered on:

- **Push** to `main` or `master` branches → builds **and pushes** all images.
- **Push** of a version tag (e.g. `v1.2.3`) → builds and pushes all images with semantic version tags.
- **Pull Request** targeting `main` or `master` → builds and pushes PR-tagged images, to validate every `Dockerfile`.

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

### Staged Builds

If you need some images to build only after others have finished (for example, a base image that other Dockerfiles depend on), end the filename with a numeric suffix:

| Dockerfile           | Stage | Image name                    |
|-----------------------|-------|-------------------------------|
| `Dockerfile`          | 0     | `ghcr.io/<owner>/<repo>`      |
| `Dockerfile.foo`      | 0     | `ghcr.io/<owner>/<repo>-foo`  |
| `Dockerfile.foo.1`    | 1     | `ghcr.io/<owner>/<repo>-foo`  |
| `Dockerfile.bar.2`    | 2     | `ghcr.io/<owner>/<repo>-bar`  |

- Files with no trailing numeric suffix (or none at all) are stage `0` and build first, in parallel, exactly as before.
- Files ending in `.1` build in a separate job that only starts once every stage `0` job has finished.
- Files ending in `.2` wait for all `.1` jobs, and so on.
- Stages `0` through `4` are supported (`.1`–`.4`); a Dockerfile with a higher numeric suffix is detected but has no build job to run it.
- If an earlier stage has no matching Dockerfiles, its build job is skipped and later stages proceed normally.

### Using a Previous Stage as a Base Image

A staged Dockerfile can use the image produced by an earlier Dockerfile as its
base image. For example, `Dockerfile.1` uses the image built from `Dockerfile`:

```dockerfile
ARG BASE_IMAGE=ct-template:main
FROM ${BASE_IMAGE}

RUN <additional build steps>
```

Build and tag the stage-0 image locally before building the staged Dockerfile,
then pass its tag through `BASE_IMAGE` if it differs from the default
`ct-template:main`. In CI, staged builds use the current PR tag (or stable
`main` tag for branch builds) published by the previous stage. The workflow uses
the same GitHub Actions cache scope
(`github.repository` plus the image suffix) for matching staged Dockerfiles, so
unchanged build steps can be reused between stages.

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

### Local Build and Push Scripts

The optional helper scripts use the same staged Dockerfile naming convention as
the workflow. A trailing stage number is ignored when deriving the local image
name, so `Dockerfile.api.1` and `Dockerfile.api` both map to
`ct-template-api:main` unless an image is supplied explicitly.

```bash
bin/build.sh [Dockerfile[.name][.stage]] [image[:tag]]
bin/push.sh <remote-repository[:tag]> [local-image[:tag]]
bin/build-all.sh
bin/push-all.sh <remote-repository[:tag]>
```

For example:

```bash
bin/build.sh Dockerfile.api.1 ct-template-api:main
bin/push.sh ghcr.io/<your-github-username>/<your-repo-name>-api:main ct-template-api:main
bin/build-all.sh
bin/push-all.sh ghcr.io/<your-github-username>/<your-repo-name>:main
```

`build-all.sh` discovers all `Dockerfile*` files and builds stages in order,
using the preceding stage's local `main`-tagged image as the base. `push-all.sh`
pushes each discovered image variant to the matching remote repository name.

## Requirements

- No additional secrets are needed. The workflow uses the built-in `GITHUB_TOKEN` to authenticate with `ghcr.io`.
- Ensure the repository's **Packages** visibility is set appropriately (public or private) in your GitHub settings.

## Customisation

- To change the base image or build steps, edit `Dockerfile`.
- To add a new image variant, create a new file named `Dockerfile.<name>` – it will be picked up automatically.
- To make an image wait for others to finish building first, end the filename with `.<stage>` (e.g. `Dockerfile.<name>.1`, `Dockerfile.<name>.2`) – see [Staged Builds](#staged-builds).
- To mark specific Dockerfiles as amd64-only, set `.github/workflows/build-container.yml` env `AMD64_ONLY_DOCKERFILES`.
- To trigger on additional branches or tags, update the `on.push` section of the workflow file.
- Same-repository pull requests publish temporary `pr-<number>` tags so isolated staged-build jobs can share their base images; fork pull requests cannot publish images.
