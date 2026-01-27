# tiledbsoma-docker

Docker images for nightly builds of TileDB-SOMA's C++ library and the latest development versions of the R and Python packages.

## Images

- **Base C++**: builds TileDB core, vcpkg, and `libtiledbsoma`.
- **R**: extends the base image and installs the latest TileDB-SOMA R package.
- **Python**: extends the base image and installs the latest TileDB-SOMA Python package.

## Build locally

Build the base image:

```bash
docker build --platform linux/amd64 -f docker/base.Dockerfile -t libtiledbsoma .
```
