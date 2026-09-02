#!/bin/bash
set -e

# Manual startup option for EC2 or local testing.
# This script installs requirements and starts the app without systemd.

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$APP_DIR"

pip3 install -r requirements.txt

# Optional: custom log path
LOG_PATH="${1:-/var/log/asg_alb_app.log}"
LOG_DIR="$(dirname "$LOG_PATH")"
mkdir -p "$LOG_DIR"

nohup env HOST=0.0.0.0 PORT=6100 python3 app.py >> "$LOG_PATH" 2>&1 &

echo "App started in background."
echo "Log file: $LOG_PATH"
echo "To stop it manually: pkill -f 'python3 app.py'"
