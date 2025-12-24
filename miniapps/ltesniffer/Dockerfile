# ==============================================================================
# LTESniffer - LTE Downlink/Uplink Eavesdropper
# ==============================================================================
# Build: docker build -t homelab/ltesniffer .
# Requirements: USRP SDR, high-performance CPU (8+ cores recommended)
# ==============================================================================

FROM ubuntu:22.04 AS builder

LABEL maintainer="HomeLab"
LABEL description="LTESniffer - LTE Traffic Analysis Tool"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    pkg-config \
    libfftw3-dev \
    libmbedtls-dev \
    libboost-all-dev \
    libconfig++-dev \
    libsctp-dev \
    libglib2.0-dev \
    libudev-dev \
    libcurl4-gnutls-dev \
    qtdeclarative5-dev \
    libqt5charts5-dev \
    autoconf \
    automake \
    ccache \
    cpufrequtils \
    doxygen \
    ethtool \
    g++ \
    inetutils-tools \
    libncurses5 \
    libncurses5-dev \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    python3-dev \
    python3-mako \
    python3-numpy \
    python3-requests \
    python3-scipy \
    python3-setuptools \
    python3-ruamel.yaml \
    && rm -rf /var/lib/apt/lists/*

# Build UHD (USRP Hardware Driver) from source
WORKDIR /tmp
RUN git clone --depth 1 --branch v4.6.0.0 https://github.com/EttusResearch/uhd.git && \
    cd uhd/host && \
    mkdir build && cd build && \
    cmake ../ -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Download UHD images
RUN /usr/local/bin/uhd_images_downloader || true

# Copy LTESniffer source
WORKDIR /app
COPY . /app/

# Build LTESniffer
RUN mkdir -p build && cd build && \
    cmake ../ -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make -j$(nproc)

# ==============================================================================
# Runtime Stage
# ==============================================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfftw3-3 \
    libmbedtls14 \
    libboost-all-dev \
    libconfig++9v5 \
    libsctp1 \
    libglib2.0-0 \
    libudev1 \
    libcurl4 \
    libqt5core5a \
    libqt5charts5 \
    libusb-1.0-0 \
    libncurses5 \
    tshark \
    wireshark-common \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built binaries from builder
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/share/uhd /usr/share/uhd
COPY --from=builder /app/build/src/LTESniffer /app/LTESniffer
COPY --from=builder /app/README.md /app/

# Update library cache
RUN ldconfig

# Create data directories
RUN mkdir -p /app/data /app/pcap

# Default command - show help
CMD ["./LTESniffer", "-h"]
