#!/bin/bash

###############################################################################
# Pyneta ASG CPU Demonstration
#
# Usage:
#
#   ./cpu-stress.sh
#
#   ./cpu-stress.sh 60
#
#   ./cpu-stress.sh 60 2
#
# Arguments:
#
#   $1 = duration in seconds
#   $2 = number of CPU workers
#
# Default:
#
#   duration = 60 seconds
#   workers  = number of available CPUs
###############################################################################

set -euo pipefail


DURATION="${1:-60}"

THREADS="${2:-$(nproc)}"


echo "============================================================"
echo "Pyneta CPU Load Demonstration"
echo "============================================================"

echo "Duration : ${DURATION} seconds"

echo "Threads  : ${THREADS}"

echo


###############################################################################
# Check stress utility
###############################################################################

if command -v stress >/dev/null 2>&1; then

    echo "stress command already installed."

else

    echo "stress command not found."

    echo "Installing stress..."


    if command -v dnf >/dev/null 2>&1; then

        sudo dnf install -y stress

    elif command -v apt-get >/dev/null 2>&1; then

        sudo apt-get update

        sudo apt-get install -y stress

    else

        echo "ERROR: Unsupported Linux distribution."

        exit 1

    fi

fi


###############################################################################
# Run controlled CPU test
###############################################################################

echo
echo "Starting CPU test..."

echo "Monitor CPU/ASG metrics while this runs."

echo


stress \
    --cpu "${THREADS}" \
    --timeout "${DURATION}s"


echo
echo "============================================================"

echo "CPU demonstration completed."

echo "============================================================"