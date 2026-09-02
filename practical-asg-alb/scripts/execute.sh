#!/bin/bash

set -euo pipefail


###############################################################################
# Pyneta manual execution helper
#
# IMPORTANT:
#   ASG/Launch Template deployment does NOT use this script.
#
#   Automated deployment uses:
#
#       User Data
#           ↓
#       systemd
#           ↓
#       app.py
###############################################################################


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${SCRIPT_DIR}"


HOST="${HOST:-0.0.0.0}"

PORT="${PORT:-6100}"

LOG_DIR="${SCRIPT_DIR}/logs"

LOG_FILE="${LOG_DIR}/pyneta-app.log"


mkdir -p "${LOG_DIR}"


echo "============================================================"
echo "Pyneta Execute Script"
echo "============================================================"


###############################################################################
# Check Python
###############################################################################

if ! command -v python3 >/dev/null 2>&1; then

    echo "ERROR: python3 is not installed."

    exit 1

fi


###############################################################################
# Virtual environment
###############################################################################

if [ ! -d "${SCRIPT_DIR}/venv" ]; then

    echo "Creating Python virtual environment..."

    python3 -m venv "${SCRIPT_DIR}/venv"

fi


###############################################################################
# Dependencies
###############################################################################

echo "Installing dependencies..."

"${SCRIPT_DIR}/venv/bin/pip" install \
    -r "${SCRIPT_DIR}/requirements.txt"


###############################################################################
# Check port
###############################################################################

if command -v ss >/dev/null 2>&1; then

    if ss -lnt | grep -q ":${PORT} "; then

        echo
        echo "WARNING: Port ${PORT} is already listening."

        echo "Application may already be running."

        exit 0

    fi

fi


###############################################################################
# Start application
###############################################################################

echo "Starting application..."

nohup \
    env HOST="${HOST}" PORT="${PORT}" \
    "${SCRIPT_DIR}/venv/bin/python" \
    "${SCRIPT_DIR}/app.py" \
    >> "${LOG_FILE}" 2>&1 &


PID=$!


echo
echo "Application started."

echo "PID: ${PID}"

echo "Host: ${HOST}"

echo "Port: ${PORT}"

echo "Log: ${LOG_FILE}"


###############################################################################
# Health check
###############################################################################

sleep 2


echo
echo "Health check:"

curl \
    --silent \
    --show-error \
    "http://127.0.0.1:${PORT}/health"

echo

echo
echo "Application is running."