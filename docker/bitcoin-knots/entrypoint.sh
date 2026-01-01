#!/bin/bash
set -e

# If running as root, set up and switch to bitcoin user
if [ "$(id -u)" = "0" ]; then
    # Copy config file if mounted
    if [ -f /tmp/bitcoin.conf ]; then
        cp /tmp/bitcoin.conf /home/bitcoin/.bitcoin/bitcoin.conf
    fi

    # Fix ownership of data directory
    chown -R bitcoin:bitcoin /home/bitcoin/.bitcoin

    # Run as bitcoin user
    exec gosu bitcoin "$@"
fi

# If not root (shouldn't happen), just copy config and run
if [ -f /tmp/bitcoin.conf ]; then
    cp /tmp/bitcoin.conf /home/bitcoin/.bitcoin/bitcoin.conf
fi

exec "$@"
