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
- CCIP 1.5 deployment compatibility

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

Update values and **IMPORTANTLY set SNAPSHOT** for faster sync (see below).

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
# Leave SNAPSHOT empty in .env
./kaiad up
```

⚠️ **NOT RECOMMENDED** - This will take approximately 5-7 days to fully sync.

### Option 2: Fast Sync with Snapshot (HIGHLY RECOMMENDED)

Download and use a snapshot for much faster initial sync:

**Full Node Snapshot** (recommended for most use cases):
```bash
# In .env:
SNAPSHOT=https://storage.googleapis.com/kaia-chaindata/mainnet/kaia-mainnet-chaindata-latest.tar.gz
```

**Snapshot Details**:
- Size: ~1.9TB compressed / ~2.4TB uncompressed
- Update frequency: Daily
- Download time: 2-6 hours (depending on connection)
- Extraction time: 1-3 hours
- Total setup time: 3-9 hours vs 5-7 days

The snapshot will be automatically downloaded, verified, and extracted on first startup.

**Alternative: Live Pruning Snapshot** (smaller, for limited disk space):
```bash
# In .env:
SNAPSHOT=https://storage.googleapis.com/kaia-chaindata/mainnet/kaia-mainnet-pruning-chaindata-latest.tar.gz
```

## Commands

The `kaiad` script provides a convenient CLI for managing your node:

### Basic Operations
- `./kaiad up` - Start the Kaia node
- `./kaiad down` - Stop the Kaia node
- `./kaiad restart` - Restart the Kaia node
- `./kaiad logs` - View and follow logs

### Maintenance
- `./kaiad update` - Rebuild Docker image (e.g., after changing `KEN_VERSION`)
- `./kaiad check-sync` - Check if node is synced with the network
- `./kaiad ps` - Show service status

### Advanced
- `./kaiad cmd <command>` - Run ken CLI commands
- `./kaiad exec <command>` - Execute command in running container
- `./kaiad version` - Show version information

## Upgrading ken Binary

To upgrade to a new ken version:

1. Update `KEN_VERSION` in `.env` to the desired version tag (e.g., `v2.2.2`)
2. Rebuild the Docker image:
```bash
./kaiad update
```

**Note**: Latest stable release is `v2.2.2` (March 2026, includes Osaka hardfork).

3. Restart the node:
```bash
./kaiad restart
```

The ken binary is compiled from source during `docker compose build` in a multi-stage Dockerfile.

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
| Prometheus | 61001 | Metrics endpoint |

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

## Using with CCIP 1.5

This RPC node is designed for use with Chainlink CCIP 1.5 deployments on Kaia.

Configure your Chainlink node to use:
- **HTTP RPC**: `http://localhost:8551`
- **WebSocket**: `ws://localhost:8552`
- **Chain ID**: `8217` (decimal) or `0x2019` (hex)

## Monitoring

Prometheus metrics are exposed on port 61001. Add to your Prometheus config:

```yaml
scrape_configs:
  - job_name: 'kaia-node'
    static_configs:
      - targets: ['localhost:61001']
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

### Snapshot download is slow
The entrypoint script uses `aria2c` if available for faster multi-connection downloads. If you experience slow downloads, you can:
1. Download the snapshot manually to `/tmp/kaia-snapshot.tar.gz`
2. Place it in the container before first start
3. Or use a different mirror/CDN if available

## Hardware Requirements

**Minimum**:
- 8 CPU cores
- 32 GB RAM
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
