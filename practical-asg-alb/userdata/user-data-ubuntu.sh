#!/bin/bash

###############################################################################
# Pyneta AWS EC2 + ASG + ALB Demo
# Ubuntu User Data
###############################################################################

set -Eeuo pipefail


###############################################################################
# Configuration
###############################################################################

APP_NAME="pyneta-app"

REPO_URL="https://github.com/Ajaydiwakar/aws-ec2-asg-alb-demo.git"

APP_DIR="/opt/pyneta-app"

VENV_DIR="${APP_DIR}/venv"

SERVICE_NAME="pyneta-app.service"

SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"

ENV_DIR="/etc/pyneta-app"

ENV_FILE="${ENV_DIR}/pyneta-app.env"

LOG_DIR="/var/log/pyneta-app"

APP_HOST="0.0.0.0"

APP_PORT="6100"

APP_USER="ubuntu"

APP_GROUP="ubuntu"

BOOTSTRAP_LOG="/var/log/pyneta-user-data.log"


###############################################################################
# Logging
###############################################################################

exec > >(tee -a "${BOOTSTRAP_LOG}" | logger -t pyneta-user-data) 2>&1

echo
echo "=============================================================="
echo " Pyneta EC2 Bootstrap - Ubuntu"
echo "=============================================================="
echo "Started: $(date)"
echo


###############################################################################
# 1. Install packages
###############################################################################

echo "[1/10] Installing required packages..."

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl


###############################################################################
# 2. Create directories
###############################################################################

echo "[2/10] Creating directories..."

mkdir -p "${APP_DIR}"

mkdir -p "${ENV_DIR}"

mkdir -p "${LOG_DIR}"


###############################################################################
# 3. Clone repository
###############################################################################

echo "[3/10] Cloning application from GitHub..."

if [ -d "${APP_DIR}/.git" ]; then

    cd "${APP_DIR}"

    git fetch --all

    git reset --hard origin/main

else

    rm -rf "${APP_DIR}"

    git clone "${REPO_URL}" "${APP_DIR}"

fi


###############################################################################
# 4. Validate application
###############################################################################

echo "[4/10] Validating application files..."

if [ ! -f "${APP_DIR}/app.py" ]; then

    echo "ERROR: app.py not found."

    exit 1

fi


if [ ! -f "${APP_DIR}/requirements.txt" ]; then

    echo "ERROR: requirements.txt not found."

    exit 1

fi


###############################################################################
# 5. Create virtual environment
###############################################################################

echo "[5/10] Creating Python virtual environment..."

if [ ! -d "${VENV_DIR}" ]; then

    python3 -m venv "${VENV_DIR}"

fi


###############################################################################
# 6. Install dependencies
###############################################################################

echo "[6/10] Installing Python dependencies..."

"${VENV_DIR}/bin/python" -m pip install --upgrade pip

"${VENV_DIR}/bin/pip" install \
    -r "${APP_DIR}/requirements.txt"


###############################################################################
# 7. Ownership
###############################################################################

echo "[7/10] Setting ownership..."

chown -R "${APP_USER}:${APP_GROUP}" "${APP_DIR}"

chown -R "${APP_USER}:${APP_GROUP}" "${LOG_DIR}"


###############################################################################
# 8. Environment file
###############################################################################

echo "[8/10] Creating environment file..."

cat > "${ENV_FILE}" <<EOF
APP_NAME=${APP_NAME}
HOST=${APP_HOST}
PORT=${APP_PORT}
EOF

chmod 640 "${ENV_FILE}"

chown root:"${APP_GROUP}" "${ENV_FILE}"


###############################################################################
# 9. Systemd service
###############################################################################

echo "[9/10] Creating systemd service..."

cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Pyneta Flask Application
Documentation=AWS EC2 ASG ALB Demonstration Application

Wants=network-online.target
After=network-online.target

[Service]
Type=simple

User=${APP_USER}
Group=${APP_GROUP}

WorkingDirectory=${APP_DIR}

EnvironmentFile=${ENV_FILE}

ExecStart=${VENV_DIR}/bin/python ${APP_DIR}/app.py

Restart=always
RestartSec=5

TimeoutStartSec=30
TimeoutStopSec=30

KillSignal=SIGTERM

StandardOutput=journal
StandardError=journal

SyslogIdentifier=${APP_NAME}

[Install]
WantedBy=multi-user.target
EOF


###############################################################################
# 10. Start service
###############################################################################

echo "[10/10] Starting systemd service..."

systemctl daemon-reload

systemctl enable "${SERVICE_NAME}"

systemctl restart "${SERVICE_NAME}"


###############################################################################
# Wait
###############################################################################

sleep 5


###############################################################################
# Verify service
###############################################################################

if systemctl is-active --quiet "${SERVICE_NAME}"; then

    echo "SUCCESS: systemd service is active."

else

    echo "ERROR: systemd service failed."

    systemctl status \
        "${SERVICE_NAME}" \
        --no-pager || true

    journalctl \
        -u "${SERVICE_NAME}" \
        -n 100 \
        --no-pager || true

    exit 1

fi


###############################################################################
# Verify port
###############################################################################

if ss -lnt | grep -q ":${APP_PORT} "; then

    echo "SUCCESS: Port ${APP_PORT} is listening."

else

    echo "ERROR: Port ${APP_PORT} is not listening."

    ss -lnt || true

    exit 1

fi


###############################################################################
# Verify health
###############################################################################

HEALTH_OK="false"

for attempt in {1..12}; do

    echo "Health check attempt ${attempt}/12..."

    if curl \
        --fail \
        --silent \
        --show-error \
        --max-time 5 \
        "http://127.0.0.1:${APP_PORT}/health"; then

        HEALTH_OK="true"

        echo
        echo "SUCCESS: Health check passed."

        break

    fi

    sleep 2

done


if [ "${HEALTH_OK}" != "true" ]; then

    echo "ERROR: Health check failed."

    systemctl status \
        "${SERVICE_NAME}" \
        --no-pager || true

    journalctl \
        -u "${SERVICE_NAME}" \
        -n 100 \
        --no-pager || true

    exit 1

fi


###############################################################################
# Complete
###############################################################################

echo
echo "=============================================================="
echo " Pyneta Application Deployment Completed"
echo "=============================================================="

echo "Application : ${APP_DIR}"
echo "Port        : ${APP_PORT}"
echo "Service     : ${SERVICE_NAME}"

echo
echo "Enabled:"

systemctl is-enabled "${SERVICE_NAME}"

echo
echo "Active:"

systemctl is-active "${SERVICE_NAME}"

echo
echo "Completed: $(date)"

echo "=============================================================="