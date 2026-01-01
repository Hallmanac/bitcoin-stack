#!/bin/bash
set -e

# If running as root, switch to bitcoin user
if [ "$(id -u)" = "0" ]; then
    # Fix ownership of data directory if needed
    chown -R bitcoin:bitcoin /home/bitcoin/.bitcoin

    # Run as bitcoin user
    exec gosu bitcoin "$@"
fi

# If bitcoin.conf exists in /tmp (mounted from config), copy it
if [ -f /tmp/bitcoin.conf ]; then
    cp /tmp/bitcoin.conf /home/bitcoin/.bitcoin/bitcoin.conf
fi

exec "$@"
