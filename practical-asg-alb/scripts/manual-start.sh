#!/bin/bash

set -euo pipefail


###############################################################################
# Pyneta manual application launcher
#
# This script is intended for manual testing only.
#
# Production/ASG deployment should use systemd.
###############################################################################


APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${APP_DIR}"


HOST="${HOST:-0.0.0.0}"

PORT="${PORT:-6100}"

LOG_DIR="${APP_DIR}/logs"

LOG_FILE="${LOG_DIR}/pyneta-app.log"


mkdir -p "${LOG_DIR}"


echo "============================================================"
echo "Pyneta Manual Start"
echo "============================================================"

echo "Application directory: ${APP_DIR}"

echo "Host: ${HOST}"

echo "Port: ${PORT}"

echo "Log file: ${LOG_FILE}"

echo


###############################################################################
# Python virtual environment
###############################################################################

if [ ! -d "${APP_DIR}/venv" ]; then

    echo "Creating virtual environment..."

    python3 -m venv "${APP_DIR}/venv"

fi


###############################################################################
# Dependencies
###############################################################################

echo "Installing dependencies..."

"${APP_DIR}/venv/bin/pip" install \
    -r "${APP_DIR}/requirements.txt"


###############################################################################
# Start
###############################################################################

echo "Starting Flask application..."

nohup \
    env HOST="${HOST}" PORT="${PORT}" \
    "${APP_DIR}/venv/bin/python" \
    "${APP_DIR}/app.py" \
    >> "${LOG_FILE}" 2>&1 &


PID=$!


echo
echo "Application started."

echo "PID: ${PID}"

echo "Log file: ${LOG_FILE}"

echo

echo "Health check:"

sleep 2

curl \
    --silent \
    --show-error \
    "http://127.0.0.1:${PORT}/health"

echo

echo
echo "============================================================"