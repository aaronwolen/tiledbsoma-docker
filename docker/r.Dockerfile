# syntax=docker/dockerfile:1.7
#
# TileDB-SOMA R package image
#
# Build:
#   docker build --platform linux/amd64 -f docker/r.Dockerfile \
#     --build-arg BASE_IMAGE=tiledbsoma-base:dev -t tiledbsoma-r:dev .

ARG BASE_IMAGE=tiledbsoma-base:dev
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG TILEDBSOMA_REF=main

# Install R and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base \
    r-base-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install tiledbsoma R package from GitHub
# The package will link against pre-built libtiledbsoma via pkg-config
RUN R -q -e "install.packages('remotes', repos='https://cloud.r-project.org')" \
    && R -q -e "remotes::install_github('single-cell-data/TileDB-SOMA', ref='${TILEDBSOMA_REF}', subdir='apis/r')"

# Verify installation
RUN R -q -e "library(tiledbsoma); cat('tiledbsoma R package loaded successfully\\n')"

LABEL org.opencontainers.image.title="tiledbsoma-r"
LABEL org.opencontainers.image.description="TileDB-SOMA R package image"
LABEL org.opencontainers.image.source="https://github.com/single-cell-data/TileDB-SOMA"

ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
