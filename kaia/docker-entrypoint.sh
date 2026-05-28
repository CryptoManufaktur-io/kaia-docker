#!/usr/bin/env bash
set -euo pipefail

# Kaia Endpoint Node (ken) Docker Entrypoint
# This script initializes and starts a Kaia endpoint node

# Required environment variables
NETWORK="${NETWORK:-mainnet}"
DATA_DIR="${DATA_DIR:-/kaia}"
SNAPSHOT="${SNAPSHOT:-}"
LOG_LEVEL="${LOG_LEVEL:-info}"

# Port configuration
PORT="${PORT:-32323}"
RPC_PORT="${RPC_PORT:-8551}"
WS_PORT="${WS_PORT:-8552}"
RPC_ADDR="${RPC_ADDR:-0.0.0.0}"
WS_ADDR="${WS_ADDR:-0.0.0.0}"

# API configuration
RPC_API="${RPC_API:-klay,eth,net,web3}"
WS_API="${WS_API:-klay,eth,net,web3}"
RPC_VHOSTS="${RPC_VHOSTS:-*}"
RPC_CORSDOMAIN="${RPC_CORSDOMAIN:-*}"
WS_ORIGINS="${WS_ORIGINS:-*}"

# Sync mode: "full" or "snap"
SYNCMODE="${SYNCMODE:-full}"

# Additional flags
EXTRA_FLAGS="${EXTRA_FLAGS:-}"

# Initialization marker
INIT_MARKER="${DATA_DIR}/.initialized"

echo "=================================================="
echo "Kaia Endpoint Node (ken) - Docker Entrypoint"
echo "=================================================="
echo "Network:   ${NETWORK}"
echo "Data Dir:  ${DATA_DIR}"
echo "Sync Mode: ${SYNCMODE}"
echo "P2P Port:  ${PORT}"
echo "RPC Port:  ${RPC_PORT}"
echo "WS Port:   ${WS_PORT}"
echo "=================================================="

# Function to download and extract snapshot
download_snapshot() {
    local snapshot_url="$1"
    local snapshot_file="/tmp/kaia-snapshot.tar.gz"

    echo "==> Downloading snapshot: ${snapshot_url}"

    # Use aria2c for faster multi-connection download if available
    if command -v aria2c >/dev/null 2>&1; then
        aria2c --file-allocation=none --max-connection-per-server=8 \
               --split=8 --min-split-size=10M \
               --continue=true --dir=/tmp --out=kaia-snapshot.tar.gz \
               "${snapshot_url}"
    else
        wget -c -O "${snapshot_file}" "${snapshot_url}"
    fi

    echo "==> Extracting snapshot to ${DATA_DIR}/data..."
    mkdir -p "${DATA_DIR}/data"
    tar -xzf "${snapshot_file}" -C "${DATA_DIR}/data" --strip-components=1

    echo "==> Cleaning up snapshot file..."
    rm -f "${snapshot_file}"

    echo "==> Snapshot extracted successfully"
}

# First-time initialization
if [ ! -f "${INIT_MARKER}" ]; then
    echo "==> First-time initialization detected"

    # Create data directory
    mkdir -p "${DATA_DIR}/data" "${DATA_DIR}/logs"

    # Download snapshot if specified
    if [ -n "${SNAPSHOT}" ]; then
        download_snapshot "${SNAPSHOT}"
    else
        echo "==> No snapshot specified. Node will sync from genesis (this will take several days)"
    fi

    # Create initialization marker
    touch "${INIT_MARKER}"
    echo "==> Initialization complete"
else
    echo "==> Data directory already initialized"
fi

# Build ken command
KEN_CMD="ken"

# Network configuration
if [ "${NETWORK}" = "mainnet" ]; then
    KEN_CMD="${KEN_CMD} --mainnet"
elif [ "${NETWORK}" = "kairos" ]; then
    KEN_CMD="${KEN_CMD} --kairos"
fi

# Data directory
KEN_CMD="${KEN_CMD} --datadir ${DATA_DIR}/data"

# Sync mode
KEN_CMD="${KEN_CMD} --syncmode ${SYNCMODE}"

# P2P configuration
KEN_CMD="${KEN_CMD} --port ${PORT}"
KEN_CMD="${KEN_CMD} --maxconnections 100"

# RPC configuration
KEN_CMD="${KEN_CMD} --rpc --rpcport ${RPC_PORT}"
KEN_CMD="${KEN_CMD} --rpcaddr ${RPC_ADDR}"
KEN_CMD="${KEN_CMD} --rpcapi ${RPC_API}"
KEN_CMD="${KEN_CMD} --rpcvhosts ${RPC_VHOSTS}"
KEN_CMD="${KEN_CMD} --rpccorsdomain ${RPC_CORSDOMAIN}"

# WebSocket configuration
KEN_CMD="${KEN_CMD} --ws --wsport ${WS_PORT}"
KEN_CMD="${KEN_CMD} --wsaddr ${WS_ADDR}"
KEN_CMD="${KEN_CMD} --wsapi ${WS_API}"
KEN_CMD="${KEN_CMD} --wsorigins ${WS_ORIGINS}"

# Metrics (Prometheus)
KEN_CMD="${KEN_CMD} --metrics --prometheus"

# Logging
KEN_CMD="${KEN_CMD} --verbosity 3"

# Extra flags
if [ -n "${EXTRA_FLAGS}" ]; then
    KEN_CMD="${KEN_CMD} ${EXTRA_FLAGS}"
fi

echo "==> Starting Kaia Endpoint Node..."
echo "==> Command: ${KEN_CMD}"
echo "=================================================="

# Execute ken
exec ${KEN_CMD}
