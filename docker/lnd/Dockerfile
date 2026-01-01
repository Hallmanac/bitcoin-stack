# =============================================================================
# LND (Lightning Network Daemon) Dockerfile
# Multi-stage build with GPG signature verification
# Supports: x86_64 (amd64) and ARM64 (aarch64)
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Download and Verify
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS builder

ARG LND_VERSION=v0.18.3-beta
ARG TARGETARCH

# Install verification tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Determine architecture and download LND
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "linux-arm64" || echo "linux-amd64") && \
    echo "Downloading LND ${LND_VERSION} for ${ARCH}..." && \
    wget -q "https://github.com/lightningnetwork/lnd/releases/download/${LND_VERSION}/lnd-${ARCH}-${LND_VERSION}.tar.gz" && \
    wget -q "https://github.com/lightningnetwork/lnd/releases/download/${LND_VERSION}/manifest-${LND_VERSION}.txt" && \
    wget -q "https://github.com/lightningnetwork/lnd/releases/download/${LND_VERSION}/manifest-roasbeef-${LND_VERSION}.sig"

# Import roasbeef's (Olaoluwa Osuntokun) signing key
RUN echo "Importing LND release signing key (roasbeef)..." && \
    wget -qO- https://raw.githubusercontent.com/lightningnetwork/lnd/master/scripts/keys/roasbeef.asc | gpg --import

# Verify GPG signature on manifest
RUN echo "Verifying GPG signature..." && \
    gpg --verify "manifest-roasbeef-${LND_VERSION}.sig" "manifest-${LND_VERSION}.txt"

# Verify SHA256 checksum of the binary
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "linux-arm64" || echo "linux-amd64") && \
    echo "Verifying SHA256 checksum..." && \
    grep "lnd-${ARCH}-${LND_VERSION}.tar.gz" "manifest-${LND_VERSION}.txt" | sha256sum -c -

# Extract verified binaries
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "linux-arm64" || echo "linux-amd64") && \
    echo "Extracting binaries..." && \
    tar -xzf "lnd-${ARCH}-${LND_VERSION}.tar.gz" && \
    mv "lnd-${ARCH}-${LND_VERSION}" /opt/lnd

# -----------------------------------------------------------------------------
# Stage 2: Runtime Image
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim

ARG USER_ID=1000
ARG GROUP_ID=1000

LABEL maintainer="bitcoin-stack"
LABEL description="LND Lightning Network Daemon with GPG-verified binaries"

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Create lnd user with specified UID/GID
RUN groupadd -g ${GROUP_ID} lnd && \
    useradd -u ${USER_ID} -g lnd -d /home/lnd -m -s /bin/bash lnd

# Copy verified binaries from builder stage
COPY --from=builder /opt/lnd/lnd /usr/local/bin/
COPY --from=builder /opt/lnd/lncli /usr/local/bin/

# Setup data directory
RUN mkdir -p /home/lnd/.lnd && \
    chown -R lnd:lnd /home/lnd

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/home/lnd/.lnd"]

# Lightning P2P port
EXPOSE 9735
# gRPC port
EXPOSE 10009
# REST port
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["lnd"]
