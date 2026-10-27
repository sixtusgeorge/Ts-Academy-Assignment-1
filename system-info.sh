#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="logs"
LOG_FILE="$LOG_DIR/system-info.log"
mkdir -p "$LOG_DIR"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "Executing system-info.sh"

echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Current User: $(whoami)"
echo "Date/Time: $(date)"

if [ -f /etc/os-release ]; then
    echo "Operating System: $(. /etc/os-release && echo "${PRETTY_NAME:-$NAME}")"
else
    echo "Operating System: $(uname -s)"
fi

echo "Kernel Version: $(uname -r)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"

if command -v lscpu &> /dev/null; then
    echo "CPU Information: $(lscpu | grep 'Model name' | sed 's/Model name:[[:space:]]*//' | head -n 1)"
elif [ -f /proc/cpuinfo ]; then
    echo "CPU Information: $(grep 'model name' /proc/cpuinfo | head -n 1 | cut -d: -f2 | xargs)"
else
    echo "CPU Information: $(uname -m)"
fi

if command -v free &> /dev/null; then
    echo "Memory Information: $(free -h | grep 'Mem:' || true)"
elif [ -f /proc/meminfo ]; then
    echo "Memory Information: Total: $(grep 'MemTotal' /proc/meminfo | awk '{print $2 $3}')"
else
    echo "Memory Information: Not available"
fi

echo "Current Working Directory: $(pwd)"
log_message "system-info.sh completed successfully"
