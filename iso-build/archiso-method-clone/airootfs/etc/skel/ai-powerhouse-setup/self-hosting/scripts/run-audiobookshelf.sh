#!/bin/bash

# Run Audiobookshelf in Podman container
# This script runs Audiobookshelf using the official Docker image

CONTAINER_NAME="audiobookshelf"
CONFIG_DIR="/media/config/audiobookshelf"
AUDIOBOOKS_DIR="/media/audiobooks"
BOOKS_DIR="/media/books"

# Create directories if they don't exist
mkdir -p "$CONFIG_DIR"
mkdir -p "$AUDIOBOOKS_DIR"
mkdir -p "$BOOKS_DIR"

# Stop and remove existing container if it exists
podman stop "$CONTAINER_NAME" 2>/dev/null
podman rm "$CONTAINER_NAME" 2>/dev/null

# Run Audiobookshelf container
podman run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p 13378:80 \
  -v "$AUDIOBOOKS_DIR":/audiobooks \
  -v "$BOOKS_DIR":/books \
  -v "$CONFIG_DIR":/config \
  -v "$CONFIG_DIR/metadata":/metadata \
  -e TZ="America/New_York" \
  ghcr.io/advplyr/audiobookshelf:latest

echo "Audiobookshelf started in container. Access at http://localhost:13378"
echo "Config directory: $CONFIG_DIR"
echo "Audiobooks directory: $AUDIOBOOKS_DIR"
echo "Books directory: $BOOKS_DIR"
echo "Container name: $CONTAINER_NAME"
echo ""
echo "To check logs: podman logs $CONTAINER_NAME"
echo "To stop: podman stop $CONTAINER_NAME"
