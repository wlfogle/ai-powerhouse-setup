#!/bin/bash

# 🏠 Garuda Media Stack - Enhanced Health Check
# Comprehensive monitoring for native media stack services
# Adapted from awesome-stack and media-stack-admin-scripts patterns

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
LOG_FILE="/var/log/media-stack/health-check.log"
CONFIG_ROOT="${CONFIG_ROOT:-/home/lou/.config}"
DATA_ROOT="${DATA_ROOT:-/media}"

# Logging functions
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"; }
info() { echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"; }
section() { echo -e "${PURPLE}═══${NC} $1 ${PURPLE}═══${NC}" | tee -a "$LOG_FILE"; }

# Ensure log directory exists
sudo mkdir -p "$(dirname "$LOG_FILE")"
sudo chown -R lou:lou "$(dirname "$LOG_FILE")"

# Banner
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                🏠 Garuda Media Stack Health Check           ║
║              Comprehensive Service Monitoring               ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Service definitions with health check details
declare -A SERVICES=(
    # Native services installed via pacman
    ["radarr"]="7878:systemd:Movie automation"
    ["sonarr"]="8989:systemd:TV show automation"
    ["jackett"]="9117:systemd:Indexer proxy"
    ["jellyfin"]="8096:systemd:Media server"
    ["plexmediaserver"]="32400:systemd:Plex media server"
    
    # Manual installations with systemd services
    ["lidarr"]="8686:systemd:Music automation"
    ["readarr"]="8787:systemd:Book automation"
    ["audiobookshelf"]="13378:systemd:Audiobook server"
    ["jellyseerr"]="5055:systemd:Jellyfin requests"
    ["pulsarr"]="3030:systemd:Plex automation"
    ["calibre-web"]="8083:systemd:Ebook server"
    
    # System services
    ["qbittorrent"]="5080:process:Torrent client"
    ["docker"]="0:systemd:Container runtime"
    ["wireguard"]="51820:network:VPN server"
)

# System information
section "System Information"
info "Hostname: $(hostname)"
info "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
info "Kernel: $(uname -r)"
info "Uptime: $(uptime -p)"
info "Architecture: $(uname -m)"

# Check system resources
section "System Resources"

# CPU Usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
info "CPU Usage: $cpu_usage"

# Memory Usage
memory_info=$(free -h | awk 'NR==2{printf "Used: %s/%s (%.1f%%)", $3,$2,$3*100/$2}')
info "Memory: $memory_info"

# Disk Usage
disk_usage=$(df -h / | awk 'NR==2{printf "Used: %s/%s (%s)", $3,$2,$5}')
info "Root Disk: $disk_usage"

# Check media storage if it exists
if [[ -d "$DATA_ROOT" ]]; then
    media_usage=$(df -h "$DATA_ROOT" | awk 'NR==2{printf "Used: %s/%s (%s)", $3,$2,$5}')
    info "Media Storage: $media_usage"
fi

# Load Average
load_avg=$(uptime | awk -F'load average:' '{print $2}')
info "Load Average:$load_avg"

# Temperature (if available)
if command -v sensors >/dev/null 2>&1; then
    temp=$(sensors 2>/dev/null | grep "Core 0" | awk '{print $3}' | head -1)
    if [[ -n "$temp" ]]; then
        info "CPU Temperature: $temp"
    fi
fi

# Service Health Checks
section "Service Health Checks"

total_services=0
running_services=0
healthy_services=0

for service_name in "${!SERVICES[@]}"; do
    IFS=':' read -r port type description <<< "${SERVICES[$service_name]}"
    total_services=$((total_services + 1))
    
    echo -n "Checking $service_name ($description)... "
    
    service_running=false
    web_accessible=false
    
    # Check if service is running based on type
    case $type in
        "systemd")
            if systemctl is-active --quiet "$service_name" 2>/dev/null; then
                service_running=true
                running_services=$((running_services + 1))
            fi
            ;;
        "process")
            if pgrep -f "$service_name" >/dev/null 2>&1; then
                service_running=true
                running_services=$((running_services + 1))
            fi
            ;;
        "network")
            if [[ "$service_name" == "wireguard" ]]; then
                if sudo wg show 2>/dev/null | grep -q "interface\|peer"; then
                    service_running=true
                    running_services=$((running_services + 1))
                elif systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
                    service_running=true
                    running_services=$((running_services + 1))
                fi
            fi
            ;;
    esac
    
    # Check web interface accessibility (if port is specified and > 0)
    if [[ "$port" != "0" ]] && [[ "$service_running" == "true" ]]; then
        if timeout 3 curl -s -o /dev/null "http://localhost:$port" 2>/dev/null; then
            web_accessible=true
            healthy_services=$((healthy_services + 1))
            echo -e "${GREEN}✅ Running & Accessible${NC}"
        else
            echo -e "${YELLOW}⚠️ Running but Web UI not accessible${NC}"
        fi
    elif [[ "$service_running" == "true" ]]; then
        healthy_services=$((healthy_services + 1))
        echo -e "${GREEN}✅ Running${NC}"
    else
        echo -e "${RED}❌ Not running${NC}"
    fi
    
    # Additional service-specific checks
    case $service_name in
        "radarr"|"sonarr"|"lidarr"|"readarr")
            if [[ "$service_running" == "true" ]]; then
                # Check if config directory exists
                config_dir="$CONFIG_ROOT/media-stack/$service_name"
                if [[ -d "$config_dir" ]]; then
                    info "  📁 Config directory: ✅ $config_dir"
                else
                    warn "  📁 Config directory missing: $config_dir"
                fi
            fi
            ;;
        "jellyfin")
            if [[ "$service_running" == "true" ]]; then
                # Check Jellyfin library access
                if [[ -d "/var/lib/jellyfin" ]]; then
                    info "  📚 Library directory: ✅ /var/lib/jellyfin"
                fi
            fi
            ;;
        "qbittorrent")
            if [[ "$service_running" == "true" ]]; then
                # Check download directory
                if [[ -d "$DATA_ROOT/downloads" ]]; then
                    info "  ⬇️ Download directory: ✅ $DATA_ROOT/downloads"
                fi
            fi
            ;;
    esac
done

# Network connectivity checks
section "Network Connectivity"

# Check internet connectivity
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    log "✅ Internet connectivity: OK"
else
    error "❌ Internet connectivity: FAILED"
fi

# Check DNS resolution
if nslookup google.com >/dev/null 2>&1; then
    log "✅ DNS resolution: OK"
else
    error "❌ DNS resolution: FAILED"
fi

# WireGuard specific checks
section "WireGuard VPN Status"

wg_active=false
if systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
    wg_active=true
    log "✅ WireGuard VPN: Active (wg-quick@wg0)"
    
    # Check VPN interface
    if ip addr show wg0 >/dev/null 2>&1; then
        vpn_ip=$(ip addr show wg0 | grep 'inet ' | awk '{print $2}' | head -1)
        info "  🔒 VPN IP: $vpn_ip"
    fi
    
    # Check connected peers
    peer_count=$(sudo wg show wg0 peers 2>/dev/null | wc -l || echo "0")
    info "  👥 Connected peers: $peer_count"
    
    # Check if VPN server is listening
    if sudo ss -ulpn | grep -q ":51820"; then
        log "  🌐 VPN server listening on port 51820"
    else
        warn "  ⚠️ VPN server not listening on expected port 51820"
    fi
    
elif systemctl list-unit-files | grep -q "wg-quick@"; then
    warn "⚠️ WireGuard VPN: Configured but not active"
    info "  💡 Start with: sudo systemctl start wg-quick@wg0"
else
    warn "⚠️ WireGuard VPN: Not configured"
    info "  💡 WireGuard needs to be set up for remote access"
    info "  📖 Refer to: /home/lou/wireguard-setup-complete.md"
fi

# Docker status (if using any containerized services)
if command -v docker >/dev/null 2>&1; then
    if systemctl is-active --quiet docker; then
        log "✅ Docker: Running"
        container_count=$(docker ps -q 2>/dev/null | wc -l)
        info "  📦 Running containers: $container_count"
    else
        warn "⚠️ Docker: Not running"
    fi
fi

# Storage checks
section "Storage Health"

# Check filesystem health
filesystem_ok=true
while IFS= read -r filesystem; do
    if ! tune2fs -l "$filesystem" >/dev/null 2>&1; then
        if ! xfs_info "$filesystem" >/dev/null 2>&1; then
            warn "Could not check filesystem health for $filesystem"
            filesystem_ok=false
        fi
    fi
done < <(lsblk -no FSTYPE,NAME 2>/dev/null | grep -E '^(ext[234]|xfs)' | awk '{print "/dev/"$2}' || true)

if [[ "$filesystem_ok" == "true" ]]; then
    log "✅ Filesystem health: OK"
fi

# Check for available disk space warnings
while IFS= read -r mount_point usage; do
    usage_percent=$(echo "$usage" | tr -d '%')
    if [[ $usage_percent -gt 90 ]]; then
        error "❌ Disk usage critical: $mount_point ($usage)"
    elif [[ $usage_percent -gt 80 ]]; then
        warn "⚠️ Disk usage high: $mount_point ($usage)"
    fi
done < <(df -h | awk 'NR>1 && $5 ~ /%/ {print $6" "$5}')

# Performance metrics
section "Performance Metrics"

# Check system load
load_1min=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
cpu_cores=$(nproc)
load_threshold=$(echo "$cpu_cores * 1.5" | bc -l 2>/dev/null || echo "4.0")

if (( $(echo "$load_1min > $load_threshold" | bc -l 2>/dev/null || echo "0") )); then
    warn "⚠️ High system load: $load_1min (threshold: $load_threshold)"
else
    log "✅ System load: OK ($load_1min)"
fi

# Check memory pressure
memory_available=$(free | awk 'NR==2{printf "%.1f", $7*100/$2}')
if (( $(echo "$memory_available < 10" | bc -l 2>/dev/null || echo "0") )); then
    error "❌ Low memory available: ${memory_available}%"
elif (( $(echo "$memory_available < 20" | bc -l 2>/dev/null || echo "0") )); then
    warn "⚠️ Memory pressure: ${memory_available}% available"
else
    log "✅ Memory: OK (${memory_available}% available)"
fi

# Summary
section "Health Check Summary"

echo ""
echo -e "${CYAN}📊 SERVICE SUMMARY:${NC}"
echo -e "  Total services: $total_services"
echo -e "  Running services: ${GREEN}$running_services${NC}"
echo -e "  Healthy services: ${GREEN}$healthy_services${NC}"

if [[ $healthy_services -eq $total_services ]]; then
    echo -e "${GREEN}🎉 ALL SERVICES HEALTHY!${NC}"
    overall_status="HEALTHY"
elif [[ $running_services -eq $total_services ]]; then
    echo -e "${YELLOW}⚠️ All services running, some web interfaces not accessible${NC}"
    overall_status="PARTIAL"
else
    echo -e "${RED}❌ Some services are not running${NC}"
    overall_status="DEGRADED"
fi

echo ""
echo -e "${CYAN}🔗 LOCAL ACCESS URLS:${NC}"
echo -e "  Dashboard: ${GREEN}http://localhost:8600${NC} (Grandmother Dashboard)"
echo -e "  Jellyfin:  ${GREEN}http://localhost:8096${NC}"
echo -e "  Plex:      ${GREEN}http://localhost:32400/web${NC}"
echo -e "  Radarr:    ${GREEN}http://localhost:7878${NC}"
echo -e "  Sonarr:    ${GREEN}http://localhost:8989${NC}"
echo -e "  qBittorrent: ${GREEN}http://localhost:5080${NC}"
echo -e "  Jackett:   ${GREEN}http://localhost:9117${NC}"

# WireGuard access info
if [[ "$wg_active" == "true" ]]; then
    echo ""
    echo -e "${CYAN}🔒 VPN ACCESS (WireGuard):${NC}"
    echo -e "  VPN Status: ${GREEN}Active${NC}"
    echo -e "  Server IP: ${GREEN}172.59.85.76:51820${NC}"
    echo -e "  VPN Network: ${GREEN}10.0.0.0/8${NC}"
    echo -e "  Dashboard via VPN: ${GREEN}http://10.0.0.1:8600${NC}"
    echo -e "  Jellyfin via VPN:  ${GREEN}http://10.0.0.1:8096${NC}"
    echo -e "  Plex via VPN:      ${GREEN}http://10.0.0.1:32400/web${NC}"
    echo ""
    echo -e "${CYAN}📱 MOBILE ACCESS:${NC}"
    echo -e "  Install WireGuard app and scan QR code"
    echo -e "  Config file: ${GREEN}/etc/wireguard/wg0.conf${NC}"
else
    echo ""
    echo -e "${YELLOW}🔒 VPN ACCESS: Not Available${NC}"
    echo -e "  WireGuard VPN is not active"
    echo -e "  📖 Setup guide: ${GREEN}/home/lou/wireguard-setup-complete.md${NC}"
    echo -e "  🛠️ Enable with: ${GREEN}sudo systemctl start wg-quick@wg0${NC}"
fi

echo ""
echo -e "${CYAN}🛠️ MANAGEMENT COMMANDS:${NC}"
echo -e "  Health Check:    ${GREEN}./scripts/health-check-enhanced.sh${NC}"
echo -e "  Start All:       ${GREEN}./start-all-services.sh${NC}"
echo -e "  Stop All:        ${GREEN}./stop-all-services.sh${NC}"
echo -e "  View Logs:       ${GREEN}sudo journalctl -f -u <service-name>${NC}"
echo -e "  Dashboard:       ${GREEN}firefox http://localhost:8600${NC}"

# WireGuard management commands
echo ""
echo -e "${CYAN}🔒 WIREGUARD COMMANDS:${NC}"
echo -e "  Start VPN:       ${GREEN}sudo systemctl start wg-quick@wg0${NC}"
echo -e "  Enable Auto-start: ${GREEN}sudo systemctl enable wg-quick@wg0${NC}"
echo -e "  Check Status:    ${GREEN}sudo wg show${NC}"
echo -e "  View VPN Logs:   ${GREEN}sudo journalctl -u wg-quick@wg0 -f${NC}"

# Create status badge
case $overall_status in
    "HEALTHY")
        echo -e "${GREEN}🏆 SYSTEM STATUS: EXCELLENT${NC}"
        echo -e "${GREEN}🌟 Your media stack is running perfectly!${NC}"
        ;;
    "PARTIAL")
        echo -e "${YELLOW}🔧 SYSTEM STATUS: NEEDS ATTENTION${NC}"
        echo -e "${YELLOW}⚡ Some services need configuration${NC}"
        ;;
    "DEGRADED")
        echo -e "${RED}🚨 SYSTEM STATUS: CRITICAL${NC}"
        echo -e "${RED}🛠️ Multiple services need immediate attention${NC}"
        ;;
esac

# Grandmother-friendly summary
echo ""
section "👵 For Grandma"
echo -e "${CYAN}📺 TO WATCH MOVIES & TV:${NC}"
echo -e "  1. Open web browser"
echo -e "  2. Go to: ${GREEN}http://localhost:8600${NC}"
echo -e "  3. Click the big colorful buttons!"

if [[ "$wg_active" == "true" ]]; then
    echo ""
    echo -e "${CYAN}📱 TO WATCH FROM ANYWHERE:${NC}"
    echo -e "  1. Connect to VPN on your phone/tablet"
    echo -e "  2. Go to: ${GREEN}http://10.0.0.1:8600${NC}"
    echo -e "  3. Enjoy your media from anywhere!"
fi

# Log completion
echo "$(date '+%Y-%m-%d %H:%M:%S') - Health check completed - Status: $overall_status" >> "$LOG_FILE"

# Exit with appropriate code
case $overall_status in
    "HEALTHY") exit 0 ;;
    "PARTIAL") exit 1 ;;
    "DEGRADED") exit 2 ;;
esac
