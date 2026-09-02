#!/bin/bash

###############################################################################
# Pyneta AWS EC2 + ASG + ALB Demo
#
# Operating System:
#   Amazon Linux 2023
#
# Purpose:
#   Automatically bootstrap the Flask application on a fresh EC2 instance.
#
# Process:
#
#   EC2
#     |
#     +-- install packages
#     |
#     +-- clone GitHub repository
#     |
#     +-- create Python virtual environment
#     |
#     +-- install Python dependencies
#     |
#     +-- create environment file
#     |
#     +-- create systemd service
#     |
#     +-- enable systemd service
#     |
#     +-- start application
#     |
#     +-- test /health
#
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

APP_USER="ec2-user"

APP_GROUP="ec2-user"

BOOTSTRAP_LOG="/var/log/pyneta-user-data.log"


###############################################################################
# Logging
###############################################################################

exec > >(tee -a "${BOOTSTRAP_LOG}" | logger -t pyneta-user-data) 2>&1

echo
echo "=============================================================="
echo " Pyneta EC2 Bootstrap - Amazon Linux 2023"
echo "=============================================================="
echo "Started: $(date)"
echo


###############################################################################
# 1. Install operating system packages
###############################################################################

echo "[1/10] Installing required packages..."

dnf install -y \
    python3 \
    python3-pip \
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
# 3. Clone application
###############################################################################

echo "[3/10] Cloning application from GitHub..."

if [ -d "${APP_DIR}/.git" ]; then

    echo "Git repository already exists."

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

    echo "ERROR: app.py does not exist."

    exit 1

fi


if [ ! -f "${APP_DIR}/requirements.txt" ]; then

    echo "ERROR: requirements.txt does not exist."

    exit 1

fi


###############################################################################
# 5. Create Python virtual environment
###############################################################################

echo "[5/10] Creating Python virtual environment..."

if [ ! -d "${VENV_DIR}" ]; then

    python3 -m venv "${VENV_DIR}"

fi


###############################################################################
# 6. Install Python dependencies
###############################################################################

echo "[6/10] Installing Python dependencies..."

"${VENV_DIR}/bin/python" -m pip install --upgrade pip

"${VENV_DIR}/bin/pip" install \
    -r "${APP_DIR}/requirements.txt"


###############################################################################
# 7. Set ownership
###############################################################################

echo "[7/10] Setting application ownership..."

chown -R "${APP_USER}:${APP_GROUP}" "${APP_DIR}"

chown -R "${APP_USER}:${APP_GROUP}" "${LOG_DIR}"


###############################################################################
# 8. Create environment configuration
###############################################################################

echo "[8/10] Creating environment configuration..."

cat > "${ENV_FILE}" <<EOF
APP_NAME=${APP_NAME}
HOST=${APP_HOST}
PORT=${APP_PORT}
EOF


chmod 640 "${ENV_FILE}"

chown root:"${APP_GROUP}" "${ENV_FILE}"


###############################################################################
# 9. Create systemd service
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
# 10. Enable and start service
###############################################################################

echo "[10/10] Enabling and starting systemd service..."

systemctl daemon-reload

systemctl enable "${SERVICE_NAME}"

systemctl restart "${SERVICE_NAME}"


###############################################################################
# Wait for application
###############################################################################

echo
echo "Waiting for application to start..."

sleep 5


###############################################################################
# Verify systemd
###############################################################################

echo
echo "Checking systemd status..."

if systemctl is-active --quiet "${SERVICE_NAME}"; then

    echo "SUCCESS: ${SERVICE_NAME} is active."

else

    echo "ERROR: ${SERVICE_NAME} is NOT active."

    systemctl status "${SERVICE_NAME}" --no-pager || true

    echo
    echo "Recent application logs:"

    journalctl \
        -u "${SERVICE_NAME}" \
        -n 100 \
        --no-pager || true

    exit 1

fi


###############################################################################
# Verify application port
###############################################################################

echo
echo "Checking TCP port ${APP_PORT}..."

if ss -lnt | grep -q ":${APP_PORT} "; then

    echo "SUCCESS: Port ${APP_PORT} is listening."

else

    echo "ERROR: Port ${APP_PORT} is not listening."

    ss -lnt || true

    journalctl \
        -u "${SERVICE_NAME}" \
        -n 100 \
        --no-pager || true

    exit 1

fi


###############################################################################
# Verify health endpoint
###############################################################################

echo
echo "Checking application health endpoint..."

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
        echo "SUCCESS: Application health check passed."

        break

    fi

    sleep 2

done


if [ "${HEALTH_OK}" != "true" ]; then

    echo
    echo "ERROR: Application health check failed."

    echo
    echo "Systemd status:"

    systemctl status \
        "${SERVICE_NAME}" \
        --no-pager || true

    echo
    echo "Application logs:"

    journalctl \
        -u "${SERVICE_NAME}" \
        -n 100 \
        --no-pager || true

    echo
    echo "Listening ports:"

    ss -lntp || true

    exit 1

fi


###############################################################################
# Final status
###############################################################################

echo
echo "=============================================================="
echo " Pyneta Application Deployment Completed"
echo "=============================================================="

echo
echo "Application directory : ${APP_DIR}"
echo "Python environment    : ${VENV_DIR}"
echo "Application port      : ${APP_PORT}"
echo "Systemd service       : ${SERVICE_NAME}"
echo "Environment file      : ${ENV_FILE}"
echo "Bootstrap log         : ${BOOTSTRAP_LOG}"

echo
echo "Systemd enabled state:"

systemctl is-enabled "${SERVICE_NAME}"

echo
echo "Systemd active state:"

systemctl is-active "${SERVICE_NAME}"

echo
echo "Health endpoint:"

curl \
    --silent \
    "http://127.0.0.1:${APP_PORT}/health"

echo

echo
echo "Completed: $(date)"

echo "=============================================================="