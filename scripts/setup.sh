#!/bin/bash
# =============================================================================
# Bitcoin Stack Setup Script (Linux/Mac)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "============================================================================="
echo "  Bitcoin Stack Setup"
echo "  Bitcoin Knots + LND + Tor"
echo "============================================================================="
echo -e "${NC}"

# -----------------------------------------------------------------------------
# Check prerequisites
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker is not installed. Please install Docker first.${NC}"
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo -e "${RED}ERROR: Docker Compose is not installed or not working.${NC}"
    exit 1
fi

echo -e "${GREEN}Docker and Docker Compose found.${NC}"

# -----------------------------------------------------------------------------
# Create .env file
# -----------------------------------------------------------------------------
cd "$PROJECT_DIR"

if [ -f .env ]; then
    echo -e "${YELLOW}Found existing .env file.${NC}"
    read -p "Do you want to regenerate it? (y/N): " REGEN
    if [[ ! "$REGEN" =~ ^[Yy]$ ]]; then
        echo "Keeping existing .env file."
    else
        cp .env .env.backup.$(date +%Y%m%d%H%M%S)
        echo "Backed up existing .env file."
        cp .env.example .env
    fi
else
    echo "Creating .env file from template..."
    cp .env.example .env
fi

# -----------------------------------------------------------------------------
# Generate RPC password
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Generating secure RPC password...${NC}"

RPC_PASS=$(openssl rand -hex 32 2>/dev/null || head -c 64 /dev/urandom | xxd -p | tr -d '\n' | head -c 64)

# Update .env with generated password
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/BITCOIN_RPC_PASS=.*/BITCOIN_RPC_PASS=${RPC_PASS}/" .env
else
    # Linux
    sed -i "s/BITCOIN_RPC_PASS=.*/BITCOIN_RPC_PASS=${RPC_PASS}/" .env
fi

echo -e "${GREEN}RPC password generated and saved to .env${NC}"

# -----------------------------------------------------------------------------
# Get user ID
# -----------------------------------------------------------------------------
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - Docker Desktop handles permissions differently
    echo "Detected macOS - using default UID/GID (1000)"
else
    # Linux - use current user's UID/GID
    echo "Setting UID/GID to current user ($CURRENT_UID:$CURRENT_GID)"
    sed -i "s/USER_ID=.*/USER_ID=${CURRENT_UID}/" .env
    sed -i "s/GROUP_ID=.*/GROUP_ID=${CURRENT_GID}/" .env
fi

# -----------------------------------------------------------------------------
# Create data directories
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Creating data directories...${NC}"

DATA_DIR=$(grep "^DATA_DIR=" .env | cut -d '=' -f2)
DATA_DIR=${DATA_DIR:-./data}

# Expand relative path
if [[ "$DATA_DIR" == ./* ]]; then
    DATA_DIR="$PROJECT_DIR/${DATA_DIR:2}"
fi

mkdir -p "$DATA_DIR/bitcoin"
mkdir -p "$DATA_DIR/lnd"
mkdir -p "$DATA_DIR/tor"

echo -e "${GREEN}Data directories created at: $DATA_DIR${NC}"

# -----------------------------------------------------------------------------
# Generate config files from templates
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Generating configuration files...${NC}"

# Source .env file
set -a
source .env
set +a

# Generate bitcoin.conf
envsubst < config/bitcoin.conf.template > config/bitcoin.conf
echo "Generated config/bitcoin.conf"

# Generate lnd.conf (mostly static, but process anyway)
cp config/lnd.conf.template config/lnd.conf
echo "Generated config/lnd.conf"

echo -e "${GREEN}Configuration files generated.${NC}"

# -----------------------------------------------------------------------------
# Build Docker images
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Building Docker images (this may take a few minutes)...${NC}"
echo "This includes GPG signature verification of binaries."

docker compose build

echo -e "${GREEN}Docker images built successfully.${NC}"

# -----------------------------------------------------------------------------
# Done!
# -----------------------------------------------------------------------------
echo ""
echo -e "${GREEN}=============================================================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}=============================================================================${NC}"
echo ""
echo "Your RPC credentials:"
echo -e "  Username: ${BLUE}${BITCOIN_RPC_USER:-bitcoinrpc}${NC}"
echo -e "  Password: ${BLUE}${RPC_PASS}${NC}"
echo ""
echo "Next steps:"
echo "  1. Review and customize .env if needed"
echo "  2. Start the stack:  docker compose up -d"
echo "  3. Monitor logs:     docker compose logs -f"
echo "  4. Check status:     docker compose ps"
echo ""
echo "After Bitcoin syncs (~3-7 days), create your LND wallet:"
echo "  docker exec -it lnd lncli create"
echo ""
echo "For more information, see README.md"
echo ""
