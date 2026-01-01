#!/bin/bash
set -e

# If running as root, switch to electrs user
if [ "$(id -u)" = "0" ]; then
    # Fix ownership of data directory if needed
    chown -R electrs:electrs /home/electrs/db

    # Run as electrs user
    exec gosu electrs "$@"
fi

exec "$@"
