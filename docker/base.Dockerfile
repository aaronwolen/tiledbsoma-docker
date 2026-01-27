# syntax=docker/dockerfile:1.7
#
# Base image with libtiledbsoma C++ library pre-built
#
# This image builds the libtiledbsoma C++ library from the main branch using the
# official build script. R and Python images extend this base to avoid rebuilding
# the C++ layer.
#
# Build:
#   docker build --platform linux/amd64 -f docker/base.Dockerfile -t tiledbsoma-base:dev .
#
# The library is installed to /opt/libtiledbsoma with:
#   - Headers:    /opt/libtiledbsoma/include
#   - Libraries:  /opt/libtiledbsoma/lib
#   - pkg-config: /opt/libtiledbsoma/lib/pkgconfig
#
# vcpkg dependencies (including TileDB core) are installed to /opt/vcpkg_installed.

ARG UBUNTU_VERSION=24.04

# =============================================================================
# Builder stage
# =============================================================================
FROM ubuntu:${UBUNTU_VERSION} AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG TILEDBSOMA_REPO=https://github.com/single-cell-data/TileDB-SOMA.git
ARG TILEDBSOMA_REF=main

ENV TZ=UTC
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV VCPKG_ROOT=/opt/vcpkg
# Needed for ARM builds, harmless on x86
ENV VCPKG_FORCE_SYSTEM_BINARIES=1

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    cmake \
    curl \
    g++ \
    git \
    libcurl4-openssl-dev \
    libssl-dev \
    locales \
    make \
    ninja-build \
    pkg-config \
    tar \
    unzip \
    wget \
    zip \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Clone and bootstrap vcpkg
WORKDIR /opt
RUN git clone https://github.com/microsoft/vcpkg.git \
    && cd vcpkg \
    && ./bootstrap-vcpkg.sh

# Clone TileDB-SOMA
# Note: --depth 1 works with branches/tags but not commit SHAs
WORKDIR /build
RUN git clone --depth 1 --branch ${TILEDBSOMA_REF} ${TILEDBSOMA_REPO} TileDB-SOMA

# Build libtiledbsoma using the official build script
WORKDIR /build/TileDB-SOMA
RUN ./scripts/bld --build=Release --prefix=/opt/libtiledbsoma

# Copy vcpkg-installed dependencies (TileDB core, etc.) to a permanent location
RUN mkdir -p /opt/vcpkg_installed \
    && if [ -d /build/TileDB-SOMA/build/vcpkg_installed ]; then \
         cp -r /build/TileDB-SOMA/build/vcpkg_installed/* /opt/vcpkg_installed/; \
       fi

# Verify the build succeeded
ENV PKG_CONFIG_PATH=/opt/vcpkg_installed/lib/pkgconfig:/opt/libtiledbsoma/lib/pkgconfig
RUN pkg-config --exists tiledbsoma \
    && echo "libtiledbsoma version: $(pkg-config --modversion tiledbsoma)" \
    && ls -la /opt/libtiledbsoma/lib/ \
    && ls -la /opt/libtiledbsoma/include/

# =============================================================================
# Runtime stage - minimal image with only runtime dependencies
# =============================================================================
FROM ubuntu:${UBUNTU_VERSION}

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=UTC
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libcurl4 \
    libgomp1 \
    libssl3 \
    locales \
    pkg-config \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Copy built libraries from builder stage
COPY --from=builder /opt/libtiledbsoma /opt/libtiledbsoma
COPY --from=builder /opt/vcpkg_installed /opt/vcpkg_installed

# Set up environment for runtime and downstream builds
ENV LD_LIBRARY_PATH=/opt/vcpkg_installed/lib:/opt/libtiledbsoma/lib
ENV PKG_CONFIG_PATH=/opt/vcpkg_installed/lib/pkgconfig:/opt/libtiledbsoma/lib/pkgconfig

# Verify libraries are accessible
RUN pkg-config --exists tiledbsoma \
    && echo "Runtime image ready - libtiledbsoma $(pkg-config --modversion tiledbsoma)"

WORKDIR /

LABEL org.opencontainers.image.title="tiledbsoma-base"
LABEL org.opencontainers.image.description="TileDB-SOMA C++ library base image"
LABEL org.opencontainers.image.source="https://github.com/single-cell-data/TileDB-SOMA"
