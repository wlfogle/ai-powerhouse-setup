#!/bin/bash

# 🛡️ WIREGUARD GHOST MODE DUAL-ROLE SETUP
# Complete WireGuard server/client with Ghost Mode integration
# Supports automatic rotation, API masking, and device-specific configurations

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WG_CONFIG_DIR="/etc/wireguard"
GHOST_CONFIG_DIR="/opt/ghost-mode"
CLIENT_CONFIG_DIR="$WG_CONFIG_DIR/clients"
LOG_FILE="/var/log/wireguard-setup.log"

# Device configurations from router settings
declare -A DEVICES=(
    ["phone-android3"]="192.168.12.207:10.0.0.10"
    ["phone-android4"]="192.168.12.142:10.0.0.11" 
    ["tablet-jackie"]="192.168.12.126:10.0.0.12"
    ["firetv-living"]="192.168.12.100:10.0.0.13"
    ["firetv-bedroom"]="192.168.12.219:10.0.0.14"
    ["garuda-main"]="192.168.12.172:10.0.0.15"
    ["garuda-alt"]="192.168.12.204:10.0.0.16"
)

# External server IP (from wireguard-setup-complete.md)
EXTERNAL_SERVER_IP="172.59.85.76"
WG_PORT="51820"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log() { 
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}
warn() { 
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}
error() { 
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

# Generate key pairs
generate_keys() {
    local name="$1"
    local private_key=$(wg genkey)
    local public_key=$(echo "$private_key" | wg pubkey)
    local preshared_key=$(wg genpsk)
    
    echo "$private_key:$public_key:$preshared_key"
}

# Setup WireGuard server configuration
setup_server_config() {
    log "Setting up WireGuard server configuration..."
    
    # Generate server keys
    SERVER_KEYS=$(generate_keys "server")
    SERVER_PRIVATE=$(echo "$SERVER_KEYS" | cut -d: -f1)
    SERVER_PUBLIC=$(echo "$SERVER_KEYS" | cut -d: -f2)
    
    # Create server configuration
    sudo mkdir -p "$WG_CONFIG_DIR"
    sudo tee "$WG_CONFIG_DIR/wg0.conf" > /dev/null << EOF
# WireGuard Server Configuration with Ghost Mode Integration
# Auto-generated on $(date)

[Interface]
PrivateKey = $SERVER_PRIVATE
Address = 10.0.0.1/24
ListenPort = $WG_PORT
SaveConfig = false

# Firewall rules for media stack access
PostUp = iptables -A FORWARD -i %i -j ACCEPT
PostUp = iptables -A FORWARD -o %i -j ACCEPT  
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostUp = iptables -A INPUT -p udp --dport $WG_PORT -j ACCEPT

# Media stack port forwarding
PostUp = iptables -t nat -A PREROUTING -i %i -p tcp --dport 8600 -j DNAT --to-destination 10.0.0.1:8600
PostUp = iptables -t nat -A PREROUTING -i %i -p tcp --dport 8096 -j DNAT --to-destination 10.0.0.1:8096
PostUp = iptables -t nat -A PREROUTING -i %i -p tcp --dport 32400 -j DNAT --to-destination 10.0.0.1:32400

PostDown = iptables -D FORWARD -i %i -j ACCEPT
PostDown = iptables -D FORWARD -o %i -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D INPUT -p udp --dport $WG_PORT -j ACCEPT

# DNS Configuration
DNS = 10.0.0.1

EOF

    # Save server public key for client configs
    echo "$SERVER_PUBLIC" | sudo tee "$WG_CONFIG_DIR/server.pub" > /dev/null
    
    log "✅ Server configuration created"
}

# Generate client configurations for all devices
generate_client_configs() {
    log "Generating client configurations for all devices..."
    
    sudo mkdir -p "$CLIENT_CONFIG_DIR"
    SERVER_PUBLIC=$(sudo cat "$WG_CONFIG_DIR/server.pub")
    
    for device in "${!DEVICES[@]}"; do
        local device_info="${DEVICES[$device]}"
        local local_ip=$(echo "$device_info" | cut -d: -f1)
        local vpn_ip=$(echo "$device_info" | cut -d: -f2)
        
        log "Creating config for $device ($local_ip -> $vpn_ip)"
        
        # Generate device keys
        DEVICE_KEYS=$(generate_keys "$device")
        DEVICE_PRIVATE=$(echo "$DEVICE_KEYS" | cut -d: -f1)
        DEVICE_PUBLIC=$(echo "$DEVICE_KEYS" | cut -d: -f2)
        DEVICE_PSK=$(echo "$DEVICE_KEYS" | cut -d: -f3)
        
        # Create client config
        sudo tee "$CLIENT_CONFIG_DIR/${device}.conf" > /dev/null << EOF
# WireGuard Client Configuration for $device
# Generated on $(date)
# Local IP: $local_ip | VPN IP: $vpn_ip

[Interface]
PrivateKey = $DEVICE_PRIVATE
Address = $vpn_ip/24
DNS = 10.0.0.1
MTU = 1280

# Ghost Mode stealth settings
# Table = off  # Uncomment for stealth mode

[Peer]
PublicKey = $SERVER_PUBLIC
PresharedKey = $DEVICE_PSK
Endpoint = $EXTERNAL_SERVER_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

        # Add peer to server config
        sudo tee -a "$WG_CONFIG_DIR/wg0.conf" > /dev/null << EOF

# $device (Local: $local_ip)
[Peer]
PublicKey = $DEVICE_PUBLIC
PresharedKey = $DEVICE_PSK
AllowedIPs = $vpn_ip/32
PersistentKeepalive = 25

EOF

        log "✅ Generated config for $device"
    done
    
    # Set proper permissions
    sudo chown -R root:root "$WG_CONFIG_DIR"
    sudo chmod 600 "$WG_CONFIG_DIR"/*.conf
    sudo chmod 644 "$WG_CONFIG_DIR"/clients/*.conf
    
    log "✅ All client configurations generated"
}

# Setup Ghost Mode integration
setup_ghost_mode() {
    log "Setting up Ghost Mode integration..."
    
    # Copy Ghost Mode from awesome-stack
    if [[ -d "/mnt/home/lou/github/awesome-stack/ghost-mode" ]]; then
        sudo cp -r /mnt/home/lou/github/awesome-stack/ghost-mode "$GHOST_CONFIG_DIR"
        sudo chown -R root:root "$GHOST_CONFIG_DIR"
        
        # Install Ghost Mode
        cd "$GHOST_CONFIG_DIR"
        sudo ./install-ghost-mode.sh
        
        log "✅ Ghost Mode installed from awesome-stack"
    else
        warn "Ghost Mode not found in awesome-stack, creating minimal version..."
        create_minimal_ghost_mode
    fi
    
    # Create API masking proxy service
    create_api_masking_service
    
    # Setup automatic rotation
    setup_automatic_rotation
}

# Create minimal Ghost Mode if not found
create_minimal_ghost_mode() {
    sudo mkdir -p "$GHOST_CONFIG_DIR/scripts"
    
    # Create basic ghost-mode script
    sudo tee "$GHOST_CONFIG_DIR/scripts/ghost-mode" > /dev/null << 'EOF'
#!/bin/bash

# Basic Ghost Mode implementation
case "${1:-}" in
    "start")
        echo "🥷 Activating Ghost Mode..."
        systemctl start wg-quick@wg0
        systemctl start api-mask-proxy
        echo "✅ Ghost Mode activated"
        ;;
    "stop")
        echo "👻 Deactivating Ghost Mode..."
        systemctl stop api-mask-proxy
        systemctl stop wg-quick@wg0
        echo "✅ Ghost Mode deactivated"
        ;;
    "status")
        echo "Ghost Mode Status:"
        systemctl is-active wg-quick@wg0 && echo "🟢 VPN: Active" || echo "🔴 VPN: Inactive"
        systemctl is-active api-mask-proxy && echo "🟢 API Proxy: Active" || echo "🔴 API Proxy: Inactive"
        ;;
    *)
        echo "Usage: ghost-mode {start|stop|status}"
        ;;
esac
EOF

    sudo chmod +x "$GHOST_CONFIG_DIR/scripts/ghost-mode"
    sudo ln -sf "$GHOST_CONFIG_DIR/scripts/ghost-mode" /usr/local/bin/ghost-mode
    
    log "✅ Minimal Ghost Mode created"
}

# Create API masking service (from awesome-stack)
create_api_masking_service() {
    log "Setting up API masking proxy..."
    
    # Create API masking proxy (simplified version of awesome-stack implementation)
    sudo tee /opt/api-mask-proxy.py > /dev/null << 'EOF'
#!/usr/bin/env python3
"""
API Masking Proxy Server
Masks API requests to prevent tracking by Warp Terminal or other monitoring
Based on awesome-stack implementation
"""

import asyncio
import aiohttp
import random
import time
import json
import re
from urllib.parse import urlparse
from aiohttp import web, ClientTimeout
from datetime import datetime
import uuid

class APIMaskingProxy:
    def __init__(self, port=8080):
        self.port = port
        self.user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        ]
        
        self.api_routes = {
            'openai': ['api.openai.com', 'chat.openai.com'],
            'anthropic': ['api.anthropic.com', 'claude.ai'],
            'google': ['generativelanguage.googleapis.com'],
        }
    
    def get_random_user_agent(self):
        return random.choice(self.user_agents)
    
    def add_request_jitter(self):
        return random.uniform(0.1, 2.0)
    
    async def proxy_request(self, request):
        target_url = request.match_info.get('path', '')
        
        if not target_url.startswith('http'):
            return web.Response(text="Invalid URL", status=400)
        
        # Add jitter delay
        await asyncio.sleep(self.add_request_jitter())
        
        try:
            body = await request.read()
            
            # Mask headers
            masked_headers = {
                'User-Agent': self.get_random_user_agent(),
                'Accept': 'application/json, text/plain, */*',
                'Accept-Language': 'en-US,en;q=0.9',
                'Accept-Encoding': 'gzip, deflate, br',
                'DNT': '1',
                'Connection': 'keep-alive'
            }
            
            # Preserve essential API headers
            essential_headers = ['authorization', 'content-type', 'anthropic-version']
            for key, value in request.headers.items():
                if key.lower() in essential_headers:
                    masked_headers[key] = value
            
            # Make proxied request
            timeout = ClientTimeout(total=30)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.request(
                    method=request.method,
                    url=target_url,
                    headers=masked_headers,
                    data=body,
                    allow_redirects=False
                ) as response:
                    response_body = await response.read()
                    
                    return web.Response(
                        body=response_body,
                        status=response.status,
                        headers={'Content-Type': response.headers.get('Content-Type', 'application/json')}
                    )
        
        except Exception as e:
            print(f"Proxy error: {e}")
            return web.Response(text=f"Proxy error: {str(e)}", status=500)
    
    def setup_routes(self, app):
        app.router.add_route('*', '/proxy/{path:.*}', self.proxy_request)
        app.router.add_get('/health', lambda r: web.Response(text="OK"))
    
    async def start_server(self):
        app = web.Application()
        self.setup_routes(app)
        
        runner = web.AppRunner(app)
        await runner.setup()
        
        site = web.TCPSite(runner, '127.0.0.1', self.port)
        await site.start()
        
        print(f"API Masking Proxy started on http://127.0.0.1:{self.port}")
        
        try:
            await asyncio.Future()
        except KeyboardInterrupt:
            await runner.cleanup()

def main():
    proxy = APIMaskingProxy(port=8080)
    asyncio.run(proxy.start_server())

if __name__ == '__main__':
    main()
EOF

    # Create systemd service for API proxy
    sudo tee /etc/systemd/system/api-mask-proxy.service > /dev/null << 'EOF'
[Unit]
Description=API Masking Proxy Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt
ExecStart=/usr/bin/python3 /opt/api-mask-proxy.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    sudo chmod +x /opt/api-mask-proxy.py
    
    log "✅ API masking proxy created"
}

# Setup automatic rotation system
setup_automatic_rotation() {
    log "Setting up automatic key rotation..."
    
    # Create rotation script based on awesome-stack
    sudo tee /opt/wireguard-rotate.sh > /dev/null << 'EOF'
#!/bin/bash

# WireGuard Key Rotation Script
# Rotates client keys and IPs every 6 hours

set -e

WG_CONFIG="/etc/wireguard/wg0.conf"
CLIENT_CONFIG_DIR="/etc/wireguard/clients"
LOG_FILE="/var/log/wg-rotation.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Available IP pool for rotation
AVAILABLE_IPS=("10.0.0.20" "10.0.0.21" "10.0.0.22" "10.0.0.23" "10.0.0.24" "10.0.0.25")

get_random_ip() {
    local random_index=$((RANDOM % ${#AVAILABLE_IPS[@]}))
    echo "${AVAILABLE_IPS[$random_index]}"
}

rotate_client() {
    local client_name="$1"
    
    log_message "Starting rotation for client: $client_name"
    
    # Generate new keys
    local private_key=$(wg genkey)
    local public_key=$(echo "$private_key" | wg pubkey)
    local preshared_key=$(wg genpsk)
    local new_ip=$(get_random_ip)
    
    # Create new client config
    tee "$CLIENT_CONFIG_DIR/$client_name-$(date +%Y%m%d-%H%M).conf" > /dev/null << EOF
[Interface]
PrivateKey = $private_key
Address = $new_ip/24
DNS = 10.0.0.1

[Peer]
PublicKey = $(cat /etc/wireguard/server.pub)
PresharedKey = $preshared_key
Endpoint = 172.59.85.76:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
    
    # Update server config (append new peer)
    cat >> "$WG_CONFIG" << EOF

# $client_name (Rotated $(date))
[Peer]
PublicKey = $public_key
PresharedKey = $preshared_key
AllowedIPs = $new_ip/32
PersistentKeepalive = 25
EOF
    
    # Restart WireGuard
    systemctl restart wg-quick@wg0
    
    log_message "Rotation completed for $client_name. New IP: $new_ip"
    echo "New config: $CLIENT_CONFIG_DIR/$client_name-$(date +%Y%m%d-%H%M).conf"
}

# Main rotation
case "${1:-}" in
    "garuda-host"|"auto")
        rotate_client "garuda-host"
        ;;
    "all-devices")
        for device in "${!DEVICES[@]}"; do
            rotate_client "$device"
        done
        ;;
    *)
        echo "Usage: $0 {garuda-host|auto|all-devices}"
        exit 1
        ;;
esac
EOF

    sudo chmod +x /opt/wireguard-rotate.sh
    
    # Create cron job for automatic rotation
    sudo tee /etc/cron.d/wireguard-rotation > /dev/null << 'EOF'
# Rotate WireGuard keys every 6 hours for enhanced security
0 */6 * * * root /opt/wireguard-rotate.sh auto >> /var/log/wg-rotation.log 2>&1

# Daily cleanup of old client configs (keep last 7 days)
0 3 * * * root find /etc/wireguard/clients -name "*.conf" -mtime +7 -delete
EOF

    log "✅ Automatic rotation configured"
}

# Create QR codes for mobile devices
generate_qr_codes() {
    log "Generating QR codes for mobile devices..."
    
    # Install qrencode if not present
    if ! command -v qrencode >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm qrencode
    fi
    
    sudo mkdir -p "$CLIENT_CONFIG_DIR/qr-codes"
    
    # Generate QR codes for mobile devices
    for device in "phone-android3" "phone-android4" "tablet-jackie"; do
        if [[ -f "$CLIENT_CONFIG_DIR/${device}.conf" ]]; then
            sudo qrencode -t png -o "$CLIENT_CONFIG_DIR/qr-codes/${device}-qr.png" < "$CLIENT_CONFIG_DIR/${device}.conf"
            log "✅ QR code generated for $device"
        fi
    done
    
    log "✅ QR codes saved to $CLIENT_CONFIG_DIR/qr-codes/"
}

# Create device management script
create_device_manager() {
    log "Creating device management script..."
    
    sudo tee /usr/local/bin/wg-device-manager > /dev/null << 'EOF'
#!/bin/bash

# WireGuard Device Manager
CLIENT_CONFIG_DIR="/etc/wireguard/clients"

case "${1:-}" in
    "list")
        echo "🔌 Configured Devices:"
        echo "====================="
        for config in "$CLIENT_CONFIG_DIR"/*.conf; do
            if [[ -f "$config" ]]; then
                device=$(basename "$config" .conf)
                echo "📱 $device"
                echo "   Config: $config"
                if [[ -f "$CLIENT_CONFIG_DIR/qr-codes/$device-qr.png" ]]; then
                    echo "   QR Code: $CLIENT_CONFIG_DIR/qr-codes/$device-qr.png"
                fi
                echo ""
            fi
        done
        ;;
    "show")
        device="${2:-}"
        if [[ -z "$device" ]]; then
            echo "Usage: wg-device-manager show <device-name>"
            exit 1
        fi
        
        config_file="$CLIENT_CONFIG_DIR/$device.conf"
        if [[ -f "$config_file" ]]; then
            echo "📱 Configuration for $device:"
            echo "============================"
            cat "$config_file"
        else
            echo "❌ Device $device not found"
            echo "Available devices:"
            ls "$CLIENT_CONFIG_DIR"/*.conf 2>/dev/null | xargs -n1 basename -s .conf || echo "No devices configured"
        fi
        ;;
    "qr")
        device="${2:-}"
        if [[ -z "$device" ]]; then
            echo "Usage: wg-device-manager qr <device-name>"
            exit 1
        fi
        
        qr_file="$CLIENT_CONFIG_DIR/qr-codes/$device-qr.png"
        if [[ -f "$qr_file" ]]; then
            echo "📱 QR Code for $device: $qr_file"
            # Try to display QR code in terminal if possible
            if command -v qrencode >/dev/null 2>&1; then
                echo "Terminal QR Code:"
                qrencode -t utf8 < "$CLIENT_CONFIG_DIR/$device.conf"
            fi
        else
            echo "❌ QR code for $device not found"
        fi
        ;;
    "rotate")
        device="${2:-garuda-host}"
        echo "🔄 Rotating keys for $device..."
        /opt/wireguard-rotate.sh "$device"
        ;;
    "status")
        echo "🛡️ WireGuard Server Status:"
        echo "=========================="
        systemctl is-active wg-quick@wg0 && echo "🟢 Server: Running" || echo "🔴 Server: Stopped"
        
        if command -v wg >/dev/null 2>&1 && systemctl is-active wg-quick@wg0 >/dev/null; then
            echo ""
            echo "Connected Peers:"
            wg show wg0 peers | while read peer; do
                echo "🔗 $peer"
            done
        fi
        ;;
    *)
        echo "🛡️ WireGuard Device Manager"
        echo "Usage: wg-device-manager {list|show|qr|rotate|status}"
        echo ""
        echo "Commands:"
        echo "  list              - List all configured devices"
        echo "  show <device>     - Show device configuration"
        echo "  qr <device>       - Display QR code for device"
        echo "  rotate [device]   - Rotate keys for device (default: garuda-host)"
        echo "  status            - Show WireGuard server status"
        ;;
esac
EOF

    sudo chmod +x /usr/local/bin/wg-device-manager
    
    log "✅ Device manager script created"
}

# Setup DNS server for VPN
setup_vpn_dns() {
    log "Setting up VPN DNS server..."
    
    # Install unbound for DNS
    sudo pacman -S --needed --noconfirm unbound
    
    # Configure unbound for VPN
    sudo tee /etc/unbound/unbound.conf > /dev/null << 'EOF'
server:
    verbosity: 1
    interface: 10.0.0.1
    port: 53
    do-ip4: yes
    do-ip6: no
    do-udp: yes
    do-tcp: yes
    
    # Access control
    access-control: 10.0.0.0/24 allow
    access-control: 127.0.0.1/32 allow
    
    # Privacy and security
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: yes
    
    # Performance
    cache-min-ttl: 300
    cache-max-ttl: 86400
    prefetch: yes
    
    # Upstream DNS servers
    forward-zone:
        name: "."
        forward-addr: 1.1.1.1@853#cloudflare-dns.com
        forward-addr: 9.9.9.9@853#dns.quad9.net
        forward-tls-upstream: yes
EOF

    # Enable and start unbound
    sudo systemctl enable unbound
    sudo systemctl start unbound
    
    log "✅ VPN DNS server configured"
}

# Main setup function
main() {
    log "🛡️ Starting WireGuard Ghost Mode Dual-Role Setup"
    log "==============================================="
    
    # Create log file
    sudo touch "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
    
    # Install dependencies
    log "Installing WireGuard dependencies..."
    sudo pacman -S --needed --noconfirm wireguard-tools qrencode unbound python-aiohttp
    
    # Setup components
    setup_server_config
    generate_client_configs
    setup_vpn_dns
    setup_ghost_mode
    generate_qr_codes
    create_device_manager
    
    # Enable services
    sudo systemctl daemon-reload
    sudo systemctl enable unbound
    sudo systemctl enable api-mask-proxy
    sudo systemctl enable wg-quick@wg0
    
    # Start services
    sudo systemctl start unbound
    sudo systemctl start api-mask-proxy
    sudo systemctl start wg-quick@wg0
    
    log "🎉 WireGuard Ghost Mode Setup Complete!"
    log "======================================"
    log ""
    log "🌐 Server Details:"
    log "  External IP: $EXTERNAL_SERVER_IP:$WG_PORT"
    log "  VPN Network: 10.0.0.0/24"
    log "  Server VPN IP: 10.0.0.1"
    log ""
    log "📱 Device Configurations:"
    for device in "${!DEVICES[@]}"; do
        local device_info="${DEVICES[$device]}"
        local local_ip=$(echo "$device_info" | cut -d: -f1)
        local vpn_ip=$(echo "$device_info" | cut -d: -f2)
        log "  $device: $local_ip -> $vpn_ip"
    done
    log ""
    log "🛠️ Management Commands:"
    log "  wg-device-manager list     - List all device configs"
    log "  wg-device-manager qr phone-android3  - Show QR code"
    log "  ghost-mode start          - Activate anonymity mode"
    log "  ghost-mode status         - Check Ghost Mode status"
    log ""
    log "📂 Client configs saved to: $CLIENT_CONFIG_DIR"
    log "🎯 QR codes saved to: $CLIENT_CONFIG_DIR/qr-codes"
    log ""
    log "🔒 Security Features Active:"
    log "  ✅ 6-hour automatic key rotation"
    log "  ✅ API request masking proxy"
    log "  ✅ Ghost Mode integration"
    log "  ✅ DNS-over-TLS for privacy"
    log "  ✅ Device-specific VPN IPs"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
