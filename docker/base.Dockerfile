# syntax=docker/dockerfile:1.7
#
# Base image with libtiledbsoma C++ library pre-built
#
# This image builds the libtiledbsoma C++ library from the main branch.
# The lang-specific images use this as a base to avoid rebuilding the C++ layer.
#
# The library is installed to /opt/libtiledbsoma with:
#   - Headers: /opt/libtiledbsoma/include
#   - Libraries: /opt/libtiledbsoma/lib
#   - pkg-config: /opt/libtiledbsoma/lib/pkgconfig

ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION} AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG TILEDBSOMA_REPO=https://github.com/single-cell-data/TileDB-SOMA.git
ARG TILEDBSOMA_REF=main

ENV TZ=UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    VCPKG_FORCE_SYSTEM_BINARIES=1 \
    VCPKG_ROOT=/opt/vcpkg

# Install build dependencies for libtiledbsoma
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
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
RUN git clone https://github.com/microsoft/vcpkg.git && \
    cd vcpkg && \
    ./bootstrap-vcpkg.sh

# Clone TileDB-SOMA from GitHub
WORKDIR /build
RUN git clone --depth 1 --branch ${TILEDBSOMA_REF} ${TILEDBSOMA_REPO} TileDB-SOMA

# Build libtiledbsoma using official build script
# Install to /opt/libtiledbsoma so it can be found via pkg-config
WORKDIR /build/TileDB-SOMA
RUN ./scripts/bld --build=Release --prefix=/opt/libtiledbsoma

# Copy vcpkg-installed dependencies (TileDB core, etc.) to permanent location
RUN mkdir -p /opt/vcpkg_installed && \
    if [ -d /build/TileDB-SOMA/build/vcpkg_installed ]; then \
        cp -r /build/TileDB-SOMA/build/vcpkg_installed/* /opt/vcpkg_installed/; \
    fi

# Verify the build
RUN ls -la /opt/libtiledbsoma/lib/ && \
    ls -la /opt/libtiledbsoma/include/ && \
    PKG_CONFIG_PATH=/opt/libtiledbsoma/lib/pkgconfig:/opt/vcpkg_installed/lib/pkgconfig \
    pkg-config --exists tiledbsoma && \
    echo "libtiledbsoma version: $(PKG_CONFIG_PATH=/opt/libtiledbsoma/lib/pkgconfig:/opt/vcpkg_installed/lib/pkgconfig pkg-config --modversion tiledbsoma)"

# ============================================================================
# Final runtime image - minimal size with only runtime dependencies
# ============================================================================
FROM ubuntu:${UBUNTU_VERSION}

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libcurl4 \
    libssl3 \
    libstdc++6 \
    locales \
    pkg-config \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Copy built libraries and headers from builder
COPY --from=builder /opt/libtiledbsoma /opt/libtiledbsoma
COPY --from=builder /opt/vcpkg_installed /opt/vcpkg_installed

# Set up library and pkg-config paths
ENV LD_LIBRARY_PATH=/opt/vcpkg_installed/lib:/opt/libtiledbsoma/lib \
    PKG_CONFIG_PATH=/opt/vcpkg_installed/lib/pkgconfig:/opt/libtiledbsoma/lib/pkgconfig

# Verify libraries are loadable in runtime environment
RUN ldconfig && \
    pkg-config --exists tiledbsoma && \
    echo "Runtime verification successful: libtiledbsoma $(pkg-config --modversion tiledbsoma)"

WORKDIR /

LABEL org.opencontainers.image.title="tiledbsoma-base" \
      org.opencontainers.image.description="TileDB-SOMA C++ library base image" \
      org.opencontainers.image.source="https://github.com/single-cell-data/TileDB-SOMA"
