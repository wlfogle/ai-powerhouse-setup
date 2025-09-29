#!/bin/bash

# Run Jellyseerr in Podman container
# This script runs Jellyseerr using the official Docker image

CONTAINER_NAME="jellyseerr"
CONFIG_DIR="/media/config/jellyseerr"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Stop and remove existing container if it exists
podman stop "$CONTAINER_NAME" 2>/dev/null
podman rm "$CONTAINER_NAME" 2>/dev/null

# Run Jellyseerr container
podman run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p 5055:5055 \
  -v "$CONFIG_DIR":/app/config \
  -v /media:/media \
  -e TZ="America/New_York" \
  -e PORT=5055 \
  -e HOST=0.0.0.0 \
  -e LOG_LEVEL=info \
  docker.io/fallenbagel/jellyseerr:latest

echo "Jellyseerr started in container. Access at http://localhost:5055"
echo "Config directory: $CONFIG_DIR"
echo "Container name: $CONTAINER_NAME"
echo ""
echo "To check logs: podman logs $CONTAINER_NAME"
echo "To stop: podman stop $CONTAINER_NAME"
