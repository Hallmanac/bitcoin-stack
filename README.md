# Bitcoin Stack

A sovereign Bitcoin + Lightning Network infrastructure using Docker.

**Features:**
- **Bitcoin Knots** full node with GPG-verified binaries
- **LND** Lightning Network daemon with GPG-verified binaries
- **Electrs** Electrum server for easy wallet connections
- **Tor** integration for maximum privacy (Tor-only connections)
- Multi-architecture support (x86_64 and ARM64)
- Easy configuration via `.env` file
- Works on Windows, Linux, and macOS

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Requirements](#requirements)
3. [Configuration](#configuration)
4. [Usage](#usage)
5. [Connecting Wallets](#connecting-wallets)
6. [Hidden Services (.onion)](#hidden-services-onion)
7. [Backup & Recovery](#backup--recovery)
8. [Maintenance](#maintenance)
9. [Troubleshooting](#troubleshooting)
10. [Security](#security)
11. [Architecture](#architecture)

---

## Quick Start

### Linux/macOS

```bash
git clone https://github.com/YOUR_USERNAME/bitcoin-stack.git
cd bitcoin-stack
chmod +x scripts/*.sh
./scripts/setup.sh
docker compose up -d
```

### Windows (PowerShell)

```powershell
git clone https://github.com/YOUR_USERNAME/bitcoin-stack.git
cd bitcoin-stack
.\scripts\setup.ps1
docker compose up -d
```

The setup script will:
1. Create `.env` with a secure RPC password
2. Generate configuration files
3. Build Docker images (with GPG verification)
4. Create data directories

**Initial sync takes 3-7 days** depending on your hardware and network.

---

## Requirements

### Hardware (Minimum)
- **CPU**: 2+ cores
- **RAM**: 8GB (4GB minimum, slower sync)
- **Storage**: 700GB+ SSD recommended (600GB blockchain + indexes)
- **Network**: Stable internet connection

### Hardware (Recommended)
- **CPU**: 4+ cores
- **RAM**: 16GB
- **Storage**: 1TB+ NVMe SSD
- **Network**: Unmetered connection

### Software
- **Docker**: 20.10+ with Docker Compose V2
- **Git**: For cloning the repository
- **OS**: Windows 10/11, Linux, or macOS

---

## Configuration

All configuration is done via the `.env` file. Copy `.env.example` to `.env` and customize:

### Key Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `DATA_DIR` | `./data` | Where blockchain and wallet data is stored |
| `BITCOIN_BLOCKS_DIR` | (empty) | Optional: Store blockchain on separate drive |
| `BITCOIN_NETWORK` | `mainnet` | Network: mainnet, testnet, signet |
| `BITCOIN_PRUNE` | `0` | 0=full node, or MB to prune to |
| `BITCOIN_DBCACHE` | `4096` | RAM for UTXO cache (MB) |
| `LND_ALIAS` | `MyLightningNode` | Your node's name on Lightning Network |
| `LND_COLOR` | `#FF6600` | Your node's color in explorers |
| `ELECTRS_PORT` | `50001` | Electrum server TCP port |

### Separate Blockchain Storage

To store the ~600GB blockchain on a different drive:

```env
DATA_DIR=./data
BITCOIN_BLOCKS_DIR=/mnt/hdd/bitcoin-blocks  # Linux
# or
BITCOIN_BLOCKS_DIR=D:/bitcoin-blocks        # Windows
```

---

## Usage

### Starting the Stack

```bash
docker compose up -d
```

### Stopping the Stack

```bash
docker compose down
```

### Viewing Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f bitcoind
docker compose logs -f lnd
docker compose logs -f electrs
docker compose logs -f tor
```

### Checking Status

```bash
docker compose ps
```

### Bitcoin CLI Commands

```bash
# Check sync progress
docker exec bitcoind bitcoin-cli -rpcuser=bitcoinrpc -rpcpassword=YOUR_PASSWORD getblockchaininfo

# Get network info
docker exec bitcoind bitcoin-cli -rpcuser=bitcoinrpc -rpcpassword=YOUR_PASSWORD getnetworkinfo

# Get peer info
docker exec bitcoind bitcoin-cli -rpcuser=bitcoinrpc -rpcpassword=YOUR_PASSWORD getpeerinfo
```

### LND Commands

```bash
# Create wallet (first time only, after Bitcoin syncs)
docker exec -it lnd lncli create

# Unlock wallet (after restart)
docker exec -it lnd lncli unlock

# Check node info
docker exec lnd lncli getinfo

# Check wallet balance
docker exec lnd lncli walletbalance

# List channels
docker exec lnd lncli listchannels
```

---

## Connecting Wallets

### Sparrow Wallet via Electrum (Recommended)

The easiest way to connect Sparrow is via the Electrs Electrum server.

**Local Connection:**
1. Open Sparrow → File → Preferences → Server
2. Select "Private Electrum"
3. Configure:
   - URL: `127.0.0.1`
   - Port: `50001`
   - Use SSL: No
4. Test Connection

**Remote Connection via Tor:**
1. Install Tor on your remote machine:
   - **macOS**: `brew install tor && brew services start tor`
   - **Linux**: `sudo apt install tor && sudo systemctl start tor`
   - **Windows**: Install Tor Browser (uses port 9150)

2. In Sparrow: File → Preferences → Server → Private Electrum
3. Enable **Use Proxy**: `127.0.0.1:9050` (or 9150 for Tor Browser)
4. URL: Your Electrs .onion address (see [Hidden Services](#hidden-services-onion))
5. Port: `50001`
6. Use SSL: No
7. Test Connection

### Sparrow Wallet via Bitcoin Core RPC

For direct RPC connection (requires RPC credentials):

**Local Connection:**
1. Open Sparrow → File → Preferences → Server
2. Select "Bitcoin Core"
3. Configure:
   - URL: `127.0.0.1`
   - Port: `8332`
   - User: `bitcoinrpc`
   - Password: (from your .env file)
4. Test Connection

**Remote Connection via Tor:**
1. Install Tor on your remote machine (see above)
2. In Sparrow: File → Preferences → Server → Bitcoin Core
3. Enable **Use Proxy**: `127.0.0.1:9050` (or 9150 for Tor Browser)
4. URL: Your Bitcoin RPC .onion address (see [Hidden Services](#hidden-services-onion))
5. Port: `8332`
6. Enter RPC credentials

### Zeus Wallet (Mobile)

1. Get your LND macaroon:
   ```bash
   docker exec lnd base64 /home/lnd/.lnd/data/chain/bitcoin/mainnet/admin.macaroon | tr -d '\n'
   ```

2. In Zeus: Settings → Connect a Node → +
3. Configure:
   - Node Type: LND
   - Host: Your LND REST .onion address
   - REST Port: `8080`
   - Macaroon: (paste from step 1)
   - Enable Tor

---

## Hidden Services (.onion)

After first start, Tor generates unique .onion addresses for your services.

### Finding Your Addresses

```bash
# Bitcoin RPC (for Sparrow via Bitcoin Core)
docker exec tor cat /var/lib/tor/bitcoin_rpc/hostname

# Bitcoin P2P (for bitnodes.io)
docker exec tor cat /var/lib/tor/bitcoin_p2p/hostname

# Electrs (for Sparrow via Electrum - recommended)
docker exec tor cat /var/lib/tor/electrs/hostname

# LND gRPC
docker exec tor cat /var/lib/tor/lnd_grpc/hostname

# LND REST (for Zeus)
docker exec tor cat /var/lib/tor/lnd_rest/hostname
```

### Testing Hidden Services

```bash
# Test Bitcoin RPC via Tor
docker exec tor curl --socks5-hostname 127.0.0.1:9050 \
  -u bitcoinrpc:YOUR_PASSWORD \
  --data-binary '{"jsonrpc":"1.0","method":"getblockcount","params":[]}' \
  http://YOUR_RPC_ONION.onion:8332/
```

### Making Your Node Visible on bitnodes.io

Your node is automatically visible once:
1. Bitcoin is fully synced
2. The P2P hidden service is running

Test at: https://bitnodes.io/nodes/YOUR_P2P_ONION.onion:8333/

---

## Backup & Recovery

### Critical Data to Backup

| Item | Location | Importance |
|------|----------|------------|
| **LND Seed (24 words)** | Written down at wallet creation | **CRITICAL** |
| **channel.backup** | `data/lnd/data/chain/bitcoin/mainnet/` | **CRITICAL** |
| **Tor hidden service keys** | `data/tor/*/` | Medium (preserves .onion addresses) |
| **.env file** | Project root | Medium (contains credentials) |

### Backup Commands

```bash
# Backup LND channel state (do this regularly!)
docker exec lnd lncli exportchanbackup --all > channel_backup_$(date +%Y%m%d).backup

# Backup Tor keys (preserves .onion addresses)
tar -czf tor_keys_$(date +%Y%m%d).tar.gz data/tor/*/hostname data/tor/*/hs_ed25519_*
```

### Recovery

**If you lose your LND wallet:**
1. Stop the stack: `docker compose down`
2. Delete LND data: `rm -rf data/lnd/*`
3. Start the stack: `docker compose up -d`
4. Recover with seed:
   ```bash
   docker exec -it lnd lncli create
   # Select "recover" and enter your 24-word seed
   ```
5. Import channel backup:
   ```bash
   docker exec lnd lncli restorechanbackup --multi_file=/path/to/backup
   ```

---

## Maintenance

### Updating Bitcoin Knots

1. Update version in `.env`:
   ```env
   BITCOIN_VERSION=29.1.knots20250903
   ```
2. Rebuild and restart:
   ```bash
   docker compose build bitcoind
   docker compose up -d bitcoind
   ```

### Updating LND

1. Update version in `.env`:
   ```env
   LND_VERSION=v0.18.3-beta
   ```
2. Rebuild and restart:
   ```bash
   docker compose build lnd
   docker compose up -d lnd
   ```
3. Unlock wallet:
   ```bash
   docker exec -it lnd lncli unlock
   ```

### Updating Electrs

1. Update version in `.env`:
   ```env
   ELECTRS_VERSION=0.10.6
   ```
2. Rebuild and restart:
   ```bash
   docker compose build electrs
   docker compose up -d electrs
   ```

**Note:** Electrs will re-index if needed, which can take several hours.

### Checking Disk Space

```bash
# Check data directory size
du -sh data/*

# Check Docker disk usage
docker system df
```

### Pruning Old Docker Data

```bash
# Remove unused images
docker image prune -a

# Remove all unused data (careful!)
docker system prune
```

---

## Troubleshooting

### Bitcoin Won't Sync

**Check logs:**
```bash
docker compose logs -f bitcoind
```

**Common issues:**
- **"Connection refused"**: Tor might not be ready. Wait and retry.
- **Low peer count**: Normal for Tor-only. Be patient.
- **Disk space**: Ensure 700GB+ available.

### LND Won't Start

**Check logs:**
```bash
docker compose logs -f lnd
```

**Common issues:**
- **"Waiting for bitcoind to sync"**: Bitcoin must fully sync first.
- **"Wallet not found"**: Create wallet with `docker exec -it lnd lncli create`
- **"Wallet locked"**: Unlock with `docker exec -it lnd lncli unlock`

### Electrs Won't Start or Sync

**Check logs:**
```bash
docker compose logs -f electrs
```

**Common issues:**
- **"Waiting for bitcoind"**: Bitcoin must fully sync first.
- **"Connection refused"**: Ensure Bitcoin is healthy and RPC is accessible.
- **High memory usage**: Normal during initial indexing. Set appropriate `ELECTRS_MEM_LIMIT`.
- **Slow indexing**: Initial index takes several hours. Be patient.

**Check indexing progress:**
```bash
docker compose logs electrs | grep -i "indexed"
```

### Tor Connection Issues

**Check Tor status:**
```bash
docker compose logs tor
docker exec tor cat /var/lib/tor/notice.log
```

**Verify SOCKS proxy:**
```bash
docker exec tor nc -z 127.0.0.1 9050 && echo "SOCKS OK"
```

### Container Keeps Restarting

**Check exit code:**
```bash
docker compose ps -a
```

**View recent logs:**
```bash
docker compose logs --tail 100 SERVICE_NAME
```

---

## Security

### Network Security

- All services run in an isolated Docker network
- RPC/gRPC ports only bound to localhost (127.0.0.1)
- All external connections routed through Tor
- No clearnet IP exposure

### Credential Security

- RPC password stored only in `.env` (gitignored)
- LND uses macaroon-based authentication
- Tor control port uses cookie authentication

### Best Practices

1. **Never commit `.env`** to version control
2. **Backup your LND seed** offline (write it down!)
3. **Backup channel.backup** regularly
4. **Keep software updated** for security patches
5. **Use strong, unique RPC passwords**

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Docker Network (172.28.0.0/16)                        │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │
│  │     Tor     │    │  Bitcoin    │    │     LND     │    │   Electrs   │   │
│  │  172.28.0.2 │    │  Knots      │    │  172.28.0.4 │    │  172.28.0.5 │   │
│  │             │    │  172.28.0.3 │    │             │    │             │   │
│  │  SOCKS:9050 │◄───│             │◄───│  gRPC:10009 │    │  TCP:50001  │   │
│  │  Ctrl:9051  │    │  RPC:8332   │    │  REST:8080  │    │             │   │
│  │             │    │  P2P:8333   │    │  P2P:9735   │    │             │   │
│  │  Hidden     │    │  ZMQ:28332+ │    │             │    │             │   │
│  │  Services   │    │             │    │             │    │             │   │
│  └─────────────┘    └──────┬──────┘    └─────────────┘    └──────┬──────┘   │
│         │                  │                  │                   │          │
│         └──────────────────┴──────────────────┴───────────────────┘          │
│                                     │                                        │
└─────────────────────────────────────┼────────────────────────────────────────┘
                                      │
                              ┌───────┴───────┐
                              │   Internet    │
                              │  (via Tor)    │
                              └───────────────┘
```

### Data Flow

1. **Bitcoin Knots** syncs blockchain via Tor
2. **LND** connects to Bitcoin Knots for chain data
3. **Electrs** indexes the blockchain from Bitcoin Knots
4. **Tor** provides hidden services for remote access
5. **Wallets** connect via Electrum/RPC (local) or Tor (remote)

### Ports

| Port | Service | Protocol | Access |
|------|---------|----------|--------|
| 8332 | Bitcoin RPC | JSON-RPC | localhost + Tor |
| 8333 | Bitcoin P2P | Bitcoin | Tor only |
| 9050 | Tor SOCKS | SOCKS5 | Internal |
| 9051 | Tor Control | Control | Internal |
| 10009 | LND gRPC | gRPC | localhost + Tor |
| 8080 | LND REST | REST | localhost + Tor |
| 9735 | LND P2P | Lightning | Tor only |
| 50001 | Electrs | Electrum TCP | localhost + Tor |

---

## License

MIT License - See LICENSE file for details.

## Contributing

Contributions welcome! Please open an issue or pull request.

## Acknowledgments

- [Bitcoin Knots](https://bitcoinknots.org/) by Luke Dashjr
- [LND](https://github.com/lightningnetwork/lnd) by Lightning Labs
- [Electrs](https://github.com/romanz/electrs) by Roman Zeyde
- [Tor Project](https://www.torproject.org/)
- Inspired by [bitcoin-knots-docker](https://github.com/rerrl/bitcoin-knots-docker)
