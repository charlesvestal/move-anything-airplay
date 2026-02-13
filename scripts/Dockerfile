FROM debian:bookworm-slim

RUN dpkg --add-architecture arm64 && \
    apt-get update && apt-get install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    make \
    git \
    autoconf \
    automake \
    libtool \
    pkg-config \
    xxd \
    # arm64 cross-compilation libraries for shairport-sync
    libssl-dev:arm64 \
    libavahi-client-dev:arm64 \
    libpopt-dev:arm64 \
    libconfig-dev:arm64 \
    && rm -rf /var/lib/apt/lists/*

ENV CROSS_PREFIX=aarch64-linux-gnu-
ENV PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig
ENV PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig
WORKDIR /build
