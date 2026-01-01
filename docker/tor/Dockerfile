# =============================================================================
# Tor Dockerfile
# Provides Tor SOCKS proxy and hidden service functionality
# Supports: x86_64 (amd64) and ARM64 (aarch64)
# =============================================================================

FROM debian:bookworm-slim

ARG USER_ID=1000
ARG GROUP_ID=1000

LABEL maintainer="bitcoin-stack"
LABEL description="Tor proxy with hidden service support for Bitcoin stack"

# Install Tor and utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    tor \
    gosu \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Create tor user with specified UID/GID (override default tor user)
RUN userdel -r debian-tor 2>/dev/null || true && \
    groupadd -g ${GROUP_ID} tor && \
    useradd -u ${USER_ID} -g tor -d /var/lib/tor -m -s /bin/bash tor

# Setup directories
RUN mkdir -p /var/lib/tor /var/log/tor /run/tor && \
    chown -R tor:tor /var/lib/tor /var/log/tor /run/tor && \
    chmod 700 /var/lib/tor

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/var/lib/tor"]

# SOCKS proxy port
EXPOSE 9050
# Control port
EXPOSE 9051

ENTRYPOINT ["/entrypoint.sh"]
