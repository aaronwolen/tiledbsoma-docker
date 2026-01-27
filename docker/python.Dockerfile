# syntax=docker/dockerfile:1.7
#
# TileDB-SOMA Python package image
#
# Build:
#   docker build --platform linux/amd64 -f docker/python.Dockerfile \
#     --build-arg BASE_IMAGE=tiledbsoma-base:dev -t tiledbsoma-python:dev .

ARG BASE_IMAGE=tiledbsoma-base:dev
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG TILEDBSOMA_REF=main

# Install Python and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    git \
    g++ \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Install tiledbsoma Python package from GitHub
# The package will link against pre-built libtiledbsoma via pkg-config
# Using --break-system-packages is safe in containers (PEP 668)
# Set include paths so the build can find TileDB headers
# Adding /opt/libtiledbsoma/include/tiledbsoma for internal headers with relative includes
ENV CPLUS_INCLUDE_PATH=/opt/vcpkg_installed/include:/opt/libtiledbsoma/include:/opt/libtiledbsoma/include/tiledbsoma
ENV LIBRARY_PATH=/opt/vcpkg_installed/lib:/opt/libtiledbsoma/lib
RUN python3 -m pip install --no-cache-dir --break-system-packages \
        "tiledbsoma @ git+https://github.com/single-cell-data/TileDB-SOMA.git@${TILEDBSOMA_REF}#subdirectory=apis/python"

# Verify installation
RUN python3 -c "import tiledbsoma; print(f'tiledbsoma {tiledbsoma.__version__} loaded successfully')"

LABEL org.opencontainers.image.title="tiledbsoma-python"
LABEL org.opencontainers.image.description="TileDB-SOMA Python package image"
LABEL org.opencontainers.image.source="https://github.com/single-cell-data/TileDB-SOMA"

ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
