#!/bin/bash

set -e

DURATION="${1:-60}"
MEMORY_MB="${2:-256}"

echo "=========================================="
echo " Pyneta Memory Stress Demo"
echo "=========================================="
echo "Duration   : ${DURATION} seconds"
echo "Memory     : ${MEMORY_MB} MB"
echo "=========================================="

if ! command -v stress >/dev/null 2>&1; then
    echo "[INFO] stress command not found."

    if command -v dnf >/dev/null 2>&1; then
        echo "[INFO] Installing stress..."
        sudo dnf install -y stress
    elif command -v apt-get >/dev/null 2>&1; then
        echo "[INFO] Installing stress..."
        sudo apt-get update
        sudo apt-get install -y stress
    else
        echo "[ERROR] Unsupported package manager."
        exit 1
    fi
fi

echo
echo "[INFO] Current memory:"
free -h

echo
echo "[INFO] Starting memory load..."

stress \
    --vm 1 \
    --vm-bytes "${MEMORY_MB}M" \
    --vm-keep \
    --timeout "${DURATION}s"

echo
echo "[INFO] Memory test completed."

echo
echo "[INFO] Current memory after test:"
free -h

echo
echo "[INFO] Demo completed."