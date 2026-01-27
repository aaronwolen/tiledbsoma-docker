# syntax=docker/dockerfile:1.7
#
# Python image with TileDB-SOMA Python package pre-installed
#
# Extends the base C++ image to install Python and the latest tiledbsoma Python package.
# Reuses the pre-built C++ libraries from the base image - no rebuild needed.

ARG BASE_IMAGE=tiledbsoma-base:dev
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG TILEDBSOMA_REPO=https://github.com/single-cell-data/TileDB-SOMA.git
ARG TILEDBSOMA_REF=main

# Install Python and development dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install tiledbsoma Python package from GitHub
# The package will find libtiledbsoma via PKG_CONFIG_PATH
RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel \
    && python3 -m pip install --no-cache-dir \
        "git+${TILEDBSOMA_REPO}@${TILEDBSOMA_REF}#subdirectory=apis/python"

# Verify installation
RUN python3 -c "import tiledbsoma; print(f'tiledbsoma Python package {tiledbsoma.__version__} loaded successfully')"

LABEL org.opencontainers.image.title="tiledbsoma-python" \
      org.opencontainers.image.description="TileDB-SOMA Python package image" \
      org.opencontainers.image.source="https://github.com/single-cell-data/TileDB-SOMA"
