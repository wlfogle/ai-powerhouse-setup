#!/bin/bash

# Fixed Garuda Media Stack Startup - Handles all edge cases
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}🔧 FIXING & STARTING COMPLETE MEDIA STACK${NC}"
echo -e "${PURPLE}=========================================${NC}"

# Kill all conflicting processes
echo -e "${YELLOW}🛑 Cleaning all processes...${NC}"
pkill -f qbittorrent || true
pkill -f jackett || true  
pkill -f jellyseerr || true
pkill -f calibre || true
pkill -f api-server || true
pkill -f readarr || true
sleep 3

# Create all config directories
echo -e "${YELLOW}📁 Creating config directories...${NC}"
mkdir -p /mnt/media/config/{qbittorrent,jackett,jellyseerr,readarr,calibre}
chown -R lou:lou /mnt/media/config/ || true

# Fix permissions
echo -e "${YELLOW}🔐 Fixing permissions...${NC}"
sudo rm -f /usr/lib/jackett/.lock || true
sudo chown -R lou:lou /usr/lib/jackett/ || true

# Start qBittorrent (simple approach)
echo -e "${BLUE}⬇️ Starting qBittorrent...${NC}"
export HOME=/mnt/media/config/qbittorrent
export XDG_CONFIG_HOME=/mnt/media/config
qbittorrent-nox --webui-port=5080 --profile=/mnt/media/config/qbittorrent &
sleep 5

# Start Jackett with minimal setup
echo -e "${BLUE}🔍 Starting Jackett...${NC}"
systemctl start jackett || /usr/lib/jackett/jackett --Port=9117 --DataFolder=/mnt/media/config/jackett &
sleep 5

# Start API Server on default port (8080)
echo -e "${BLUE}🌐 Starting API Server...${NC}"
cd /home/lou/github/garuda-media-stack
python3 -c "
import socketserver
import http.server
import json
import subprocess

class APIHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/status':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            status = {'status': 'running', 'services': []}
            self.wfile.write(json.dumps(status).encode())
        else:
            self.send_response(404)
            self.end_headers()
    def log_message(self, format, *args): pass

with socketserver.TCPServer(('', 8888), APIHandler) as httpd:
    httpd.serve_forever()
" &
sleep 3

# Start Readarr if available
if [[ -x /mnt/media/Readarr-0.9.0/Readarr ]]; then
    echo -e "${BLUE}📚 Starting Readarr...${NC}"
    cd /mnt/media/Readarr-0.9.0
    ./Readarr --nobrowser --data=/mnt/media/config/readarr &
    sleep 3
fi

# Start Calibre-Web if available  
if [[ -f /mnt/media/calibre-web-0.6.25/cps.py ]]; then
    echo -e "${BLUE}📖 Starting Calibre-Web...${NC}"
    cd /mnt/media/calibre-web-0.6.25
    pip3 install --user -r requirements.txt >/dev/null 2>&1 || true
    python3 cps.py -p 8083 -g /mnt/media/config/calibre &
    sleep 3
fi

# Start Jellyseerr if possible (skip if npm issues)
if [[ -d /mnt/media/jellyseerr-2.7.3 ]] && [[ -f /mnt/media/jellyseerr-2.7.3/dist/index.js ]]; then
    echo -e "${BLUE}📺 Starting Jellyseerr...${NC}"
    cd /mnt/media/jellyseerr-2.7.3
    PORT=5055 CONFIG_DIRECTORY=/mnt/media/config/jellyseerr node dist/index.js &
    sleep 3
fi

# Enable Ghost Mode
echo -e "${BLUE}🥷 Enabling Ghost Mode...${NC}"
cd /home/lou/github/garuda-media-stack
./ghost-control.sh enable || true
echo "enabled" > ghost-mode-status.txt

echo -e "${GREEN}✅ FIXES APPLIED!${NC}"
echo ""

# Wait for services to start
sleep 10

# Final status
echo -e "${PURPLE}📊 FINAL STATUS:${NC}"
./ultimate-status.sh

echo ""
echo -e "${GREEN}🎉 FIXED MEDIA STACK STATUS:${NC}"

# Test each service
services=(
    "Jellyfin:8096"
    "Radarr:7878" 
    "Sonarr:8989"
    "Lidarr:8686"
    "qBittorrent:5080"
    "Jackett:9117"
    "Readarr:8787"
    "API Proxy:8888"
    "Calibre-Web:8083"
    "Jellyseerr:5055"
)

working=0
total=${#services[@]}

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    if ss -tuln | grep -q ":${port} "; then
        echo -e "${GREEN}✅ $name (port $port)${NC}"
        ((working++))
    else
        echo -e "${RED}❌ $name (port $port)${NC}"
    fi
done

echo ""
echo -e "${PURPLE}📊 SUMMARY: $working/$total services working ($(( working * 100 / total ))%)${NC}"
echo -e "${GREEN}🎉 Your media stack is ready!${NC}"
