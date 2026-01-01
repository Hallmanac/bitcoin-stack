# =============================================================================
# Electrs (Electrum Rust Server) Dockerfile
# Multi-stage build from source
# Supports: x86_64 (amd64) and ARM64 (aarch64)
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Download Source
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS downloader

ARG ELECTRS_VERSION=0.10.6

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Download source tarball
# Note: Electrs does not provide official checksums or GPG signatures for releases.
# We pin to a specific version tag and verify the download is a valid gzip archive.
# For maximum security, consider building from a specific commit hash instead.
RUN wget -q "https://github.com/romanz/electrs/archive/refs/tags/v${ELECTRS_VERSION}.tar.gz" -O electrs.tar.gz

# Verify the download is valid (not empty or error page)
RUN test -s electrs.tar.gz && \
    file electrs.tar.gz | grep -q "gzip compressed" && \
    echo "Source tarball downloaded and verified as valid gzip archive"

# Extract source
RUN tar -xzf electrs.tar.gz && mv electrs-${ELECTRS_VERSION} /electrs-src

# -----------------------------------------------------------------------------
# Stage 2: Build from Source
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS builder

ARG ELECTRS_VERSION=0.10.6

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    clang \
    cmake \
    curl \
    librocksdb-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"

# Copy verified source from downloader stage
COPY --from=downloader /electrs-src /electrs-src

WORKDIR /electrs-src

# Build electrs
ENV ROCKSDB_INCLUDE_DIR=/usr/include
ENV ROCKSDB_LIB_DIR=/usr/lib
RUN cargo build --locked --release

# -----------------------------------------------------------------------------
# Stage 3: Runtime Image
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim

ARG USER_ID=1000
ARG GROUP_ID=1000

LABEL maintainer="bitcoin-stack"
LABEL description="Electrs Electrum Server"

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    librocksdb7.8 \
    gosu \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Create electrs user
RUN groupadd -g ${GROUP_ID} electrs && \
    useradd -u ${USER_ID} -g electrs -d /home/electrs -m -s /bin/bash electrs

# Copy binary from builder
COPY --from=builder /electrs-src/target/release/electrs /usr/local/bin/

# Setup data directory
RUN mkdir -p /home/electrs/db && \
    chown -R electrs:electrs /home/electrs

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/home/electrs/db"]

# Electrum TCP port
EXPOSE 50001
# Prometheus metrics port (optional)
EXPOSE 4224

ENTRYPOINT ["/entrypoint.sh"]
CMD ["electrs"]
