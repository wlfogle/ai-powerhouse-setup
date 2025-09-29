#!/bin/bash

# Simple Media Stack Status Checker
# Works with both native and container installations

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

HOST_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')

echo -e "${BLUE}🎬 Garuda Media Stack Status${NC}"
echo -e "${BLUE}=============================${NC}"
echo -e "Host IP: ${GREEN}${HOST_IP}${NC}"
echo ""

# Check services
services=(
    "Jellyfin:8096"
    "Radarr:7878"
    "Sonarr:8989" 
    "Lidarr:8686"
    "Jackett:9117"
    "qBittorrent:5080"
    "Jellyseerr:5055"
)

for service_info in "${services[@]}"; do
    IFS=':' read -r name port <<< "$service_info"
    url="http://${HOST_IP}:${port}"
    
    # Check if port is listening
    if ss -tuln | grep -q ":${port} "; then
        # Try HTTP request
        if curl -s --connect-timeout 3 --max-time 5 "$url" >/dev/null 2>&1; then
            status="${GREEN}✅ ONLINE${NC}"
        else
            status="${YELLOW}⏳ STARTING${NC}"
        fi
    else
        status="${RED}❌ OFFLINE${NC}"
    fi
    
    printf "%-15s %s %s\\n" "$name:" "$status" "$url"
done

echo ""

# Show running processes
echo -e "${BLUE}📊 Running Processes:${NC}"
processes=$(ps aux | grep -E '(jellyfin|radarr|sonarr|lidarr|jackett|qbittorrent)' | grep -v grep | wc -l)
echo -e "Found ${GREEN}${processes}${NC} media service processes"

# Show listening ports
echo ""
echo -e "${BLUE}🌐 Listening Ports:${NC}"
ss -tuln | grep -E ':(5080|8096|7878|8989|8686|9117|5055)' | while read line; do
    echo -e "${GREEN}  $line${NC}"
done
