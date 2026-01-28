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
ARG TILEDBSOMA_REF=2.0.0
ARG UBUNTU_CODENAME=noble
ARG CRAN_REPO=https://packagemanager.posit.co/cran/__linux__/${UBUNTU_CODENAME}/latest

# Install R and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base \
    r-base-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure R to use Posit Package Manager for faster binary package installs
RUN echo "options(repos = c(CRAN = '${CRAN_REPO}'), download.file.method = 'libcurl', HTTPUserAgent = sprintf('R/%s R (%s)', getRversion(), paste(getRversion(), R.version['platform'], R.version['arch'], R.version['os'])))" >> $(R RHOME)/etc/Rprofile.site

# Install tiledbsoma R package from GitHub
# The package will link against pre-built libtiledbsoma via pkg-config
RUN R -q -e "install.packages('remotes')" \
    && R -q -e "remotes::install_github('single-cell-data/TileDB-SOMA', ref='${TILEDBSOMA_REF}', subdir='apis/r')"

# Verify installation
RUN R -q -e "library(tiledbsoma); cat('tiledbsoma R package loaded successfully\\n')"

LABEL org.opencontainers.image.title="tiledbsoma-r"
LABEL org.opencontainers.image.description="TileDB-SOMA R package image"
LABEL org.opencontainers.image.source="https://github.com/single-cell-data/TileDB-SOMA"
