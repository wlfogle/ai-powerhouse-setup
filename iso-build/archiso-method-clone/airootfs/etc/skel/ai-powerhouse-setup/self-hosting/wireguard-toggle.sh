#!/bin/bash
# WireGuard Dual-Role Toggle Script
# Switches between server-only and server+client modes

WG_DIR="/etc/wireguard"
STATUS_FILE="/home/lou/garuda-media-stack/ghost-mode-status.txt"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "/home/lou/garuda-media-stack/logs/wireguard.log"
}

get_status() {
    if wg show wg0-client-simple > /dev/null 2>&1; then
        echo "client_active"
    else
        echo "server_only"
    fi
}

start_client() {
    log "🔐 Starting WireGuard client mode (routing through VPN)..."
    
    # Create a simplified client config without DNS conflicts
    cat > /etc/wireguard/wg0-client-simple.conf << EOF
[Interface]
Address = 10.0.0.2/24
PrivateKey = yMlhSKo+CbdwBbOK0mif22ZOOaanXW9TGZJO3rw/GF8=

# Route all traffic through VPN
PostUp = ip route add default via 10.0.0.1 dev %i metric 50
PostUp = iptables -t mangle -A OUTPUT -j MARK --set-mark 0x1
PostDown = iptables -t mangle -D OUTPUT -j MARK --set-mark 0x1 || true

[Peer]
PublicKey = 2mnH8JZvP/g4+pRTM7jaRAU7mFy5D7T+HuARiqQAOFY=
PresharedKey = 2GaZKZGsPh75OQU+vgyE9cb9WnUQUEwVXX6TEPD4kNo=
Endpoint = 127.0.0.1:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
    chmod 600 /etc/wireguard/wg0-client-simple.conf

    # Start the client interface
    if wg-quick up wg0-client-simple; then
        log "✅ WireGuard client mode activated"
        echo "active" > "$STATUS_FILE"
        return 0
    else
        log "❌ Failed to start WireGuard client mode"
        echo "inactive" > "$STATUS_FILE"
        return 1
    fi
}

stop_client() {
    log "🔓 Stopping WireGuard client mode (direct connection)..."
    
    # Stop client interface if it exists
    if wg show wg0-client-simple > /dev/null 2>&1; then
        wg-quick down wg0-client-simple || true
    fi
    
    # Clean up any client interfaces
    if ip link show wg0-client-simple > /dev/null 2>&1; then
        ip link delete wg0-client-simple || true
    fi
    
    # Clean up iptables rules
    iptables -t mangle -D OUTPUT -j MARK --set-mark 0x1 2>/dev/null || true
    
    log "✅ WireGuard client mode deactivated"
    echo "inactive" > "$STATUS_FILE"
}

toggle_client() {
    local status=$(get_status)
    
    if [ "$status" = "client_active" ]; then
        log "🔄 Switching from VPN client to direct connection..."
        stop_client
    else
        log "🔄 Switching from direct connection to VPN client..."
        start_client
    fi
}

show_status() {
    local server_status="❌ OFFLINE"
    local client_status="❌ INACTIVE"
    local external_ip="Unknown"
    
    # Check server status
    if wg show wg0-server > /dev/null 2>&1; then
        local peer_count=$(wg show wg0-server peers | wc -l)
        server_status="✅ ONLINE ($peer_count clients connected)"
    fi
    
    # Check client status
    if wg show wg0-client-simple > /dev/null 2>&1; then
        client_status="✅ ACTIVE (routing via VPN)"
    else
        client_status="🔓 INACTIVE (direct connection)"
    fi
    
    # Get external IP
    external_ip=$(curl -s --max-time 5 http://ipinfo.io/ip || echo "Connection failed")
    
    echo "🌐 WireGuard Dual-Role Status:"
    echo "  Server: $server_status"
    echo "  Client: $client_status"
    echo "  External IP: $external_ip"
    
    # Show location if we have an IP
    if [[ "$external_ip" != "Unknown" && "$external_ip" != "Connection failed" ]]; then
        local location=$(curl -s --max-time 5 "http://ipinfo.io/$external_ip" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$location" ]; then
            echo "  Location: $location"
        fi
    fi
}

restart_server() {
    log "🔄 Restarting WireGuard server..."
    
    systemctl stop wg-quick@wg0-server
    sleep 2
    systemctl start wg-quick@wg0-server
    
    if systemctl is-active wg-quick@wg0-server > /dev/null 2>&1; then
        log "✅ WireGuard server restarted successfully"
    else
        log "❌ Failed to restart WireGuard server"
    fi
}

case "$1" in
    "start-client")
        start_client
        ;;
    "stop-client")
        stop_client
        ;;
    "toggle")
        toggle_client
        ;;
    "status")
        show_status
        ;;
    "restart-server")
        restart_server
        ;;
    "test-connection")
        echo "Testing external IP..."
        curl -s http://ipinfo.io/ip
        ;;
    *)
        echo "Usage: $0 {start-client|stop-client|toggle|status|restart-server|test-connection}"
        echo ""
        echo "🔐 WireGuard Dual-Role Manager:"
        echo "  start-client  → Route traffic through VPN"
        echo "  stop-client   → Use direct connection"
        echo "  toggle        → Switch between modes"
        echo "  status        → Show current status"
        echo "  restart-server → Restart VPN server"
        echo ""
        show_status
        ;;
esac
