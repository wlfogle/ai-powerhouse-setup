#!/bin/bash

# Run Pulsarr natively
# This script runs the pre-built Pulsarr application

PULSARR_DIR="/opt/pulsarr"
CONFIG_DIR="/media/config/pulsarr"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Check for existing process
if pgrep -f "node.*pulsarr.*app.js" > /dev/null; then
    echo "Stopping existing Pulsarr process..."
    pkill -f "node.*pulsarr.*app.js"
    sleep 2
fi

# Start Pulsarr
cd "$PULSARR_DIR"
echo "Starting Pulsarr..."

# Set up environment
export NODE_ENV=production
export PORT=3030
export HOST=0.0.0.0
export CONFIG_DIR="$CONFIG_DIR"

# Run in background
nohup node dist/app.js > "$CONFIG_DIR/pulsarr.log" 2>&1 &

echo "Pulsarr started. Access at http://localhost:3030"
echo "Config directory: $CONFIG_DIR"
echo "Log file: $CONFIG_DIR/pulsarr.log"
echo "Process ID: $!"
echo ""
echo "To check logs: tail -f $CONFIG_DIR/pulsarr.log"
echo "To stop: pkill -f 'node.*pulsarr.*app.js'"
