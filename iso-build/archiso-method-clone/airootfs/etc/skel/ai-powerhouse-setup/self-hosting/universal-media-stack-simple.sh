#!/bin/bash

# Simplified Universal Garuda Media Stack for Live ISO/Chroot
# Uses host networking and minimal container features to work in constrained environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="garuda-media-stack"
DATA_DIR="/media"
CONFIG_DIR="/home/lou/.config"

# Detect host IP
HOST_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')

echo -e "${BLUE}🚀 Simplified Universal Garuda Media Stack${NC}"
echo -e "${BLUE}==========================================${NC}"
echo -e "Host IP: ${GREEN}${HOST_IP}${NC}"
echo -e "Data Directory: ${GREEN}${DATA_DIR}${NC}"
echo -e "${YELLOW}Note: Running in simplified mode for live ISO/chroot${NC}"
echo ""

# Suppress Podman warnings
export PODMAN_IGNORE_CGROUPSV1_WARNING=1

# Create directories
echo -e "${YELLOW}📁 Creating directories...${NC}"
sudo mkdir -p ${DATA_DIR}/{movies,tv,music,books,downloads,torrents,completed}
sudo mkdir -p ${CONFIG_DIR}/{radarr,sonarr,lidarr,jackett,jellyfin,qbittorrent}
sudo chown -R $(whoami):$(whoami) ${DATA_DIR} ${CONFIG_DIR} 2>/dev/null || true

# Stop and remove existing containers
echo -e "${YELLOW}🛑 Cleaning up existing containers...${NC}"
podman stop ${STACK_NAME}-qbittorrent ${STACK_NAME}-jellyfin ${STACK_NAME}-radarr ${STACK_NAME}-sonarr ${STACK_NAME}-lidarr ${STACK_NAME}-jackett ${STACK_NAME}-jellyseerr 2>/dev/null || true
podman rm ${STACK_NAME}-qbittorrent ${STACK_NAME}-jellyfin ${STACK_NAME}-radarr ${STACK_NAME}-sonarr ${STACK_NAME}-lidarr ${STACK_NAME}-jackett ${STACK_NAME}-jellyseerr 2>/dev/null || true

# Function to start a service with simplified options
start_service() {
    local service_name=$1
    local image=$2
    local port=$3
    local config_dir=$4
    local additional_volumes=$5
    local additional_env=$6
    
    echo -e "${YELLOW}Starting ${service_name}...${NC}"
    
    podman run -d \
        --name ${STACK_NAME}-${service_name,,} \
        --net=host \
        --privileged \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ=America/New_York \
        ${additional_env} \
        -v ${CONFIG_DIR}/${config_dir}:/config \
        ${additional_volumes} \
        --restart=no \
        ${image} || echo -e "${RED}Failed to start ${service_name}, continuing...${NC}"
}

# Start qBittorrent
start_service "qBittorrent" "lscr.io/linuxserver/qbittorrent:latest" "5080" "qbittorrent" \
    "-v ${DATA_DIR}/downloads:/downloads -v ${DATA_DIR}/completed:/completed" \
    "-e WEBUI_PORT=8080"

# Start Jellyfin
start_service "Jellyfin" "lscr.io/linuxserver/jellyfin:latest" "8096" "jellyfin" \
    "-v ${DATA_DIR}/movies:/data/movies -v ${DATA_DIR}/tv:/data/tvshows -v ${DATA_DIR}/music:/data/music"

# Start Jackett
start_service "Jackett" "lscr.io/linuxserver/jackett:latest" "9117" "jackett" \
    "-v ${DATA_DIR}/downloads:/downloads"

# Start Radarr
start_service "Radarr" "lscr.io/linuxserver/radarr:latest" "7878" "radarr" \
    "-v ${DATA_DIR}/movies:/movies -v ${DATA_DIR}/downloads:/downloads"

# Start Sonarr
start_service "Sonarr" "lscr.io/linuxserver/sonarr:latest" "8989" "sonarr" \
    "-v ${DATA_DIR}/tv:/tv -v ${DATA_DIR}/downloads:/downloads"

# Start Lidarr
start_service "Lidarr" "lscr.io/linuxserver/lidarr:latest" "8686" "lidarr" \
    "-v ${DATA_DIR}/music:/music -v ${DATA_DIR}/downloads:/downloads"

# Start Jellyseerr
start_service "Jellyseerr" "fallenbagel/jellyseerr:latest" "5055" "jellyseerr" \
    "-v ${CONFIG_DIR}/jellyseerr:/app/config"

# Wait for services to start
echo -e "${YELLOW}⏳ Waiting for services to initialize...${NC}"
sleep 30

# Check service status
echo ""
echo -e "${GREEN}✅ SIMPLIFIED MEDIA STACK STATUS${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Display service URLs
services=(
    "qBittorrent:5080"
    "Jellyfin:8096"
    "Radarr:7878"
    "Sonarr:8989"
    "Lidarr:8686"
    "Jackett:9117"
    "Jellyseerr:5055"
)

for service_info in "${services[@]}"; do
    IFS=':' read -r name port <<< "$service_info"
    url="http://${HOST_IP}:${port}"
    
    # Simple port check
    if ss -tuln | grep -q ":${port} "; then
        status="${GREEN}✅ ONLINE${NC}"
    else
        status="${YELLOW}⏳ STARTING${NC}"
    fi
    
    printf "%-15s %s %s\\n" "$name:" "$status" "$url"
done

echo ""
echo -e "${BLUE}🎉 Access your media stack at the URLs above!${NC}"
echo -e "${YELLOW}Note: Services may take a few minutes to fully initialize${NC}"
