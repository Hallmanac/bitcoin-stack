#!/bin/bash
# =============================================================================
# Generate Secure RPC Password
# =============================================================================
# Generates a 32-byte (64 character) hex password suitable for Bitcoin RPC
# =============================================================================

if command -v openssl &> /dev/null; then
    PASSWORD=$(openssl rand -hex 32)
elif [ -f /dev/urandom ]; then
    PASSWORD=$(head -c 32 /dev/urandom | xxd -p | tr -d '\n')
else
    echo "ERROR: Cannot generate secure random password."
    echo "Please install openssl or ensure /dev/urandom is available."
    exit 1
fi

echo ""
echo "Generated RPC Password:"
echo "========================"
echo "$PASSWORD"
echo ""
echo "Add this to your .env file:"
echo "BITCOIN_RPC_PASS=$PASSWORD"
echo ""
