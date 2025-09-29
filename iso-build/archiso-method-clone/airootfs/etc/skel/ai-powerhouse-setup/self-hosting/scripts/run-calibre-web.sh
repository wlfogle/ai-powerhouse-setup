#!/bin/bash

# Run Calibre-Web in Podman container
# This script runs Calibre-Web using the LinuxServer.io Docker image

CONTAINER_NAME="calibre-web"
CONFIG_DIR="/media/config/calibre-web"
BOOKS_DIR="/media/books"

# Create directories if they don't exist
mkdir -p "$CONFIG_DIR"
mkdir -p "$BOOKS_DIR"

# Stop and remove existing container if it exists
podman stop "$CONTAINER_NAME" 2>/dev/null
podman rm "$CONTAINER_NAME" 2>/dev/null

# Run Calibre-Web container
podman run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p 8083:8083 \
  -v "$CONFIG_DIR":/config \
  -v "$BOOKS_DIR":/books \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ="America/New_York" \
  -e DOCKER_MODS=linuxserver/mods:universal-calibre \
  lscr.io/linuxserver/calibre-web:latest

echo "Calibre-Web started in container. Access at http://localhost:8083"
echo "Config directory: $CONFIG_DIR"
echo "Books directory: $BOOKS_DIR" 
echo "Container name: $CONTAINER_NAME"
echo ""
echo "To check logs: podman logs $CONTAINER_NAME"
echo "To stop: podman stop $CONTAINER_NAME"
echo ""
echo "First setup: Point to your Calibre library at /books when prompted"
