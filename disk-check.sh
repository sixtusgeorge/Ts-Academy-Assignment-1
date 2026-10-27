#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="logs"
LOG_FILE="$LOG_DIR/disk-check.log"
mkdir -p "$LOG_DIR"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ $# -lt 1 ]; then
    echo "Error: Threshold argument is missing." >&2
    echo "Usage: $0 <threshold> [path]" >&2
    exit 2
fi

THRESHOLD="$1"
TARGET_PATH="${2:-/}"

# Validate threshold is an integer from 1 to 100
if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -lt 1 ] || [ "$THRESHOLD" -gt 100 ]; then
    echo "Error: Threshold must be an integer between 1 and 100." >&2
    exit 2
fi

if [ ! -e "$TARGET_PATH" ]; then
    echo "Error: Path '$TARGET_PATH' does not exist." >&2
    exit 2
fi

log_message "Checking disk usage for path '$TARGET_PATH' with threshold ${THRESHOLD}%"

# Extract integer usage percentage
USAGE=$(df "$TARGET_PATH" | tail -n 1 | awk '{print $5}' | tr -d '%')

if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
    echo "Error: Failed to parse disk usage." >&2
    log_message "Error: Failed to parse disk usage for $TARGET_PATH"
    exit 2
fi

echo "Path: $TARGET_PATH"
echo "Current Disk Usage: ${USAGE}%"
echo "Threshold: ${THRESHOLD}%"

log_message "Disk usage for $TARGET_PATH is ${USAGE}% (Threshold: ${THRESHOLD}%)"

if [ "$USAGE" -ge "$THRESHOLD" ]; then
    echo "WARNING: Disk usage has reached or exceeded the threshold!"
    log_message "WARNING: Disk usage ${USAGE}% reached or exceeded threshold ${THRESHOLD}%"
    exit 1
else
    echo "Disk usage is below the threshold."
    log_message "Disk usage is within safe limits."
    exit 0
fi
