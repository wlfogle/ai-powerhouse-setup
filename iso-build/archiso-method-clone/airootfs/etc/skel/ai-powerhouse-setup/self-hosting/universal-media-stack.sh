#!/bin/bash

# Universal Garuda Media Stack - Runs ANYWHERE
# Works on live ISO, main system, any Linux environment
# No dependencies on chroot, systemd, or specific OS setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="garuda-media-stack"
NETWORK_NAME="${STACK_NAME}-network"
DATA_DIR="/media"
CONFIG_DIR="/home/lou/.config"

# Detect host IP
HOST_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')

echo -e "${BLUE}🚀 Universal Garuda Media Stack${NC}"
echo -e "${BLUE}================================${NC}"
echo -e "Host IP: ${GREEN}${HOST_IP}${NC}"
echo -e "Data Directory: ${GREEN}${DATA_DIR}${NC}"
echo ""

# Check if podman is installed
if ! command -v podman &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Podman...${NC}"
    if command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm podman podman-compose
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y podman podman-compose
    else
        echo -e "${RED}❌ Cannot install Podman automatically. Please install manually.${NC}"
        exit 1
    fi
fi

# Create network
echo -e "${YELLOW}🌐 Creating media network...${NC}"
podman network create ${NETWORK_NAME} 2>/dev/null || true

# Create directories
echo -e "${YELLOW}📁 Creating directories...${NC}"
sudo mkdir -p ${DATA_DIR}/{movies,tv,music,books,downloads,torrents,completed}
sudo mkdir -p ${CONFIG_DIR}/{radarr,sonarr,lidarr,jackett,jellyfin,qbittorrent}
sudo chown -R $(whoami):$(whoami) ${DATA_DIR} ${CONFIG_DIR} 2>/dev/null || true

# Stop and remove existing containers
echo -e "${YELLOW}🛑 Cleaning up existing containers...${NC}"
podman stop ${STACK_NAME}-qbittorrent ${STACK_NAME}-jellyfin ${STACK_NAME}-radarr ${STACK_NAME}-sonarr ${STACK_NAME}-lidarr ${STACK_NAME}-jackett ${STACK_NAME}-jellyseerr 2>/dev/null || true
podman rm ${STACK_NAME}-qbittorrent ${STACK_NAME}-jellyfin ${STACK_NAME}-radarr ${STACK_NAME}-sonarr ${STACK_NAME}-lidarr ${STACK_NAME}-jackett ${STACK_NAME}-jellyseerr 2>/dev/null || true

# Start qBittorrent
echo -e "${YELLOW}⬇️ Starting qBittorrent...${NC}"
podman run -d \
  --name ${STACK_NAME}-qbittorrent \
  --network ${NETWORK_NAME} \
  -p 5080:8080 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -e WEBUI_PORT=8080 \
  -v ${CONFIG_DIR}/qbittorrent:/config \
  -v ${DATA_DIR}/downloads:/downloads \
  -v ${DATA_DIR}/completed:/completed \
  --restart unless-stopped \
  lscr.io/linuxserver/qbittorrent:latest

# Start Jellyfin
echo -e "${YELLOW}🎬 Starting Jellyfin...${NC}"
podman run -d \
  --name ${STACK_NAME}-jellyfin \
  --network ${NETWORK_NAME} \
  -p 8096:8096 \
  -p 8920:8920 \
  -p 7359:7359/udp \
  -p 1900:1900/udp \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -v ${CONFIG_DIR}/jellyfin:/config \
  -v ${DATA_DIR}/movies:/data/movies \
  -v ${DATA_DIR}/tv:/data/tvshows \
  -v ${DATA_DIR}/music:/data/music \
  --restart unless-stopped \
  lscr.io/linuxserver/jellyfin:latest

# Start Jackett
echo -e "${YELLOW}🔍 Starting Jackett...${NC}"
podman run -d \
  --name ${STACK_NAME}-jackett \
  --network ${NETWORK_NAME} \
  -p 9117:9117 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -v ${CONFIG_DIR}/jackett:/config \
  -v ${DATA_DIR}/downloads:/downloads \
  --restart unless-stopped \
  lscr.io/linuxserver/jackett:latest

# Start Radarr
echo -e "${YELLOW}🎭 Starting Radarr...${NC}"
podman run -d \
  --name ${STACK_NAME}-radarr \
  --network ${NETWORK_NAME} \
  -p 7878:7878 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -v ${CONFIG_DIR}/radarr:/config \
  -v ${DATA_DIR}/movies:/movies \
  -v ${DATA_DIR}/downloads:/downloads \
  --restart unless-stopped \
  lscr.io/linuxserver/radarr:latest

# Start Sonarr
echo -e "${YELLOW}📺 Starting Sonarr...${NC}"
podman run -d \
  --name ${STACK_NAME}-sonarr \
  --network ${NETWORK_NAME} \
  -p 8989:8989 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -v ${CONFIG_DIR}/sonarr:/config \
  -v ${DATA_DIR}/tv:/tv \
  -v ${DATA_DIR}/downloads:/downloads \
  --restart unless-stopped \
  lscr.io/linuxserver/sonarr:latest

# Start Lidarr
echo -e "${YELLOW}🎵 Starting Lidarr...${NC}"
podman run -d \
  --name ${STACK_NAME}-lidarr \
  --network ${NETWORK_NAME} \
  -p 8686:8686 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -v ${CONFIG_DIR}/lidarr:/config \
  -v ${DATA_DIR}/music:/music \
  -v ${DATA_DIR}/downloads:/downloads \
  --restart unless-stopped \
  lscr.io/linuxserver/lidarr:latest

# Start Jellyseerr
echo -e "${YELLOW}📋 Starting Jellyseerr...${NC}"
podman run -d \
  --name ${STACK_NAME}-jellyseerr \
  --network ${NETWORK_NAME} \
  -p 5055:5055 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -v ${CONFIG_DIR}/jellyseerr:/app/config \
  --restart unless-stopped \
  fallenbagel/jellyseerr:latest

# Wait for services to start
echo -e "${YELLOW}⏳ Waiting for services to initialize...${NC}"
sleep 30

# Check service status
echo ""
echo -e "${GREEN}✅ UNIVERSAL MEDIA STACK READY!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Test connectivity and display URLs
services=(
  "qBittorrent:5080:/api/v2/app/version"
  "Jellyfin:8096:/System/Info/Public"
  "Radarr:7878:/api/v3/system/status"
  "Sonarr:8989:/api/v3/system/status"
  "Lidarr:8686:/api/v1/system/status"
  "Jackett:9117:"
  "Jellyseerr:5055:"
)

for service_info in "${services[@]}"; do
    IFS=':' read -r name port endpoint <<< "$service_info"
    url="http://${HOST_IP}:${port}"
    
    if curl -s --connect-timeout 5 "${url}${endpoint}" > /dev/null 2>&1; then
        status="${GREEN}✅ ONLINE${NC}"
    else
        status="${YELLOW}⏳ STARTING${NC}"
    fi
    
    printf "%-15s %s %s\n" "$name:" "$status" "$url"
done

echo ""
echo -e "${BLUE}🔧 Default Credentials:${NC}"
echo -e "qBittorrent: ${GREEN}admin / adminadmin${NC}"
echo ""
echo -e "${BLUE}💡 Quick Setup:${NC}"
echo -e "1. Configure qBittorrent download client in *arr apps using:"
echo -e "   Host: ${GREEN}${STACK_NAME}-qbittorrent${NC} Port: ${GREEN}8080${NC}"
echo -e "2. Configure Jackett indexers and copy API key to *arr apps"
echo -e "3. Add root folders: /movies, /tv, /music"
echo ""
echo -e "${GREEN}🎉 Your universal media stack is running!${NC}"
