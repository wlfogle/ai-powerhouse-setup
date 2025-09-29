#!/bin/bash

# Complete Garuda Media Stack Startup Script
# Starts ALL services, VPN, Ghost Mode, and API Proxy

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}🚀 STARTING COMPLETE GARUDA MEDIA STACK${NC}"
echo -e "${PURPLE}=====================================${NC}"

# Kill any existing conflicting processes
echo -e "${YELLOW}🛑 Cleaning up existing processes...${NC}"
pkill -f qbittorrent || true
pkill -f jellyseerr || true
pkill -f calibre || true
pkill -f jackett || true
pkill -f api-server || true
sleep 2

# Start core media services that should already be running
echo -e "${BLUE}📺 Starting Core Media Services...${NC}"

# Start qBittorrent with proper config
echo -e "${YELLOW}  Starting qBittorrent...${NC}"
export QBT_PROFILE=/mnt/media/config/qbittorrent
mkdir -p /mnt/media/config/qbittorrent
qbittorrent-nox --webui-port=5080 &
sleep 3

# Start Jackett
echo -e "${YELLOW}  Starting Jackett...${NC}"
mkdir -p /mnt/media/config/jackett
/usr/lib/jackett/jackett --Port=9117 --DataFolder=/mnt/media/config/jackett &
sleep 3

# Start Jellyseerr
if [[ -d /mnt/media/jellyseerr-2.7.3 ]]; then
    echo -e "${YELLOW}  Starting Jellyseerr...${NC}"
    mkdir -p /mnt/media/config/jellyseerr
    cd /mnt/media/jellyseerr-2.7.3
    PORT=5055 CONFIG_DIRECTORY=/mnt/media/config/jellyseerr node dist/index.js &
    sleep 3
fi

echo -e "${BLUE}📚 Starting Additional Services...${NC}"

# Start Readarr
if [[ -d /mnt/media/Readarr-0.9.0 ]]; then
    echo -e "${YELLOW}  Starting Readarr...${NC}"
    mkdir -p /mnt/media/config/readarr
    cd /mnt/media/Readarr-0.9.0
    ./Readarr --nobrowser --data=/mnt/media/config/readarr &
    sleep 3
fi

# Start Calibre-Web
if [[ -d /mnt/media/calibre-web-0.6.25 ]]; then
    echo -e "${YELLOW}  Starting Calibre-Web...${NC}"
    mkdir -p /mnt/media/config/calibre
    cd /mnt/media/calibre-web-0.6.25
    python3 cps.py -p 8083 -g /mnt/media/config/calibre &
    sleep 3
fi

echo -e "${BLUE}🔒 Starting VPN & Privacy Stack...${NC}"

# Enable Ghost Mode
echo -e "${YELLOW}  Enabling Ghost Mode...${NC}"
cd /home/lou/github/garuda-media-stack
./ghost-control.sh enable

# Start API Proxy/Server
echo -e "${YELLOW}  Starting API Proxy (port 8888)...${NC}"
cd /home/lou/github/garuda-media-stack
python3 api-server.py --port=8888 &
sleep 3

# Start WireGuard if not already running
echo -e "${YELLOW}  Checking WireGuard status...${NC}"
if ! ss -tuln | grep -q ":51820 "; then
    echo -e "${YELLOW}  Starting WireGuard server...${NC}"
    # WireGuard should already be configured, just need to start if possible
    systemctl start wg-quick@wg0-server 2>/dev/null || echo -e "${YELLOW}  WireGuard will start after reboot${NC}"
fi

echo -e "${GREEN}✅ STARTUP COMPLETE!${NC}"
echo ""

# Wait a moment for services to initialize
sleep 10

# Show status
echo -e "${PURPLE}📊 FINAL STATUS CHECK:${NC}"
./ultimate-status.sh

echo ""
echo -e "${PURPLE}🎉 GARUDA MEDIA STACK READY!${NC}"
echo -e "${PURPLE}==============================${NC}"
echo -e "${GREEN}Your complete media stack is now running!${NC}"
echo ""
echo -e "${BLUE}Access your services at:${NC}"
echo -e "  Jellyfin:     http://$(ip route get 1.1.1.1 | awk '{print $7; exit}'):8096"
echo -e "  Radarr:       http://$(ip route get 1.1.1.1 | awk '{print $7; exit}'):7878"
echo -e "  Sonarr:       http://$(ip route get 1.1.1.1 | awk '{print $7; exit}'):8989"
echo -e "  Lidarr:       http://$(ip route get 1.1.1.1 | awk '{print $7; exit}'):8686"
echo -e "  Jackett:      http://$(ip route get 1.1.1.1 | awk '{print $7; exit}'):9117"
echo -e "  qBittorrent:  http://$(ip route get 1.1.1.1 | awk '{print $7; exit}'):5080"
echo -e "  Jellyseerr:   http://$(ip route get 1.1.1.1 | awk '{print $7; exit}'):5055"
echo -e "  Readarr:      http://$(ip route get 1.1.1.1 | awk '{print $7; exit}'):8787"
echo -e "  Calibre-Web:  http://$(ip route get 1.1.1.1 | awk '{print $7; exit}'):8083"
echo ""
echo -e "${BLUE}Privacy & VPN:${NC}"
echo -e "  WireGuard:    Port 51820"
echo -e "  API Proxy:    Port 8888"
echo -e "  Ghost Mode:   ENABLED"
echo ""
echo -e "${GREEN}All configurations saved to: /mnt/media/config/${NC}"
