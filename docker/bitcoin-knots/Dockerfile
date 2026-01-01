# =============================================================================
# Bitcoin Knots Dockerfile
# Multi-stage build with GPG signature verification
# Supports: x86_64 (amd64) and ARM64 (aarch64)
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Download and Verify
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS builder

ARG BITCOIN_VERSION=29.1.knots20250903
ARG TARGETARCH

# Install verification tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Determine architecture and download Bitcoin Knots
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x86_64") && \
    echo "Downloading Bitcoin Knots ${BITCOIN_VERSION} for ${ARCH}..." && \
    wget -q "https://bitcoinknots.org/files/29.x/${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz" && \
    wget -q "https://bitcoinknots.org/files/29.x/${BITCOIN_VERSION}/SHA256SUMS" && \
    wget -q "https://bitcoinknots.org/files/29.x/${BITCOIN_VERSION}/SHA256SUMS.asc"

# Import Bitcoin Knots signing keys from official guix.sigs repository
RUN echo "Importing Bitcoin Knots builder keys..." && \
    git clone --depth 1 https://github.com/bitcoinknots/guix.sigs guix.sigs-knots && \
    find guix.sigs-knots/builder-keys -name "*.gpg" -exec gpg --import {} \; 2>/dev/null || true

# Verify GPG signature on SHA256SUMS
RUN echo "Verifying GPG signature..." && \
    gpg --verify SHA256SUMS.asc SHA256SUMS

# Verify SHA256 checksum of the binary
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x86_64") && \
    echo "Verifying SHA256 checksum..." && \
    grep "bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz" SHA256SUMS | sha256sum -c -

# Extract verified binaries
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x86_64") && \
    echo "Extracting binaries..." && \
    tar -xzf "bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz" && \
    mv bitcoin-${BITCOIN_VERSION} /opt/bitcoin

# -----------------------------------------------------------------------------
# Stage 2: Runtime Image
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim

ARG USER_ID=1000
ARG GROUP_ID=1000

LABEL maintainer="bitcoin-stack"
LABEL description="Bitcoin Knots full node with GPG-verified binaries"

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libatomic1 \
    libevent-2.1-7 \
    libevent-pthreads-2.1-7 \
    libminiupnpc17 \
    libnatpmp1 \
    libzmq5 \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Create bitcoin user with specified UID/GID
RUN groupadd -g ${GROUP_ID} bitcoin && \
    useradd -u ${USER_ID} -g bitcoin -d /home/bitcoin -m -s /bin/bash bitcoin

# Copy verified binaries from builder stage
COPY --from=builder /opt/bitcoin/bin/bitcoind /usr/local/bin/
COPY --from=builder /opt/bitcoin/bin/bitcoin-cli /usr/local/bin/
COPY --from=builder /opt/bitcoin/bin/bitcoin-tx /usr/local/bin/
COPY --from=builder /opt/bitcoin/bin/bitcoin-util /usr/local/bin/

# Setup data directory
RUN mkdir -p /home/bitcoin/.bitcoin && \
    chown -R bitcoin:bitcoin /home/bitcoin

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/home/bitcoin/.bitcoin"]

# Mainnet ports
EXPOSE 8332 8333
# Testnet ports
EXPOSE 18332 18333
# ZMQ ports
EXPOSE 28332 28333 28334

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bitcoind"]
