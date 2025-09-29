#!/bin/bash

# 🎯 Automated Client Generator for WireGuard VPN
# Creates additional client configurations for family/friends
# Part of Garuda Media Stack

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

# Configuration
WIREGUARD_CONFIG="/etc/wireguard/wg0.conf"
CLIENT_DIR="/home/lou/wireguard-clients"
SERVER_PUBLIC_KEY=""
PRESHARED_KEY=""
EXTERNAL_IP=""

# Check if WireGuard server is configured
if [[ ! -f "$WIREGUARD_CONFIG" ]]; then
    error "WireGuard server not configured. Run setup-wireguard.sh first."
    exit 1
fi

# Extract server details
SERVER_PUBLIC_KEY=$(sudo grep "PrivateKey" "$WIREGUARD_CONFIG" | cut -d' ' -f3 | wg pubkey)
EXTERNAL_IP=$(grep "Endpoint" "$CLIENT_DIR/media-stack-client.conf" 2>/dev/null | cut -d' ' -f3 | cut -d':' -f1 || echo "")

if [[ -z "$EXTERNAL_IP" ]]; then
    log "Detecting external IP address..."
    EXTERNAL_IP=$(curl -4 -s --max-time 10 ifconfig.me || curl -4 -s --max-time 10 icanhazip.com || echo "")
    if [[ -z "$EXTERNAL_IP" ]]; then
        error "Could not detect external IP address"
        exit 1
    fi
fi

# Function to get next available IP
get_next_ip() {
    local used_ips
    used_ips=$(sudo grep -E "AllowedIPs.*10\.0\.0\." "$WIREGUARD_CONFIG" | grep -oE "10\.0\.0\.[0-9]+" | sort -V)
    
    for i in {2..254}; do
        if ! echo "$used_ips" | grep -q "10.0.0.$i"; then
            echo "10.0.0.$i"
            return
        fi
    done
    
    error "No available IP addresses in range 10.0.0.2-254"
    exit 1
}

# Function to create client configuration
create_client() {
    local client_name="$1"
    local client_ip="$2"
    local client_private_key client_public_key preshared_key
    
    log "Creating client: $client_name"
    
    # Generate client keys
    client_private_key=$(wg genkey)
    client_public_key=$(echo "$client_private_key" | wg pubkey)
    preshared_key=$(wg genpsk)
    
    # Create client config file
    local client_config="$CLIENT_DIR/${client_name}.conf"
    
    tee "$client_config" > /dev/null << EOF
# WireGuard Client Configuration: $client_name
# Generated on $(date)
# Garuda Media Stack Remote Access

[Interface]
Address = ${client_ip}/8
DNS = 10.0.0.1
ListenPort = 63119
MTU = 1280
PrivateKey = $client_private_key

[Peer]
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $EXTERNAL_IP:51820
PersistentKeepalive = 25
PresharedKey = $preshared_key
PublicKey = $SERVER_PUBLIC_KEY
EOF
    
    # Generate QR code
    local qr_file="$CLIENT_DIR/${client_name}-qr.png"
    if command -v qrencode >/dev/null 2>&1; then
        qrencode -t PNG -o "$qr_file" < "$client_config"
        log "QR code: $qr_file"
    fi
    
    # Add peer to server configuration
    sudo tee -a "$WIREGUARD_CONFIG" > /dev/null << EOF

# Client: $client_name
[Peer]
PublicKey = $client_public_key
PresharedKey = $preshared_key
AllowedIPs = ${client_ip}/32
EOF
    
    log "✅ Client '$client_name' created with IP $client_ip"
    
    return 0
}

# Function to remove client
remove_client() {
    local client_name="$1"
    local client_config="$CLIENT_DIR/${client_name}.conf"
    
    if [[ ! -f "$client_config" ]]; then
        error "Client '$client_name' not found"
        return 1
    fi
    
    # Get client public key
    local client_public_key
    client_public_key=$(grep "PrivateKey" "$client_config" | cut -d' ' -f3 | wg pubkey)
    
    # Remove from server config
    sudo sed -i "/# Client: $client_name/,/^$/d" "$WIREGUARD_CONFIG"
    
    # Remove client files
    rm -f "$client_config"
    rm -f "$CLIENT_DIR/${client_name}-qr.png"
    
    log "✅ Client '$client_name' removed"
}

# Function to list clients
list_clients() {
    echo -e "${CYAN}📋 Configured Clients:${NC}"
    
    if [[ ! -d "$CLIENT_DIR" ]]; then
        warn "No client directory found"
        return 1
    fi
    
    local count=0
    for config in "$CLIENT_DIR"/*.conf; do
        if [[ -f "$config" ]]; then
            local client_name
            client_name=$(basename "$config" .conf)
            local client_ip
            client_ip=$(grep "Address" "$config" | cut -d' ' -f3 | cut -d'/' -f1)
            
            echo -e "  ${GREEN}$client_name${NC} - IP: $client_ip"
            ((count++))
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        warn "No client configurations found"
    else
        info "Total clients: $count"
    fi
}

# Function to show client QR code
show_qr() {
    local client_name="$1"
    local client_config="$CLIENT_DIR/${client_name}.conf"
    
    if [[ ! -f "$client_config" ]]; then
        error "Client '$client_name' not found"
        return 1
    fi
    
    echo -e "${CYAN}📱 QR Code for '$client_name':${NC}"
    if command -v qrencode >/dev/null 2>&1; then
        qrencode -t ANSIUTF8 < "$client_config"
    else
        error "qrencode not installed"
        return 1
    fi
}

# Function to restart WireGuard service
restart_service() {
    log "Restarting WireGuard service to apply changes..."
    sudo systemctl restart wg-quick@wg0
    
    if systemctl is-active --quiet wg-quick@wg0; then
        log "✅ WireGuard service restarted successfully"
    else
        error "❌ Failed to restart WireGuard service"
        return 1
    fi
}

# Main menu
show_menu() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║            🎯 WireGuard Client Manager                      ║
║                Garuda Media Stack                           ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo "Available commands:"
    echo "  add <name>       - Create new client configuration"
    echo "  remove <name>    - Remove client configuration"
    echo "  list            - List all clients"
    echo "  qr <name>       - Show QR code for client"
    echo "  restart         - Restart WireGuard service"
    echo "  help            - Show this help"
    echo ""
}

# Ensure client directory exists
mkdir -p "$CLIENT_DIR"

# Main command handling
case "${1:-help}" in
    "add")
        if [[ -z "${2:-}" ]]; then
            error "Please specify a client name: $0 add <name>"
            exit 1
        fi
        
        client_name="$2"
        client_ip=$(get_next_ip)
        
        echo -e "${CYAN}🔑 Creating new client: $client_name${NC}"
        create_client "$client_name" "$client_ip"
        
        echo ""
        echo -e "${GREEN}✅ Client created successfully!${NC}"
        echo -e "  Config file: ${GREEN}$CLIENT_DIR/${client_name}.conf${NC}"
        echo -e "  QR code: ${GREEN}$CLIENT_DIR/${client_name}-qr.png${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  Restart WireGuard to activate: ${GREEN}$0 restart${NC}"
        ;;
        
    "remove")
        if [[ -z "${2:-}" ]]; then
            error "Please specify a client name: $0 remove <name>"
            exit 1
        fi
        
        client_name="$2"
        echo -e "${YELLOW}🗑️ Removing client: $client_name${NC}"
        remove_client "$client_name"
        
        echo ""
        echo -e "${YELLOW}⚠️  Restart WireGuard to apply changes: ${GREEN}$0 restart${NC}"
        ;;
        
    "list")
        list_clients
        ;;
        
    "qr")
        if [[ -z "${2:-}" ]]; then
            error "Please specify a client name: $0 qr <name>"
            exit 1
        fi
        
        show_qr "$2"
        ;;
        
    "restart")
        restart_service
        ;;
        
    "help"|*)
        show_menu
        ;;
esac

echo ""
echo -e "${BLUE}💡 Tip: Use './scripts/manage-wireguard.sh status' to check VPN server status${NC}"
