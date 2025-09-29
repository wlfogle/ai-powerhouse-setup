#!/bin/bash

# Ultimate Garuda Media Stack Status Checker
# Complete status of ALL services + VPN/Ghost Mode

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

HOST_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')

echo -e "${PURPLE}🚀 ULTIMATE GARUDA MEDIA STACK STATUS${NC}"
echo -e "${PURPLE}====================================${NC}"
echo -e "Host IP: ${GREEN}${HOST_IP}${NC}"
echo ""

# VPN and Privacy Status
echo -e "${CYAN}🔒 VPN & Privacy Status:${NC}"

# Check WireGuard
if ss -tuln | grep -q ":51820 "; then
    wg_status="${GREEN}✅ READY${NC}"
else
    wg_status="${YELLOW}⏳ CONFIGURED${NC}"
fi
echo -e "WireGuard Server: $wg_status (Port 51820)"

# Check Ghost Mode
if [[ -f /home/lou/github/garuda-media-stack/ghost-mode-status.txt ]]; then
    ghost_status=$(cat /home/lou/github/garuda-media-stack/ghost-mode-status.txt 2>/dev/null || echo "unknown")
    if [[ "$ghost_status" == "enabled" ]]; then
        ghost_display="${GREEN}✅ ENABLED${NC}"
    else
        ghost_display="${YELLOW}⏳ DISABLED${NC}"
    fi
else
    ghost_display="${RED}❌ NOT CONFIGURED${NC}"
fi
echo -e "Ghost Mode:       $ghost_display"

# Check API Proxy
if ss -tuln | grep -q ":8888 "; then
    proxy_status="${GREEN}✅ ONLINE${NC}"
else
    proxy_status="${RED}❌ OFFLINE${NC}"
fi
echo -e "API Proxy:        $proxy_status (Port 8888)"

echo ""

# Core Media Services
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

core_online=0
for service_info in "${core_services[@]}"; do
    IFS=':' read -r name port <<< "$service_info"
    url="http://${HOST_IP}:${port}"
    
    if ss -tuln | grep -q ":${port} "; then
        if curl -s --connect-timeout 2 --max-time 3 "$url" >/dev/null 2>&1; then
            status="${GREEN}✅ ONLINE${NC}"
            ((core_online++))
        else
            status="${YELLOW}⏳ STARTING${NC}"
        fi
    else
        status="${RED}❌ OFFLINE${NC}"
    fi
    
    printf "%-15s %s %s\\n" "$name:" "$status" "$url"
done

echo ""

# Additional Services
echo -e "${BLUE}📚 Additional Services:${NC}"
additional_services=(
    "Readarr:8787"
    "Calibre-Web:8083"
    "Pulsarr:9001"
)

additional_online=0
for service_info in "${additional_services[@]}"; do
    IFS=':' read -r name port <<< "$service_info"
    url="http://${HOST_IP}:${port}"
    
    if ss -tuln | grep -q ":${port} "; then
        if curl -s --connect-timeout 2 --max-time 3 "$url" >/dev/null 2>&1; then
            status="${GREEN}✅ ONLINE${NC}"
            ((additional_online++))
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
total_online=$((core_online + additional_online))
echo -e "${PURPLE}📊 SYSTEM SUMMARY:${NC}"
echo -e "Core Services:       ${GREEN}${core_online}/7${NC} online"
echo -e "Additional Services: ${GREEN}${additional_online}/3${NC} online"
echo -e "Total Media Stack:   ${GREEN}${total_online}/10${NC} services online"

# VPN Summary
vpn_features=0
ss -tuln | grep -q ":51820 " && ((vpn_features++))
ss -tuln | grep -q ":8888 " && ((vpn_features++))
[[ "$ghost_status" == "enabled" ]] && ((vpn_features++))

echo -e "VPN/Privacy Stack:   ${GREEN}${vpn_features}/3${NC} features active"

echo ""

# Configuration Files
echo -e "${CYAN}🗂️ Configuration Status:${NC}"
configs=(
    "Media configs: /mnt/media/config/"
    "WireGuard: /etc/wireguard/"
    "Client configs: /home/lou/wireguard-clients/"
)

for config in "${configs[@]}"; do
    path=$(echo "$config" | cut -d: -f2 | tr -d ' ')
    name=$(echo "$config" | cut -d: -f1)
    
    if [[ -d "$path" ]] && [[ $(ls -A "$path" 2>/dev/null | wc -l) -gt 0 ]]; then
        echo -e "${name}: ${GREEN}✅ CONFIGURED${NC}"
    else
        echo -e "${name}: ${RED}❌ MISSING${NC}"
    fi
done

echo ""

# Performance Status
echo -e "${PURPLE}⚡ PERFORMANCE STATUS:${NC}"
processes=$(ps aux | grep -E '(jellyfin|radarr|sonarr|lidarr|jackett|qbittorrent|jellyseerr|readarr|calibre)' | grep -v grep | wc -l)
echo -e "Active processes: ${GREEN}${processes}${NC}"

memory=$(free -h | awk '/^Mem:/ {print $3"/"$2}')
echo -e "Memory usage: ${GREEN}${memory}${NC}"

# Network Ports Summary  
echo ""
echo -e "${PURPLE}🌐 LISTENING PORTS:${NC}"
important_ports=(5055 5080 7878 8083 8096 8686 8787 8888 8989 9001 9117 51820)
for port in "${important_ports[@]}"; do
    if ss -tuln | grep -q ":${port} "; then
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
            8888) service="API Proxy" ;;
            51820) service="WireGuard" ;;
        esac
        echo -e "${GREEN}  ✅ $port ($service)${NC}"
    fi
done

echo ""
echo -e "${PURPLE}🎉 STACK STATUS: $(( (total_online + vpn_features) * 100 / 13 ))% OPERATIONAL${NC}"
