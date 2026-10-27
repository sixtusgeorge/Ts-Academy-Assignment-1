#!/usr/bin/env bash
set -uo pipefail

LOG_DIR="logs"
LOG_FILE="$LOG_DIR/network-check.log"
mkdir -p "$LOG_DIR"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ $# -lt 1 ]; then
    echo "Error: Hostname or IP argument is missing." >&2
    echo "Usage: $0 <hostname-or-ip> [port]" >&2
    exit 2
fi

HOST="$1"
PORT="${2:-}"

log_message "Starting network check for host: '$HOST'${PORT:+ with port: $PORT}"

echo "=== Network Interfaces ==="
if command -v ip &> /dev/null; then
    ip -brief addr show 2>/dev/null || ip addr show
else
    ifconfig -a 2>/dev/null || echo "Network interface info not available"
fi
echo ""

echo "=== Host Resolution & Connectivity ==="
RESOLVED_IP=""
if command -v getent &> /dev/null; then
    RESOLVED_IP=$(getent hosts "$HOST" | awk '{print $1}' | head -n 1)
elif command -v host &> /dev/null; then
    RESOLVED_IP=$(host "$HOST" 2>/dev/null | grep "has address" | head -n 1 | awk '{print $4}')
elif command -v nslookup &> /dev/null; then
    RESOLVED_IP=$(nslookup "$HOST" 2>/dev/null | awk '/^Address: / { print $2 }' | tail -n 1)
fi

if [ -z "$RESOLVED_IP" ]; then
    RESOLVED_IP=$(ping -c 1 -W 2 "$HOST" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)
fi

if [ -n "$RESOLVED_IP" ]; then
    echo "Target Host: $HOST"
    echo "Resolved Address: $RESOLVED_IP"
    log_message "Successfully resolved $HOST to $RESOLVED_IP"
else
    echo "Error: Could not resolve host '$HOST'." >&2
    log_message "Error: Failed to resolve host '$HOST'"
    exit 1
fi

echo "Performing ping connectivity check..."
if ping -c 2 -W 3 "$HOST" &> /dev/null; then
    echo "Connectivity check: SUCCESS (Host is reachable via ICMP)"
    log_message "ICMP ping check to $HOST succeeded"
else
    echo "Connectivity check: WARNING (Host did not respond to ICMP ping, but may still be reachable)"
    log_message "ICMP ping check to $HOST failed or timed out"
fi

if [ -n "$PORT" ]; then
    echo ""
    echo "=== TCP Port Check ==="
    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        echo "Error: Port must be an integer between 1 and 65535." >&2
        log_message "Error: Invalid port number provided: $PORT"
        exit 2
    fi

    echo "Checking TCP connectivity to $HOST on port $PORT..."
    PORT_SUCCESS=false

    if command -v nc &> /dev/null; then
        if nc -z -w 3 "$HOST" "$PORT" &> /dev/null; then
            PORT_SUCCESS=true
        fi
    elif command -v timeout &> /dev/null; then
        if timeout 3 bash -c "cat < /dev/tcp/$HOST/$PORT" &> /dev/null; then
            PORT_SUCCESS=true
        fi
    fi

    if [ "$PORT_SUCCESS" = true ]; then
        echo "TCP Port $PORT on $HOST: OPEN"
        log_message "TCP connectivity check to $HOST:$PORT succeeded (OPEN)"
    else
        echo "TCP Port $PORT on $HOST: CLOSED or UNREACHABLE"
        log_message "TCP connectivity check to $HOST:$PORT failed (CLOSED/UNREACHABLE)"
        exit 1
    fi
fi

log_message "network-check.sh completed successfully for $HOST"
exit 0
