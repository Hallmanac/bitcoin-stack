#!/bin/bash
set -e

# If running as root, set up and switch to lnd user
if [ "$(id -u)" = "0" ]; then
    # Copy config file if mounted
    if [ -f /tmp/lnd.conf ]; then
        cp /tmp/lnd.conf /home/lnd/.lnd/lnd.conf
    fi

    # Fix ownership of data directory
    chown -R lnd:lnd /home/lnd/.lnd

    # Run as lnd user
    exec gosu lnd "$@"
fi

# If not root (shouldn't happen), just copy config and run
if [ -f /tmp/lnd.conf ]; then
    cp /tmp/lnd.conf /home/lnd/.lnd/lnd.conf
fi

exec "$@"
