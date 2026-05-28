# kaia-docker

Docker compose for Kaia Endpoint Node (ken).

Meant to be used with [central-proxy-docker](https://github.com/CryptoManufaktur-io/central-proxy-docker) for traefik
and Prometheus remote write; use `:ext-network.yml` in `COMPOSE_FILE` inside `.env` in that case.

## Overview

This project provides a production-ready Docker setup for running a Kaia Endpoint Node. It supports:
- Full node and archive node configurations
- Snapshot-based fast sync (highly recommended)
- EVM JSON-RPC and WebSocket endpoints
- Prometheus metrics
- Traefik integration for HTTPS

## Network Information

- **Chain ID**: `8217` (0x2019)
- **Network**: Kaia Mainnet (legacy name: Cypress)
- **Testnet**: Kairos (Chain ID: 1001 / 0x3E9, legacy name: Baobab)
- **Binary**: `ken` (Kaia Endpoint Node)
- **RPC Ports**: HTTP (8551), WebSocket (8552)
- **P2P Port**: 32323

## Quick Setup

1. **Clone and configure**:
```bash
cp default.env .env
nano .env
```

**IMPORTANTLY set SNAPSHOT** for faster sync (see below).

2. **Expose RPC ports locally** (optional):

If you want the RPC ports exposed locally, add `rpc-shared.yml` to `COMPOSE_FILE` inside `.env`:
```bash
COMPOSE_FILE=kaia.yml:rpc-shared.yml
```

3. **Start the node**:
```bash
./kaiad up
```

## Syncing Options

### Option 1: Sync from Genesis (Very Slow - 5-7+ days)

Start without a snapshot. The node will sync from block 0:
```bash
# In .env (default):
SNAPSHOT=
./kaiad up
```

⚠️ **NOT RECOMMENDED** - This will take approximately 5-7 days to fully sync.

### Option 2: Fast Sync with Snapshot (HIGHLY RECOMMENDED)

Download and use a snapshot for much faster initial sync:

**Live-Pruning Snapshot** (RECOMMENDED for production):
```bash
# In .env, set:
SNAPSHOT=https://storage.googleapis.com/kaia-chaindata/mainnet/pruning-chaindata/kaia-mainnet-pruning-chaindata-latest.tar.gz
LIVE_PRUNING=true
```

**Snapshot Details**:
- Size: ~2.4TB compressed / ~2.9TB uncompressed
- Update frequency: Daily
- Disk efficient: Uses state pruning to reduce storage requirements
- **IMPORTANT**: Requires `LIVE_PRUNING=true` in .env
- Download time: 2-6 hours (depending on connection)
- Extraction time: 1-3 hours
- Total setup time: 3-9 hours vs 5-7 days

The snapshot will be automatically downloaded and extracted on first startup using aria2c (16 connections) and pigz (parallel decompression) for maximum speed.

**Alternative: Full Archive Snapshot** (for nodes requiring complete state history):
```bash
# In .env, set:
SNAPSHOT=https://storage.googleapis.com/kaia-chaindata/mainnet/kaia-mainnet-chaindata-latest.tar.gz
LIVE_PRUNING=false
```
- Size: ~1.9TB compressed / ~2.4TB uncompressed
- Keeps full state history (larger disk requirements)

## Commands

The `kaiad` script provides a convenient CLI for managing your node:

### Basic Operations
- `./kaiad up` - Start the Kaia node
- `./kaiad down` - Stop the Kaia node
- `./kaiad restart` - Restart the Kaia node
- `./kaiad logs` - View and follow logs

### Maintenance
- `./kaiad update` - Rebuild Docker image (e.g., after changing `KAIA_TAG`)
- `./kaiad check-sync` - Check if node is synced with the network
- `./kaiad ps` - Show service status

### Advanced
- `./kaiad cmd <command>` - Run ken CLI commands
- `./kaiad exec <command>` - Execute command in running container
- `./kaiad version` - Show version information

## Upgrading ken Binary

To upgrade to a new ken version:

1. Update `KAIA_TAG` in `.env` to the desired version tag (e.g., `v2.2.2`)
2. Rebuild the Docker image:
```bash
./kaiad update
```

**Note**: Latest stable release is `v2.2.2` (March 2026, includes Osaka hardfork).

3. Restart the node:
```bash
./kaiad restart
```

Uses the official kaiachain/kaia Docker image from Docker Hub (no custom build required).

## Testing the RPC Endpoint

After the node is synced, test the JSON-RPC endpoint:

```bash
# Get current block number
curl -L http://localhost:8551 -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0","method": "eth_blockNumber","params": [],"id": 1}'

# Get chain ID
curl -L http://localhost:8551 -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0","method": "eth_chainId","params": [],"id": 1}'

# Expected response: {"jsonrpc":"2.0","id":1,"result":"0x2019"}  (8217 in decimal)
```

Expected response format:
```json
{"jsonrpc":"2.0","id":1,"result":"0x..."}
```

## Check Sync Status

Compare your local node height with the network:

```bash
./kaiad check-sync
```

The script will sample the sync rate over ~10 seconds and provide an ETA estimate.

Exit codes:
- `0` - Node is synced (height and hash match)
- `1` - Node is syncing (behind public RPC)
- `2` - Node is diverged (hash mismatch, possible fork)
- `3` - Local RPC error
- `4` - Public RPC error
- `5` - Parse error
- `7` - Docker/container error

## Port Configuration

Default ports (configurable in `.env`):

| Service | Port | Description |
|---------|------|-------------|
| JSON-RPC | 8551 | HTTP JSON-RPC endpoint |
| WebSocket | 8552 | WebSocket endpoint |
| P2P | 32323 | Peer-to-peer networking |
| Prometheus | 8551 | Metrics endpoint (via RPC) |

## Data Storage

Node data is stored in a Docker volume named `kaia-data`. To inspect or backup:

```bash
# List volumes
docker volume ls | grep kaia

# Inspect volume
docker volume inspect kaia-docker_kaia-data

# Backup volume (with node stopped)
./kaiad down
docker run --rm -v kaia-docker_kaia-data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/kaia-backup.tar.gz /data
```

## Troubleshooting

### Node not syncing
```bash
# Check logs
./kaiad logs

# Check if ken is running
./kaiad ps
```

### Out of disk space
Kaia blockchain data is large. Ensure you have:
- Full node: ~2.5TB+ available (with snapshot: 2.4TB uncompressed)
- Live pruning: ~1TB+ available

### Reset and resync
```bash
./kaiad down
docker volume rm kaia-docker_kaia-data
# Update SNAPSHOT in .env if desired
./kaiad up
```

## Hardware Requirements

**Minimum**:
- 8 CPU cores
- 64 GB RAM
- 3 TB SSD storage (for full node)
- 100 Mbps network

**Recommended**:
- 16+ CPU cores
- 64 GB RAM
- 4 TB NVMe SSD storage
- 1 Gbps network

**Note**: These requirements are higher than typical EVM chains due to Kaia's high throughput (4000+ TPS).

## References

- [Kaia Documentation](https://docs.kaia.io/)
- [Kaia GitHub](https://github.com/kaiachain/kaia)
- [Kaia Snapshots](https://packages.kaia.io/mainnet/chaindata/)
- [Public RPC Endpoints](https://docs.kaia.io/references/public-en/)

## Version

This is kaia-docker v1.0.0
