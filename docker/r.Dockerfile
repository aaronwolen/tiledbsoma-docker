# syntax=docker/dockerfile:1.7
#
# R image with TileDB-SOMA R package pre-installed
#
# Extends the base C++ image to install R and the latest tiledbsoma R package.
# Reuses the pre-built C++ libraries from the base image - no rebuild needed.

ARG BASE_IMAGE=tiledbsoma-base:dev
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG TILEDBSOMA_REPO=https://github.com/single-cell-data/TileDB-SOMA.git
ARG TILEDBSOMA_REF=main

# Install R and development dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base \
    r-base-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# Install tiledbsoma R package from GitHub
# The package will find libtiledbsoma via PKG_CONFIG_PATH
RUN R -q -e "install.packages('remotes', repos='https://cloud.r-project.org')" \
    && R -q -e "remotes::install_github('single-cell-data/TileDB-SOMA', ref='${TILEDBSOMA_REF}', subdir='apis/r')"

# Verify installation
RUN R -q -e "library(tiledbsoma); cat('tiledbsoma R package loaded successfully\n')"

LABEL org.opencontainers.image.title="tiledbsoma-r" \
      org.opencontainers.image.description="TileDB-SOMA R package image" \
      org.opencontainers.image.source="https://github.com/single-cell-data/TileDB-SOMA"
