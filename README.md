# tiledbsoma-docker

Docker images for TileDB-SOMA's R and Python packages.

## Images

| Image                                  | Description                             |
|----------------------------------------------------------------------------------|
| `ghcr.io/aaronwolen/tiledbsoma-base`   | TileDB core + libtiledbsoma C++ library |
| `ghcr.io/aaronwolen/tiledbsoma-r`      | Base + TileDB-SOMA R package            |
| `ghcr.io/aaronwolen/tiledbsoma-python` | Base + TileDB-SOMA Python package       |

All images are available for both `linux/amd64` and `linux/arm64`.

## Image Tags

| Tag            | Description                                 |
|----------------|---------------------------------------------|
| `latest`       | Built weekly from TileDB-SOMA `main` branch |
| `stable`       | Built from the latest TileDB-SOMA release   |
| `sha-<commit>` | Immutable reference to a specific build     |

## Usage

```bash
# Pull the latest Python image
docker pull ghcr.io/aaronwolen/tiledbsoma-python:latest

# Pull the stable R image
docker pull ghcr.io/aaronwolen/tiledbsoma-r:stable
```

## Building Stable Images

To build new stable images when a TileDB-SOMA release is published update `STABLE_SOMA_REF` in `.github/workflows/ci.yml` to the new release tag and submit a pull request.

## Build Locally

```bash
# Build base image
docker build --platform linux/amd64 -f docker/base.Dockerfile -t tiledbsoma-base:dev .

# Build R image
docker build --platform linux/amd64 -f docker/r.Dockerfile \
  --build-arg BASE_IMAGE=tiledbsoma-base:dev -t tiledbsoma-r:dev .

# Build Python image
docker build --platform linux/amd64 -f docker/python.Dockerfile \
  --build-arg BASE_IMAGE=tiledbsoma-base:dev -t tiledbsoma-python:dev .
```
