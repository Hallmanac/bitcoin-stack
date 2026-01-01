#!/bin/bash
set -e

# If running as root, switch to lnd user
if [ "$(id -u)" = "0" ]; then
    # Fix ownership of data directory if needed
    chown -R lnd:lnd /home/lnd/.lnd

    # Run as lnd user
    exec gosu lnd "$@"
fi

# If lnd.conf exists in /tmp (mounted from config), copy it
if [ -f /tmp/lnd.conf ]; then
    cp /tmp/lnd.conf /home/lnd/.lnd/lnd.conf
fi

exec "$@"
