```bash
#!/bin/bash

###############################################################################
# Pyneta AWS Demo - Combined CPU + Memory Stress Test
#
# Purpose:
#   Controlled CPU + memory load generator for AWS EC2 / Auto Scaling demos.
#
# Supported:
#   - Amazon Linux 2023
#   - Ubuntu
#
# Usage:
#   ./combined-stress.sh
#   ./combined-stress.sh <duration_seconds>
#   ./combined-stress.sh <duration_seconds> <cpu_workers> <memory_mb>
#
# Examples:
#   ./combined-stress.sh
#       Run a 60-second test using detected CPU count and safe memory amount.
#
#   ./combined-stress.sh 120 2 512
#       Run for 120 seconds with 2 CPU workers and 512 MB memory.
#
#   ./combined-stress.sh 300 4 1024
#       Run for 5 minutes with 4 CPU workers and 1 GB memory.
#
# IMPORTANT:
#   This script is intended for controlled classroom demonstrations.
#   Do not intentionally consume all available system memory.
###############################################################################

set -Eeuo pipefail

###############################################################################
# Configuration
###############################################################################

DEFAULT_DURATION=60

# Number of logical CPUs available to the instance.
DEFAULT_THREADS="$(nproc)"

# Detect total system memory in MB.
TOTAL_MEM_KB="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
TOTAL_MEM_MB="$((TOTAL_MEM_KB / 1024))"

# Use approximately 50% of RAM by default.
# This leaves reasonable headroom for the OS, application, CloudWatch Agent,
# SSH session, etc.
DEFAULT_MEM_MB="$((TOTAL_MEM_MB * 50 / 100))"

# Keep a reasonable minimum for the demo.
if [ "$DEFAULT_MEM_MB" -lt 128 ]; then
    DEFAULT_MEM_MB=128
fi

###############################################################################
# Arguments
###############################################################################

DURATION="${1:-$DEFAULT_DURATION}"
THREADS="${2:-$DEFAULT_THREADS}"
MEM_MB="${3:-$DEFAULT_MEM_MB}"

###############################################################################
# Colors / output helpers
###############################################################################

info() {
    echo "[INFO] $*"
}

warn() {
    echo "[WARN] $*" >&2
}

error() {
    echo "[ERROR] $*" >&2
}

###############################################################################
# Cleanup
###############################################################################

STRESS_PID=""

cleanup() {
    echo
    info "Stopping stress test..."

    if [ -n "${STRESS_PID}" ] && kill -0 "${STRESS_PID}" 2>/dev/null; then
        kill "${STRESS_PID}" 2>/dev/null || true
        wait "${STRESS_PID}" 2>/dev/null || true
    fi

    info "Stress test stopped."

    echo
    echo "Current memory:"
    free -h

    echo
    info "Demo completed."
}

trap cleanup INT TERM EXIT

###############################################################################
# Validate arguments
###############################################################################

if ! [[ "$DURATION" =~ ^[0-9]+$ ]]; then
    error "Duration must be a positive integer."
    exit 1
fi

if ! [[ "$THREADS" =~ ^[0-9]+$ ]] || [ "$THREADS" -lt 1 ]; then
    error "CPU workers must be a positive integer."
    exit 1
fi

if ! [[ "$MEM_MB" =~ ^[0-9]+$ ]] || [ "$MEM_MB" -lt 1 ]; then
    error "Memory amount must be a positive integer."
    exit 1
fi

###############################################################################
# Prevent accidental excessive memory allocation
###############################################################################

# Maximum recommended allocation: 75% of detected RAM.
MAX_MEM_MB="$((TOTAL_MEM_MB * 75 / 100))"

if [ "$MAX_MEM_MB" -lt 128 ]; then
    MAX_MEM_MB=128
fi

if [ "$MEM_MB" -gt "$MAX_MEM_MB" ]; then
    warn "Requested memory: ${MEM_MB} MB"
    warn "Detected RAM:      ${TOTAL_MEM_MB} MB"
    warn "Maximum allowed by this demo script: ${MAX_MEM_MB} MB"

    error "Requested memory is too high."
    error "Reduce the memory argument and try again."

    exit 1
fi

###############################################################################
# Header
###############################################################################

echo
echo "============================================================"
echo "       Pyneta AWS EC2 Combined Stress Test"
echo "============================================================"
echo
echo "Operating System : $(. /etc/os-release && echo "${PRETTY_NAME:-Unknown}")"
echo "Hostname         : $(hostname)"
echo "CPU cores        : $(nproc)"
echo "Total memory     : ${TOTAL_MEM_MB} MB"
echo
echo "Stress duration  : ${DURATION} seconds"
echo "CPU workers      : ${THREADS}"
echo "Memory allocation: ${MEM_MB} MB"
echo
echo "============================================================"
echo

###############################################################################
# Display memory before test
###############################################################################

info "Memory before stress test:"
free -h

echo

###############################################################################
# Install stress if necessary
###############################################################################

if ! command -v stress >/dev/null 2>&1; then

    info "The 'stress' command was not found."
    info "Installing stress package..."

    if command -v dnf >/dev/null 2>&1; then

        # Amazon Linux 2023
        sudo dnf install -y stress

    elif command -v apt-get >/dev/null 2>&1; then

        # Ubuntu / Debian
        sudo apt-get update
        sudo apt-get install -y stress

    else

        error "Unsupported operating system."
        error "Neither dnf nor apt-get was found."
        exit 1
    fi
fi

###############################################################################
# Verify installation
###############################################################################

if ! command -v stress >/dev/null 2>&1; then
    error "stress installation failed."
    exit 1
fi

info "stress version:"
stress --version || true

echo

###############################################################################
# Start stress test
###############################################################################

info "Starting CPU + memory stress..."
echo
echo "Monitor the instance from another terminal with:"
echo
echo "  top"
echo "  free -h"
echo "  uptime"
echo
echo "For AWS monitoring, check CloudWatch metrics."
echo
echo "Press Ctrl+C to stop the test early."
echo

###############################################################################
# Run stress
###############################################################################

stress \
    --cpu "$THREADS" \
    --vm 1 \
    --vm-bytes "${MEM_MB}M" \
    --vm-hang 0 \
    --timeout "${DURATION}s" &

STRESS_PID=$!

###############################################################################
# Wait for stress process
###############################################################################

wait "$STRESS_PID" || true

STRESS_PID=""

echo
info "Stress test duration completed."

###############################################################################
# Final memory status
###############################################################################

echo
info "Memory after stress test:"
free -h

echo
info "CPU load after stress test:"
uptime

echo
info "Combined CPU + memory stress test finished successfully."
```
