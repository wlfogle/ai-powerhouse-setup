#!/bin/bash

# Complete Garuda Media Stack Status Checker
# Shows status of ALL services including additional ones

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

HOST_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')

echo -e "${BLUE}🎬 COMPLETE Garuda Media Stack Status${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "Host IP: ${GREEN}${HOST_IP}${NC}"
echo ""

# Core services
echo -e "${BLUE}📺 Core Media Services:${NC}"
core_services=(
    "Jellyfin:8096"
    "Radarr:7878"
    "Sonarr:8989" 
    "Lidarr:8686"
    "Jackett:9117"
    "qBittorrent:5080"
    "Jellyseerr:5055"
)

for service_info in "${core_services[@]}"; do
    IFS=':' read -r name port <<< "$service_info"
    url="http://${HOST_IP}:${port}"
    
    if ss -tuln | grep -q ":${port} "; then
        if curl -s --connect-timeout 2 --max-time 3 "$url" >/dev/null 2>&1; then
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

# Additional services
echo -e "${BLUE}📚 Additional Services:${NC}"
additional_services=(
    "Readarr:8787"
    "Calibre-Web:8083"
    "Pulsarr:9001"
)

for service_info in "${additional_services[@]}"; do
    IFS=':' read -r name port <<< "$service_info"
    url="http://${HOST_IP}:${port}"
    
    if ss -tuln | grep -q ":${port} "; then
        if curl -s --connect-timeout 2 --max-time 3 "$url" >/dev/null 2>&1; then
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

# Summary
online_core=$(ss -tuln | grep -cE ':(8096|7878|8989|8686|9117|5080|5055) ')
online_additional=$(ss -tuln | grep -cE ':(8787|8083|9001) ')
total_online=$((online_core + online_additional))

echo -e "${BLUE}📊 Summary:${NC}"
echo -e "Core Services: ${GREEN}${online_core}/7${NC} online"
echo -e "Additional Services: ${GREEN}${online_additional}/3${NC} online"
echo -e "Total Services: ${GREEN}${total_online}/10${NC} online"

# Show all listening ports for media stack
echo ""
echo -e "${BLUE}🌐 All Media Stack Ports:${NC}"
ss -tuln | grep -E ':(5055|5080|7878|8083|8096|8686|8787|8989|9001|9117) ' | while read line; do
    port=$(echo "$line" | grep -oE ':[0-9]+' | head -1 | tr -d ':')
    case $port in
        8096) service="Jellyfin" ;;
        7878) service="Radarr" ;;
        8989) service="Sonarr" ;;
        8686) service="Lidarr" ;;
        9117) service="Jackett" ;;
        5080) service="qBittorrent" ;;
        5055) service="Jellyseerr" ;;
        8787) service="Readarr" ;;
        8083) service="Calibre-Web" ;;
        9001) service="Pulsarr" ;;
        *) service="Unknown" ;;
    esac
    echo -e "${GREEN}  $service ($port): $line${NC}"
done
