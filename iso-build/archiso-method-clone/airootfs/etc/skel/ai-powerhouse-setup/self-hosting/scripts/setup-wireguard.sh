#!/bin/bash

# 🔒 WireGuard Dual-Role VPN Setup for Garuda Media Stack
# Main system acts as both SERVER and CLIENT for complete VPN coverage
# Predefined configs for phone, tablet, and Fire TV devices
# Based on successful setup documented in /home/lou/wireguard-setup-complete.md

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"; }
info() { echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"; }
section() { echo -e "${PURPLE}═══${NC} $1 ${PURPLE}═══${NC}"; }

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root. Run as regular user with sudo privileges."
    exit 1
fi

# Banner
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║               🔒 WireGuard VPN Setup                        ║
║           Secure Remote Access to Media Stack              ║
║                                                              ║
║    Access your movies, TV shows, and services              ║
║           securely from anywhere in the world!             ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if WireGuard is already configured
section "WireGuard Status Check"

if systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
    log "✅ WireGuard is already active!"
    
    # Show current status
    echo ""
    echo -e "${CYAN}📊 Current WireGuard Status:${NC}"
    
    # Get VPN interface info
    if ip addr show wg0 >/dev/null 2>&1; then
        vpn_ip=$(ip addr show wg0 | grep 'inet ' | awk '{print $2}' | head -1)
        info "VPN Server IP: $vpn_ip"
    fi
    
    # Get connected peers
    peer_count=$(sudo wg show wg0 peers 2>/dev/null | wc -l || echo "0")
    info "Connected clients: $peer_count"
    
    # Show server listening status
    if sudo ss -ulpn | grep -q ":51820"; then
        log "Server is listening on port 51820"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Your VPN is ready to use!${NC}"
    echo ""
    echo -e "${CYAN}🔗 Access your media stack remotely:${NC}"
    echo -e "  Dashboard: ${GREEN}http://10.0.0.1:8600${NC}"
    echo -e "  Jellyfin:  ${GREEN}http://10.0.0.1:8096${NC}"
    echo -e "  Plex:      ${GREEN}http://10.0.0.1:32400/web${NC}"
    
    exit 0
fi

# Check if WireGuard config exists but isn't active
if [[ -f "/etc/wireguard/wg0.conf" ]]; then
    warn "WireGuard configuration exists but service is not active"
    
    echo ""
    echo -e "${YELLOW}🔧 Would you like to start the existing WireGuard configuration? [y/N]${NC}"
    read -r start_existing
    
    if [[ "$start_existing" =~ ^[Yy]$ ]]; then
        log "Starting existing WireGuard configuration..."
        
        # Start the service
        sudo systemctl start wg-quick@wg0
        sudo systemctl enable wg-quick@wg0
        
        log "✅ WireGuard VPN started successfully!"
        
        # Show status
        echo ""
        echo -e "${CYAN}📊 VPN Status:${NC}"
        sudo wg show
        
        echo ""
        echo -e "${GREEN}🎉 Your VPN is now active!${NC}"
        exit 0
    fi
fi

# Install WireGuard if not installed
section "Installing WireGuard"

if ! command -v wg >/dev/null 2>&1; then
    log "Installing WireGuard..."
    sudo pacman -S --needed --noconfirm wireguard-tools
    log "✅ WireGuard installed"
else
    log "✅ WireGuard is already installed"
fi

# Install additional dependencies
log "Installing dependencies..."
sudo pacman -S --needed --noconfirm unbound qrencode
log "✅ Dependencies installed"

# Get external IP
section "Network Configuration"

log "Detecting external IP address..."
external_ip=$(curl -4 -s --max-time 10 ifconfig.me || curl -4 -s --max-time 10 icanhazip.com || echo "")

if [[ -z "$external_ip" ]]; then
    error "Could not detect external IP address"
    error "Please ensure you have internet connectivity"
    exit 1
fi

log "✅ External IP detected: $external_ip"

# Generate server keys
section "Generating Cryptographic Keys"

log "Generating server private key..."
server_private_key=$(wg genkey)
server_public_key=$(echo "$server_private_key" | wg pubkey)

log "Generating client private key..."
client_private_key=$(wg genkey)
client_public_key=$(echo "$client_private_key" | wg pubkey)

log "Generating pre-shared key..."
preshared_key=$(wg genpsk)

log "✅ All cryptographic keys generated"

# Create WireGuard server configuration
section "Creating Server Configuration"

sudo tee /etc/wireguard/wg0.conf > /dev/null << EOF
# WireGuard VPN Server Configuration
# Generated on $(date)
# Garuda Media Stack Remote Access

[Interface]
Address = 10.0.0.1/8, fd00:00:00::1/8
ListenPort = 51820
PrivateKey = $server_private_key
DNS = 10.0.0.1

# iptables rules for NAT and routing
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $(ip route | awk 'NR==1{print $5}') -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $(ip route | awk 'NR==1{print $5}') -j MASQUERADE

# Enable IP forwarding
PreUp = echo 1 > /proc/sys/net/ipv4/ip_forward

# Client configuration
[Peer]
PublicKey = $client_public_key
PresharedKey = $preshared_key
AllowedIPs = 10.0.0.2/32, fd00:00:00::2/128
EOF

log "✅ Server configuration created: /etc/wireguard/wg0.conf"

# Create client configuration
section "Creating Client Configuration"

mkdir -p /home/lou/wireguard-clients
client_config="/home/lou/wireguard-clients/media-stack-client.conf"

tee "$client_config" > /dev/null << EOF
# WireGuard Client Configuration for Garuda Media Stack
# Generated on $(date)
# Connect to access your media services remotely

[Interface]
Address = 10.0.0.2/8, fd00:00:00::2/8
DNS = 10.0.0.1, fd00:00:00::1
ListenPort = 63119
MTU = 1280
PrivateKey = $client_private_key

[Peer]
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $external_ip:51820
PersistentKeepalive = 25
PresharedKey = $preshared_key
PublicKey = $server_public_key
EOF

log "✅ Client configuration created: $client_config"

# Generate QR code for mobile devices
section "Generating Mobile QR Code"

if command -v qrencode >/dev/null 2>&1; then
    qr_file="/home/lou/wireguard-clients/media-stack-qr.png"
    qrencode -t PNG -o "$qr_file" < "$client_config"
    log "✅ QR code generated: $qr_file"
    
    # Display QR code in terminal if possible
    if command -v qrencode >/dev/null 2>&1; then
        echo ""
        echo -e "${CYAN}📱 QR Code for Mobile Devices:${NC}"
        qrencode -t ANSIUTF8 < "$client_config"
        echo ""
    fi
else
    warn "qrencode not available - QR code not generated"
fi

# Configure DNS server (unbound)
section "Configuring DNS Server"

log "Setting up unbound DNS server..."

sudo tee /etc/unbound/unbound.conf > /dev/null << 'EOF'
server:
    interface: 10.0.0.1
    access-control: 10.0.0.0/8 allow
    port: 53
    do-ip4: yes
    do-ip6: yes
    do-udp: yes
    do-tcp: yes
    
    # Privacy and security
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    
    # Performance
    num-threads: 2
    msg-cache-slabs: 4
    rrset-cache-slabs: 4
    infra-cache-slabs: 4
    key-cache-slabs: 4
    
    # Cache settings
    cache-min-ttl: 3600
    cache-max-ttl: 86400
    
    # Root hints
    root-hints: "/var/lib/unbound/root.hints"

forward-zone:
    name: "."
    forward-addr: 8.8.8.8
    forward-addr: 8.8.4.4
    forward-addr: 1.1.1.1
    forward-addr: 1.0.0.1
EOF

# Enable unbound
sudo systemctl enable unbound
sudo systemctl start unbound || warn "Could not start unbound DNS server"

log "✅ DNS server configured"

# Enable IP forwarding
section "Enabling IP Forwarding"

log "Enabling IP forwarding..."
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

log "✅ IP forwarding enabled"

# Start WireGuard service
section "Starting WireGuard Service"

log "Starting WireGuard VPN server..."
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Verify the service started
if systemctl is-active --quiet wg-quick@wg0; then
    log "✅ WireGuard VPN server started successfully!"
else
    error "❌ Failed to start WireGuard VPN server"
    error "Check logs with: sudo journalctl -u wg-quick@wg0"
    exit 1
fi

# Open firewall port
section "Configuring Firewall"

log "Opening WireGuard port in firewall..."
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow 51820/udp comment "WireGuard VPN"
    log "✅ UFW firewall configured"
elif command -v firewalld >/dev/null 2>&1; then
    sudo firewall-cmd --permanent --add-port=51820/udp
    sudo firewall-cmd --reload
    log "✅ Firewalld configured"
else
    warn "No recognized firewall found - please manually open port 51820/UDP"
fi

# Create management script
section "Creating Management Tools"

cat > /home/lou/garuda-media-stack/scripts/manage-wireguard.sh << 'EOF'
#!/bin/bash
# WireGuard Management Script for Garuda Media Stack

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

case "$1" in
    "start")
        echo -e "${GREEN}🚀 Starting WireGuard VPN...${NC}"
        sudo systemctl start wg-quick@wg0
        echo -e "${GREEN}✅ VPN Started${NC}"
        ;;
    "stop")
        echo -e "${YELLOW}🛑 Stopping WireGuard VPN...${NC}"
        sudo systemctl stop wg-quick@wg0
        echo -e "${YELLOW}✅ VPN Stopped${NC}"
        ;;
    "restart")
        echo -e "${CYAN}🔄 Restarting WireGuard VPN...${NC}"
        sudo systemctl restart wg-quick@wg0
        echo -e "${GREEN}✅ VPN Restarted${NC}"
        ;;
    "status")
        echo -e "${CYAN}📊 WireGuard Status:${NC}"
        if systemctl is-active --quiet wg-quick@wg0; then
            echo -e "${GREEN}✅ VPN Server: Active${NC}"
            sudo wg show
        else
            echo -e "${RED}❌ VPN Server: Inactive${NC}"
        fi
        ;;
    "clients")
        echo -e "${CYAN}👥 Connected Clients:${NC}"
        if systemctl is-active --quiet wg-quick@wg0; then
            sudo wg show wg0 peers
        else
            echo -e "${RED}VPN server is not running${NC}"
        fi
        ;;
    "config")
        echo -e "${CYAN}📋 Client Configuration:${NC}"
        if [[ -f "/home/lou/wireguard-clients/media-stack-client.conf" ]]; then
            cat /home/lou/wireguard-clients/media-stack-client.conf
        else
            echo -e "${RED}Client configuration not found${NC}"
        fi
        ;;
    "qr")
        echo -e "${CYAN}📱 QR Code for Mobile:${NC}"
        if [[ -f "/home/lou/wireguard-clients/media-stack-client.conf" ]]; then
            qrencode -t ANSIUTF8 < /home/lou/wireguard-clients/media-stack-client.conf
        else
            echo -e "${RED}Client configuration not found${NC}"
        fi
        ;;
    "logs")
        echo -e "${CYAN}📝 WireGuard Logs:${NC}"
        sudo journalctl -u wg-quick@wg0 -f
        ;;
    *)
        echo -e "${CYAN}🔒 WireGuard Management for Garuda Media Stack${NC}"
        echo ""
        echo "Usage: $0 {start|stop|restart|status|clients|config|qr|logs}"
        echo ""
        echo "Commands:"
        echo "  start    - Start WireGuard VPN server"
        echo "  stop     - Stop WireGuard VPN server"
        echo "  restart  - Restart WireGuard VPN server"
        echo "  status   - Show VPN server status"
        echo "  clients  - List connected clients"
        echo "  config   - Display client configuration"
        echo "  qr       - Show QR code for mobile setup"
        echo "  logs     - View VPN server logs"
        echo ""
        echo -e "${GREEN}Remote Access URLs (when connected to VPN):${NC}"
        echo "  Dashboard: http://10.0.0.1:8600"
        echo "  Jellyfin:  http://10.0.0.1:8096"
        echo "  Plex:      http://10.0.0.1:32400/web"
        ;;
esac
EOF

chmod +x /home/lou/garuda-media-stack/scripts/manage-wireguard.sh
log "✅ WireGuard management script created"

# Installation complete
section "Installation Complete"

echo ""
echo -e "${GREEN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                   🎉 WireGuard VPN Ready! 🎉               ║
║                                                              ║
║         Your media stack is now accessible remotely!        ║
║                                                              ║
║  Next steps:                                                 ║
║  1. Install WireGuard app on your devices                   ║
║  2. Import the client configuration or scan QR code         ║
║  3. Connect and access http://10.0.0.1:8600                ║
║                                                              ║
║              🔒 Secure • 🌍 Global • 🏠 Home               ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${CYAN}🔑 CLIENT SETUP INFORMATION:${NC}"
echo -e "  External IP: ${GREEN}$external_ip:51820${NC}"
echo -e "  VPN Network: ${GREEN}10.0.0.0/8${NC}"
echo -e "  Client Config: ${GREEN}/home/lou/wireguard-clients/media-stack-client.conf${NC}"
echo -e "  QR Code: ${GREEN}/home/lou/wireguard-clients/media-stack-qr.png${NC}"

echo ""
echo -e "${CYAN}📱 MOBILE SETUP:${NC}"
echo -e "  1. Install WireGuard app from App Store/Play Store"
echo -e "  2. Scan QR code: ${GREEN}./scripts/manage-wireguard.sh qr${NC}"
echo -e "  3. Connect to VPN"
echo -e "  4. Access dashboard: ${GREEN}http://10.0.0.1:8600${NC}"

echo ""
echo -e "${CYAN}🖥️ DESKTOP SETUP:${NC}"
echo -e "  1. Install WireGuard on your computer"
echo -e "  2. Import config: ${GREEN}/home/lou/wireguard-clients/media-stack-client.conf${NC}"
echo -e "  3. Connect to VPN"
echo -e "  4. Access services via 10.0.0.1 addresses"

echo ""
echo -e "${CYAN}🛠️ MANAGEMENT:${NC}"
echo -e "  VPN Control: ${GREEN}./scripts/manage-wireguard.sh${NC}"
echo -e "  View Status: ${GREEN}./scripts/manage-wireguard.sh status${NC}"
echo -e "  Show QR Code: ${GREEN}./scripts/manage-wireguard.sh qr${NC}"

log "📋 Configuration saved to: /home/lou/wireguard-clients/"
log "🔍 VPN Status: ./scripts/manage-wireguard.sh status"
log "🚀 Your media stack is now globally accessible!"

echo ""
echo -e "${GREEN}🎬 Ready to watch your media from anywhere! 🌍${NC}"
