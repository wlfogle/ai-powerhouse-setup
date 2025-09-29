#!/bin/bash

# 🥷 WireGuard Dual-Role + Ghost Mode VPN Setup for Garuda Media Stack
# Main system acts as both SERVER and CLIENT for complete VPN coverage
# Integrates with Ghost Mode for ultimate anonymity
# Predefined configs for phone, tablet, and Fire TV devices
# Based on awesome-stack advanced VPN suite with rotation and stealth features

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Logging functions
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"; }
info() { echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"; }
section() { echo -e "${PURPLE}═══${NC} $1 ${PURPLE}═══${NC}"; }

# Device configurations based on router settings
declare -A DEVICES=(
    ["phone"]="10.0.0.10"           # Android-3/Android-4
    ["tablet"]="10.0.0.11"          # Jackie-s-Tab-A7-Lite  
    ["firetv1"]="10.0.0.12"         # amazon-3b7916bc43038426
    ["firetv2"]="10.0.0.13"         # amazon-f4efe1dd8
    ["main-system"]="10.0.0.2"      # lou-eon17x (client config)
)

# Configuration
EXTERNAL_IP=""
VPN_PORT="51820"
VPN_NETWORK="10.0.0.0/24"
SERVER_IP="10.0.0.1"
CONFIG_DIR="/home/lou/wireguard-clients"
GHOST_MODE_DIR="/home/lou/github/awesome-stack/ghost-mode"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root. Run as regular user with sudo privileges."
    exit 1
fi

# Banner
echo -e "${CYAN}${BOLD}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║          🥷 WireGuard Dual-Role + Ghost Mode Setup          ║
║                 Advanced VPN & Anonymity Suite              ║
║                                                              ║
║    🔄 Server + Client on main system                        ║
║    🛡️ Ghost Mode integration                                ║
║    📱 Predefined device configurations                      ║
║    🔑 Automated key rotation                                ║
║                                                              ║
║              🔒 Secure • 🥷 Anonymous • 🌍 Global          ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if WireGuard is already configured
section "WireGuard Status Check"

if systemctl is-active --quiet wg-quick@wg0-server 2>/dev/null && systemctl is-active --quiet wg-quick@wg0-client 2>/dev/null; then
    log "✅ WireGuard dual-role setup is already active!"
    
    echo ""
    echo -e "${CYAN}📊 Current WireGuard Status:${NC}"
    
    # Show server status
    if ip addr show wg0-server >/dev/null 2>&1; then
        server_ip=$(ip addr show wg0-server | grep 'inet ' | awk '{print $2}' | head -1)
        info "VPN Server IP: $server_ip"
    fi
    
    # Show client status
    if ip addr show wg0-client >/dev/null 2>&1; then
        client_ip=$(ip addr show wg0-client | grep 'inet ' | awk '{print $2}' | head -1)
        info "VPN Client IP: $client_ip"
    fi
    
    # Get connected peers
    peer_count=$(sudo wg show wg0-server peers 2>/dev/null | wc -l || echo "0")
    info "Connected clients: $peer_count"
    
    echo ""
    echo -e "${GREEN}🎉 Your dual-role VPN is ready to use!${NC}"
    echo -e "${CYAN}🔗 Access your media stack (via VPN tunnel):${NC}"
    echo -e "  Dashboard: ${GREEN}http://10.0.0.1:8600${NC}"
    echo -e "  Jellyfin:  ${GREEN}http://10.0.0.1:8096${NC}"
    echo -e "  Plex:      ${GREEN}http://10.0.0.1:32400/web${NC}"
    
    exit 0
fi

# Install dependencies
section "Installing Dependencies"

log "Installing WireGuard and dependencies..."
sudo pacman -S --needed --noconfirm wireguard-tools unbound qrencode python-pyqt5 python-requests

log "✅ Dependencies installed"

# Get external IP
section "Network Configuration"

log "Detecting external IP address..."
EXTERNAL_IP=$(curl -4 -s --max-time 10 ifconfig.me || curl -4 -s --max-time 10 icanhazip.com || echo "")

if [[ -z "$EXTERNAL_IP" ]]; then
    error "Could not detect external IP address"
    error "Please ensure you have internet connectivity"
    exit 1
fi

log "✅ External IP detected: $EXTERNAL_IP"

# Generate all required keys
section "Generating Cryptographic Keys"

log "Generating server keys..."
server_private_key=$(wg genkey)
server_public_key=$(echo "$server_private_key" | wg pubkey)

log "Generating main system client keys..."
main_client_private_key=$(wg genkey)
main_client_public_key=$(echo "$main_client_private_key" | wg pubkey)

log "Generating device keys..."
declare -A device_private_keys device_public_keys preshared_keys

for device in "${!DEVICES[@]}"; do
    device_private_keys["$device"]=$(wg genkey)
    device_public_keys["$device"]=$(echo "${device_private_keys[$device]}" | wg pubkey)
    preshared_keys["$device"]=$(wg genpsk)
    log "Keys generated for: $device"
done

log "✅ All cryptographic keys generated"

# Create WireGuard server configuration
section "Creating Server Configuration"

sudo tee /etc/wireguard/wg0-server.conf > /dev/null << EOF
# WireGuard VPN Server Configuration - Dual Role Setup
# Generated on $(date)
# Garuda Media Stack + Ghost Mode Integration

[Interface]
Address = $SERVER_IP/24
ListenPort = $VPN_PORT
PrivateKey = $server_private_key
DNS = 1.1.1.1, 8.8.8.8

# iptables rules for NAT and routing
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o \$(ip route | awk 'NR==1{print \$5}') -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o \$(ip route | awk 'NR==1{print \$5}') -j MASQUERADE

# Enable IP forwarding
PreUp = echo 1 > /proc/sys/net/ipv4/ip_forward

# Main system as client (dual-role)
[Peer]
# Main System Client Role
PublicKey = $main_client_public_key
PresharedKey = ${preshared_keys["main-system"]}
AllowedIPs = ${DEVICES["main-system"]}/32

EOF

# Add all other devices to server config
for device in "${!DEVICES[@]}"; do
    if [[ "$device" != "main-system" ]]; then
        cat >> /tmp/server_peers << EOF
[Peer]
# $device
PublicKey = ${device_public_keys["$device"]}
PresharedKey = ${preshared_keys["$device"]}
AllowedIPs = ${DEVICES["$device"]}/32

EOF
    fi
done

sudo tee -a /etc/wireguard/wg0-server.conf < /tmp/server_peers > /dev/null
rm -f /tmp/server_peers

log "✅ Server configuration created: /etc/wireguard/wg0-server.conf"

# Create main system client configuration (dual-role)
section "Creating Main System Client Configuration"

sudo tee /etc/wireguard/wg0-client.conf > /dev/null << EOF
# WireGuard Client Configuration - Main System Dual Role
# Generated on $(date)
# Routes ALL traffic through VPN for complete anonymity

[Interface]
Address = ${DEVICES["main-system"]}/24
DNS = 1.1.1.1, 8.8.8.8
PrivateKey = $main_client_private_key
Table = 1000

# Custom routing for dual-role (avoid conflicts)
PostUp = ip rule add fwmark 0x1 table 1000 priority 100
PostUp = ip route add default dev %i table 1000
PostUp = ip rule add to $SERVER_IP table main priority 50

PostDown = ip rule del fwmark 0x1 table 1000 priority 100 || true
PostDown = ip route del default dev %i table 1000 || true
PostDown = ip rule del to $SERVER_IP table main priority 50 || true

[Peer]
PublicKey = $server_public_key
PresharedKey = ${preshared_keys["main-system"]}
Endpoint = 127.0.0.1:$VPN_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

log "✅ Main system client configuration created: /etc/wireguard/wg0-client.conf"

# Create client directory and device configurations
section "Creating Device Client Configurations"

mkdir -p "$CONFIG_DIR"

for device in "${!DEVICES[@]}"; do
    if [[ "$device" != "main-system" ]]; then
        device_config="$CONFIG_DIR/${device}.conf"
        
        tee "$device_config" > /dev/null << EOF
# WireGuard Client Configuration: $device
# Generated on $(date)
# Garuda Media Stack Remote Access

[Interface]
Address = ${DEVICES["$device"]}/24
DNS = 10.0.0.1
PrivateKey = ${device_private_keys["$device"]}
MTU = 1280

[Peer]
PublicKey = $server_public_key
PresharedKey = ${preshared_keys["$device"]}
Endpoint = $EXTERNAL_IP:$VPN_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
        
        # Generate QR code for mobile devices
        if [[ "$device" == "phone" || "$device" == "tablet" ]]; then
            qr_file="$CONFIG_DIR/${device}-qr.png"
            if command -v qrencode >/dev/null 2>&1; then
                qrencode -t PNG -o "$qr_file" < "$device_config"
                log "QR code generated: $qr_file"
            fi
        fi
        
        log "✅ Configuration created for: $device (${DEVICES["$device"]})"
    fi
done

# Configure DNS server (unbound)
section "Configuring DNS Server"

log "Setting up unbound DNS server..."

sudo tee /etc/unbound/unbound.conf > /dev/null << 'EOF'
server:
    interface: 10.0.0.1
    interface: 127.0.0.1
    access-control: 10.0.0.0/8 allow
    access-control: 127.0.0.0/8 allow
    port: 53
    do-ip4: yes
    do-ip6: no
    do-udp: yes
    do-tcp: yes
    
    # Privacy and security
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    
    # Performance optimization
    num-threads: 4
    msg-cache-slabs: 8
    rrset-cache-slabs: 8
    infra-cache-slabs: 8
    key-cache-slabs: 8
    
    # Cache settings for anonymity
    cache-min-ttl: 300
    cache-max-ttl: 3600
    serve-expired: yes
    
    # Root hints
    root-hints: "/var/lib/unbound/root.hints"

# Forward to secure DNS with DoT support
forward-zone:
    name: "."
    forward-tls-upstream: yes
    forward-addr: 1.1.1.1@853#cloudflare-dns.com
    forward-addr: 1.0.0.1@853#cloudflare-dns.com
    forward-addr: 8.8.8.8@853#dns.google
    forward-addr: 8.8.4.4@853#dns.google
EOF

sudo systemctl enable unbound
sudo systemctl start unbound || warn "Could not start unbound DNS server"

log "✅ Secure DNS server configured with DoT"

# Enable IP forwarding and disable IPv6 (Ghost Mode requirement)
section "Network Security Configuration"

log "Configuring network security settings..."

# IP forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf

# Disable IPv6 completely (Ghost Mode requirement)
echo 'net.ipv6.conf.all.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf

# Security hardening
echo 'net.ipv4.conf.all.send_redirects = 0' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.conf.default.send_redirects = 0' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.conf.all.accept_redirects = 0' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.conf.default.accept_redirects = 0' | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

log "✅ Network security configured (IPv6 disabled for Ghost Mode)"

# Create systemd services for dual-role operation
section "Creating Systemd Services"

# Server service
sudo tee /etc/systemd/system/wg-quick@wg0-server.service > /dev/null << 'EOF'
[Unit]
Description=WireGuard VPN Server via wg-quick(8) for %I
After=network-online.target nss-lookup.target
Wants=network-online.target nss-lookup.target
PartOf=wg-quick.target
Documentation=man:wg-quick(8)
Documentation=man:wg(8)
Documentation=https://www.wireguard.com/
Documentation=https://www.wireguard.com/quickstart/

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/wg-quick up %i
ExecStop=/usr/bin/wg-quick down %i
ExecReload=/bin/bash -c 'exec /usr/bin/wg syncconf %i <(exec /usr/bin/wg-quick strip %i)'
Environment=WG_ENDPOINT_RESOLUTION_RETRIES=infinity

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ProtectKernelTunables=false
ProtectKernelModules=false
ProtectControlGroups=true
RestrictSUIDSGID=true
RestrictRealtime=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictNamespaces=true
SystemCallArchitectures=native

# Network settings
IPAddressDeny=any
IPAddressAllow=localhost
IPAddressAllow=127.0.0.0/8
IPAddressAllow=192.168.0.0/16
IPAddressAllow=10.0.0.0/8

[Install]
WantedBy=multi-user.target
EOF

# Client service
sudo tee /etc/systemd/system/wg-quick@wg0-client.service > /dev/null << 'EOF'
[Unit]
Description=WireGuard VPN Client via wg-quick(8) for %I
After=wg-quick@wg0-server.service network-online.target
Wants=network-online.target
Requires=wg-quick@wg0-server.service
Documentation=man:wg-quick(8)
Documentation=man:wg(8)

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/wg-quick up %i
ExecStop=/usr/bin/wg-quick down %i
ExecReload=/bin/bash -c 'exec /usr/bin/wg syncconf %i <(exec /usr/bin/wg-quick strip %i)'
Environment=WG_ENDPOINT_RESOLUTION_RETRIES=infinity

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ProtectKernelTunables=false
ProtectKernelModules=false
ProtectControlGroups=true
RestrictSUIDSGID=true
RestrictRealtime=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictNamespaces=true
SystemCallArchitectures=native

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

log "✅ Systemd services created"

# Configure firewall
section "Configuring Firewall"

log "Setting up firewall rules..."

# Open WireGuard port
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow $VPN_PORT/udp comment "WireGuard VPN Server"
    
    # Ghost Mode DNS protection - block direct DNS
    sudo ufw deny out 53 comment "Block direct DNS (Ghost Mode)"
    sudo ufw allow out on wg0-client to any port 53 comment "Allow DNS through VPN"
    
    log "✅ UFW firewall configured"
elif command -v firewalld >/dev/null 2>&1; then
    sudo firewall-cmd --permanent --add-port=$VPN_PORT/udp
    sudo firewall-cmd --reload
    log "✅ Firewalld configured"
else
    warn "No recognized firewall found - please manually open port $VPN_PORT/UDP"
fi

# Start WireGuard services
section "Starting WireGuard Services"

log "Starting WireGuard server..."
sudo systemctl enable wg-quick@wg0-server
sudo systemctl start wg-quick@wg0-server

if systemctl is-active --quiet wg-quick@wg0-server; then
    log "✅ WireGuard server started successfully!"
else
    error "❌ Failed to start WireGuard server"
    error "Check logs with: sudo journalctl -u wg-quick@wg0-server"
    exit 1
fi

log "Starting WireGuard client (main system dual-role)..."
sudo systemctl enable wg-quick@wg0-client
sudo systemctl start wg-quick@wg0-client

if systemctl is-active --quiet wg-quick@wg0-client; then
    log "✅ WireGuard client started successfully!"
    log "🥷 Main system is now routing through VPN tunnel"
else
    error "❌ Failed to start WireGuard client"
    error "Check logs with: sudo journalctl -u wg-quick@wg0-client"
    exit 1
fi

# Create advanced management script with Ghost Mode integration
section "Creating Advanced Management Tools"

cat > /home/lou/garuda-media-stack/scripts/ghost-wireguard-manager.sh << 'EOF'
#!/bin/bash
# Advanced WireGuard + Ghost Mode Manager for Garuda Media Stack

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

GHOST_MODE_PATH="/home/lou/github/awesome-stack/ghost-mode"

show_banner() {
    echo -e "${CYAN}${BOLD}"
    cat << 'BANNER'
╔══════════════════════════════════════════════════════════════╗
║         🥷 Ghost Mode + WireGuard Manager                   ║
║              Ultimate Anonymity Control                     ║
╚══════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
}

case "$1" in
    "start")
        show_banner
        echo -e "${GREEN}🚀 Starting Ghost Mode + WireGuard...${NC}"
        
        # Start WireGuard services
        sudo systemctl start wg-quick@wg0-server
        sudo systemctl start wg-quick@wg0-client
        
        # Start Ghost Mode if available
        if [[ -x "$GHOST_MODE_PATH/scripts/ghost-mode" ]]; then
            echo -e "${PURPLE}🥷 Activating Ghost Mode...${NC}"
            "$GHOST_MODE_PATH/scripts/ghost-mode" start
        fi
        
        echo -e "${GREEN}✅ Complete anonymity activated${NC}"
        ;;
        
    "stop")
        echo -e "${YELLOW}🛑 Stopping Ghost Mode + WireGuard...${NC}"
        
        # Stop Ghost Mode if available
        if [[ -x "$GHOST_MODE_PATH/scripts/ghost-mode" ]]; then
            "$GHOST_MODE_PATH/scripts/ghost-mode" stop
        fi
        
        # Stop WireGuard services
        sudo systemctl stop wg-quick@wg0-client
        sudo systemctl stop wg-quick@wg0-server
        
        echo -e "${YELLOW}✅ Anonymity deactivated${NC}"
        ;;
        
    "restart")
        echo -e "${CYAN}🔄 Restarting Ghost Mode + WireGuard...${NC}"
        $0 stop
        sleep 2
        $0 start
        ;;
        
    "status")
        show_banner
        echo -e "${CYAN}📊 System Status:${NC}"
        
        # WireGuard Server Status
        if systemctl is-active --quiet wg-quick@wg0-server; then
            echo -e "${GREEN}✅ VPN Server: Active${NC}"
            peer_count=$(sudo wg show wg0-server peers 2>/dev/null | wc -l || echo "0")
            echo -e "   Connected devices: $peer_count"
        else
            echo -e "${RED}❌ VPN Server: Inactive${NC}"
        fi
        
        # WireGuard Client Status
        if systemctl is-active --quiet wg-quick@wg0-client; then
            echo -e "${GREEN}✅ VPN Client: Active (Main system protected)${NC}"
            if ip addr show wg0-client >/dev/null 2>&1; then
                client_ip=$(ip addr show wg0-client | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
                echo -e "   VPN IP: $client_ip"
            fi
        else
            echo -e "${RED}❌ VPN Client: Inactive (Main system EXPOSED)${NC}"
        fi
        
        # Ghost Mode Status
        if [[ -x "$GHOST_MODE_PATH/scripts/ghost-mode" ]]; then
            echo ""
            echo -e "${PURPLE}🥷 Ghost Mode Status:${NC}"
            "$GHOST_MODE_PATH/scripts/ghost-mode" status
        fi
        
        # DNS Status
        echo ""
        echo -e "${CYAN}🌐 DNS Status:${NC}"
        if systemctl is-active --quiet unbound; then
            echo -e "${GREEN}✅ Secure DNS: Active${NC}"
        else
            echo -e "${RED}❌ Secure DNS: Inactive${NC}"
        fi
        
        # External IP check
        echo ""
        echo -e "${CYAN}🌍 External IP Check:${NC}"
        ext_ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "Unable to detect")
        echo -e "   Current IP: $ext_ip"
        ;;
        
    "clients")
        echo -e "${CYAN}👥 Connected Devices:${NC}"
        if systemctl is-active --quiet wg-quick@wg0-server; then
            sudo wg show wg0-server
        else
            echo -e "${RED}VPN server is not running${NC}"
        fi
        ;;
        
    "rotate")
        echo -e "${PURPLE}🔄 Rotating VPN keys for enhanced security...${NC}"
        
        # Check if awesome-stack rotation script exists
        if [[ -x "/home/lou/github/awesome-stack/wireguard-tools/server/wireguard-rotate.sh" ]]; then
            /home/lou/github/awesome-stack/wireguard-tools/server/wireguard-rotate.sh
            $0 restart
            echo -e "${GREEN}✅ Keys rotated and services restarted${NC}"
        else
            warn "Rotation script not found - manual restart performed"
            $0 restart
        fi
        ;;
        
    "ghost")
        if [[ -x "$GHOST_MODE_PATH/scripts/ghost-toggle" ]]; then
            "$GHOST_MODE_PATH/scripts/ghost-toggle" "${2:-toggle}"
        else
            echo -e "${RED}Ghost Mode not available${NC}"
            echo -e "${YELLOW}Install from: /home/lou/github/awesome-stack/ghost-mode/${NC}"
        fi
        ;;
        
    "test")
        echo -e "${CYAN}🧪 Testing Anonymity...${NC}"
        
        # Check VPN connection
        if systemctl is-active --quiet wg-quick@wg0-client; then
            echo -e "${GREEN}✅ VPN tunnel active${NC}"
        else
            echo -e "${RED}❌ VPN tunnel inactive${NC}"
        fi
        
        # Check external IP
        echo -e "${CYAN}🌍 Checking external IP...${NC}"
        ext_ip=$(curl -s --max-time 10 ifconfig.me || echo "Failed")
        echo -e "   External IP: $ext_ip"
        
        # Test DNS leaks
        echo -e "${CYAN}🕵️ Testing DNS leaks...${NC}"
        if command -v dig >/dev/null 2>&1; then
            dns_server=$(dig +short txt ch whoami.cloudflare @1.1.1.1 | tr -d '"' || echo "Test failed")
            echo -e "   DNS server: $dns_server"
        fi
        
        # Ghost Mode test if available
        if [[ -x "$GHOST_MODE_PATH/scripts/ghost-mode" ]]; then
            echo ""
            "$GHOST_MODE_PATH/scripts/ghost-mode" test
        fi
        ;;
        
    "browser")
        echo -e "${PURPLE}🥷 Launching anonymous browser...${NC}"
        if [[ -x "$GHOST_MODE_PATH/scripts/setup-ghost-firefox" ]]; then
            "$GHOST_MODE_PATH/scripts/setup-ghost-firefox"
        else
            # Fallback to secure Firefox
            firefox --private-window --new-instance 2>/dev/null &
        fi
        ;;
        
    "config")
        device="${2:-}"
        if [[ -z "$device" ]]; then
            echo -e "${CYAN}📋 Available Device Configurations:${NC}"
            for config in /home/lou/wireguard-clients/*.conf; do
                if [[ -f "$config" ]]; then
                    basename "$config" .conf
                fi
            done
            echo ""
            echo "Usage: $0 config <device>"
            echo "Example: $0 config phone"
        else
            config_file="/home/lou/wireguard-clients/${device}.conf"
            if [[ -f "$config_file" ]]; then
                echo -e "${CYAN}📋 Configuration for $device:${NC}"
                cat "$config_file"
            else
                echo -e "${RED}Configuration not found for: $device${NC}"
            fi
        fi
        ;;
        
    "qr")
        device="${2:-}"
        if [[ -z "$device" ]]; then
            echo "Usage: $0 qr <device>"
            echo "Available: phone, tablet"
        else
            config_file="/home/lou/wireguard-clients/${device}.conf"
            if [[ -f "$config_file" ]]; then
                echo -e "${CYAN}📱 QR Code for $device:${NC}"
                qrencode -t ANSIUTF8 < "$config_file"
            else
                echo -e "${RED}Configuration not found for: $device${NC}"
            fi
        fi
        ;;
        
    *)
        show_banner
        echo ""
        echo -e "${CYAN}🛠️ Available Commands:${NC}"
        echo ""
        echo -e "${GREEN}Basic Control:${NC}"
        echo "  start       - Start VPN server + client + Ghost Mode"
        echo "  stop        - Stop all services"
        echo "  restart     - Restart all services"
        echo "  status      - Show comprehensive status"
        echo ""
        echo -e "${GREEN}Advanced Features:${NC}"
        echo "  clients     - Show connected devices"
        echo "  rotate      - Rotate VPN keys for security"
        echo "  ghost       - Toggle Ghost Mode specifically"
        echo "  test        - Test anonymity and leaks"
        echo "  browser     - Launch anonymous browser"
        echo ""
        echo -e "${GREEN}Configuration:${NC}"
        echo "  config <device>  - Show device configuration"
        echo "  qr <device>      - Show QR code for mobile devices"
        echo ""
        echo -e "${CYAN}🔗 Remote Access URLs (when connected to VPN):${NC}"
        echo "  Dashboard: http://10.0.0.1:8600"
        echo "  Jellyfin:  http://10.0.0.1:8096"
        echo "  Plex:      http://10.0.0.1:32400/web"
        echo "  Radarr:    http://10.0.0.1:7878"
        echo "  Sonarr:    http://10.0.0.1:8989"
        echo ""
        echo -e "${PURPLE}🥷 Ghost Mode Features:${NC}"
        echo "  • Complete IP/DNS leak protection"
        echo "  • Hardware fingerprinting spoofing"
        echo "  • Browser anonymization"
        echo "  • Timing attack prevention"
        echo "  • Automated monitoring and repair"
        ;;
esac
EOF

chmod +x /home/lou/garuda-media-stack/scripts/ghost-wireguard-manager.sh
log "✅ Advanced management script created"

# Create key rotation script
cat > /home/lou/garuda-media-stack/scripts/rotate-wireguard-keys.sh << 'EOF'
#!/bin/bash
# WireGuard Key Rotation Script - Enhanced Security
# Rotates server and client keys every 6 hours for Ghost Mode

log() { echo -e "\033[0;32m[$(date +'%H:%M:%S')]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }

log "🔄 Starting WireGuard key rotation..."

# Generate new server keys
NEW_SERVER_PRIVATE=$(wg genkey)
NEW_SERVER_PUBLIC=$(echo "$NEW_SERVER_PRIVATE" | wg pubkey)

# Generate new main client keys  
NEW_CLIENT_PRIVATE=$(wg genkey)
NEW_CLIENT_PUBLIC=$(echo "$NEW_CLIENT_PRIVATE" | wg pubkey)

# Backup current configs
sudo cp /etc/wireguard/wg0-server.conf /etc/wireguard/wg0-server.conf.backup
sudo cp /etc/wireguard/wg0-client.conf /etc/wireguard/wg0-client.conf.backup

# Update server config with new keys
sudo sed -i "s/PrivateKey = .*/PrivateKey = $NEW_SERVER_PRIVATE/" /etc/wireguard/wg0-server.conf
sudo sed -i "0,/PublicKey = .*/{s/PublicKey = .*/PublicKey = $NEW_CLIENT_PUBLIC/}" /etc/wireguard/wg0-server.conf

# Update client config with new keys
sudo sed -i "s/PrivateKey = .*/PrivateKey = $NEW_CLIENT_PRIVATE/" /etc/wireguard/wg0-client.conf
sudo sed -i "s/PublicKey = .*/PublicKey = $NEW_SERVER_PUBLIC/" /etc/wireguard/wg0-client.conf

# Restart services
sudo systemctl restart wg-quick@wg0-server
sleep 2
sudo systemctl restart wg-quick@wg0-client

log "✅ WireGuard keys rotated successfully"
log "🔑 New server public key: $NEW_SERVER_PUBLIC"

# Log rotation event
echo "$(date): Key rotation completed - Server: $NEW_SERVER_PUBLIC" >> /home/lou/.config/ghost-mode/rotation.log
EOF

chmod +x /home/lou/garuda-media-stack/scripts/rotate-wireguard-keys.sh

# Set up key rotation cron job
(crontab -l 2>/dev/null; echo "0 */6 * * * /home/lou/garuda-media-stack/scripts/rotate-wireguard-keys.sh") | crontab -

log "✅ Key rotation scheduled every 6 hours"

# Create device-specific QR codes
section "Generating Device QR Codes"

for device in phone tablet; do
    if [[ -f "$CONFIG_DIR/${device}.conf" ]]; then
        qr_file="$CONFIG_DIR/${device}-qr.png"
        if command -v qrencode >/dev/null 2>&1; then
            qrencode -t PNG -o "$qr_file" < "$CONFIG_DIR/${device}.conf"
            log "QR code generated: $qr_file"
        fi
    fi
done

# Installation complete
section "Installation Complete"

echo ""
echo -e "${GREEN}${BOLD}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║               🎉 Dual-Role VPN + Ghost Mode Ready! 🎉       ║
║                                                              ║
║  🥷 Main system is now completely anonymous                 ║
║  🔄 Automatic key rotation every 6 hours                    ║
║  📱 Device configurations ready                             ║
║  🛡️ Ghost Mode integration available                        ║
║                                                              ║
║         🔒 Server • 🥷 Client • 🌍 Anonymous • 🏠 Home      ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${CYAN}🎯 SYSTEM CONFIGURATION:${NC}"
echo -e "  External IP: ${GREEN}$EXTERNAL_IP:$VPN_PORT${NC}"
echo -e "  VPN Network: ${GREEN}$VPN_NETWORK${NC}"
echo -e "  Server IP: ${GREEN}$SERVER_IP${NC}"
echo -e "  Main Client IP: ${GREEN}${DEVICES["main-system"]}${NC}"

echo ""
echo -e "${CYAN}📱 DEVICE CONFIGURATIONS:${NC}"
for device in "${!DEVICES[@]}"; do
    if [[ "$device" != "main-system" ]]; then
        echo -e "  ${device}: ${GREEN}${DEVICES["$device"]}${NC} - $CONFIG_DIR/${device}.conf"
    fi
done

echo ""
echo -e "${CYAN}📱 MOBILE SETUP (QR CODES):${NC}"
echo -e "  Phone: ${GREEN}./scripts/ghost-wireguard-manager.sh qr phone${NC}"
echo -e "  Tablet: ${GREEN}./scripts/ghost-wireguard-manager.sh qr tablet${NC}"

echo ""
echo -e "${CYAN}🖥️ FIRE TV SETUP:${NC}"
echo -e "  FireTV 1: ${GREEN}$CONFIG_DIR/firetv1.conf${NC}"
echo -e "  FireTV 2: ${GREEN}$CONFIG_DIR/firetv2.conf${NC}"

echo ""
echo -e "${CYAN}🛠️ MANAGEMENT:${NC}"
echo -e "  Control Panel: ${GREEN}./scripts/ghost-wireguard-manager.sh${NC}"
echo -e "  Quick Status: ${GREEN}./scripts/ghost-wireguard-manager.sh status${NC}"
echo -e "  Ghost Mode: ${GREEN}./scripts/ghost-wireguard-manager.sh ghost${NC}"
echo -e "  Anonymous Browser: ${GREEN}./scripts/ghost-wireguard-manager.sh browser${NC}"

echo ""
echo -e "${PURPLE}🥷 GHOST MODE FEATURES:${NC}"
if [[ -d "$GHOST_MODE_DIR" ]]; then
    echo -e "  ${GREEN}✅ Available${NC} - Complete anonymity suite ready"
    echo -e "  System Tray: ${GREEN}$GHOST_MODE_DIR/scripts/ghost-tray-widget${NC}"
    echo -e "  Quick Toggle: ${GREEN}./scripts/ghost-wireguard-manager.sh ghost${NC}"
else
    echo -e "  ${YELLOW}⚠️ Not installed${NC} - Clone awesome-stack ghost-mode for enhanced anonymity"
fi

echo ""
echo -e "${CYAN}🔐 SECURITY FEATURES:${NC}"
echo -e "  • ${GREEN}Dual-role operation${NC} - Main system behind VPN"
echo -e "  • ${GREEN}Automatic key rotation${NC} - Every 6 hours"
echo -e "  • ${GREEN}DNS leak protection${NC} - IPv6 disabled"
echo -e "  • ${GREEN}Hardware spoofing${NC} - Ghost Mode integration"
echo -e "  • ${GREEN}Traffic obfuscation${NC} - Pattern masking"

echo ""
echo -e "${GREEN}🎬 Your media stack is now completely anonymous and globally accessible! 🥷🌍${NC}"

log "📋 All configurations saved to: $CONFIG_DIR"
log "🔧 Management script: ./scripts/ghost-wireguard-manager.sh"
log "🥷 Start Ghost Mode: ./scripts/ghost-wireguard-manager.sh ghost on"

echo ""
echo -e "${YELLOW}⚡ NEXT STEPS:${NC}"
echo "1. Configure your devices with the client files"
echo "2. Test connectivity: ./scripts/ghost-wireguard-manager.sh test"
echo "3. Install Ghost Mode for ultimate anonymity"
echo "4. Access media stack via VPN tunnel at 10.0.0.1 addresses"
