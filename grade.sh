#!/usr/bin/env bash
set -euo pipefail

echo "=== Running Assignment 1 Grader ==="

# Check required files
REQUIRED_FILES=("system-info.sh" "disk-check.sh" "network-check.sh" "README.md" "logs/.gitkeep")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "FAIL: Required file missing: $file" >&2
        exit 1
    fi
    echo "PASS: Found $file"
done

# Check executable permissions
SCRIPTS=("system-info.sh" "disk-check.sh" "network-check.sh")
for script in "${SCRIPTS[@]}"; do
    if [ ! -x "$script" ]; then
        echo "FAIL: Script is not executable: $script" >&2
        exit 1
    fi
    echo "PASS: $script is executable"
    
    # Check Bash syntax
    if ! bash -n "$script"; then
        echo "FAIL: Syntax error in $script" >&2
        exit 1
    fi
    echo "PASS: $script syntax check passed"
done

# Test system-info.sh execution
echo "Testing system-info.sh..."
./system-info.sh > /dev/null

# Test disk-check.sh validation and execution
echo "Testing disk-check.sh..."
./disk-check.sh 50 > /dev/null
if ./disk-check.sh 150 2>/dev/null; then
    echo "FAIL: disk-check.sh should fail on invalid threshold" >&2
    exit 1
else
    echo "PASS: disk-check.sh correctly rejected invalid threshold"
fi

# Test network-check.sh validation
echo "Testing network-check.sh..."
if ./network-check.sh nonesuchhostxyz123.local 2>/dev/null; then
    echo "FAIL: network-check.sh should fail on invalid host" >&2
    exit 1
else
    echo "PASS: network-check.sh correctly handled invalid host"
fi

echo "=== ALL GRADER CHECKS PASSED SUCCESSFULLY ==="
