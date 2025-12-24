# ==============================================================================
# srsRAN 5G gNB - Open Source 5G Base Station
# ==============================================================================
# Build: docker build -t homelab/srsran-gnb .
# Requirements: USRP SDR, high-performance CPU, UHD 4.0+
# ==============================================================================

FROM ubuntu:22.04 AS builder

LABEL maintainer="HomeLab"
LABEL description="srsRAN 5G gNB - Software 5G Base Station"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake \
    make \
    gcc \
    g++ \
    pkg-config \
    libfftw3-dev \
    libmbedtls-dev \
    libsctp-dev \
    libyaml-cpp-dev \
    libboost-all-dev \
    git \
    autoconf \
    automake \
    build-essential \
    ccache \
    cpufrequtils \
    doxygen \
    ethtool \
    inetutils-tools \
    libncurses5 \
    libncurses5-dev \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    libusb-dev \
    python3-dev \
    python3-mako \
    python3-numpy \
    python3-requests \
    python3-scipy \
    python3-setuptools \
    python3-ruamel.yaml \
    libzmq3-dev \
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

# Copy srsRAN source
WORKDIR /app
COPY . /app/

# Build srsRAN
RUN mkdir -p build && cd build && \
    cmake ../ \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=Off && \
    make -j$(nproc) && \
    make install

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
    libsctp1 \
    libyaml-cpp0.7 \
    libboost-program-options1.74.0 \
    libusb-1.0-0 \
    libncurses5 \
    libzmq5 \
    iproute2 \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built binaries from builder
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/share/uhd /usr/share/uhd
COPY --from=builder /app/build/apps/gnb/gnb /app/gnb
COPY --from=builder /app/configs /app/configs
COPY --from=builder /app/README.md /app/

# Update library cache
RUN ldconfig

# Create directories
RUN mkdir -p /app/logs /app/configs

# Default command - show help
CMD ["./gnb", "--help"]
