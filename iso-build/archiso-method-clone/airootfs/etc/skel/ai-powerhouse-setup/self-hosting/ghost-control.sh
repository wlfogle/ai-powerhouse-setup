#!/bin/bash
# Ghost Mode Controller

GHOST_STATUS_FILE="/home/lou/garuda-media-stack/ghost-mode-status.txt"
WG_SERVER_CONF="/etc/wireguard/wg0-server.conf"
WG_CLIENT_CONF="/etc/wireguard/wg0-client.conf"

get_ghost_status() {
    if [[ -f "$GHOST_STATUS_FILE" ]]; then
        cat "$GHOST_STATUS_FILE"
    else
        echo "inactive"
    fi
}

enable_ghost_mode() {
    echo "🥷 Enabling Ghost Mode..."
    
    # Start client connection through VPN
    if [[ -f "$WG_CLIENT_CONF" ]]; then
        wg-quick up wg0-client 2>/dev/null
    fi
    
    # Route traffic through VPN
    ip route add default dev wg0-client 2>/dev/null
    
    # Update status
    echo "active" > "$GHOST_STATUS_FILE"
    echo "✅ Ghost Mode ENABLED - Traffic masked through VPN"
}

disable_ghost_mode() {
    echo "👁️ Disabling Ghost Mode..."
    
    # Stop client connection
    wg-quick down wg0-client 2>/dev/null
    
    # Restore normal routing
    ip route del default dev wg0-client 2>/dev/null
    
    # Update status
    echo "inactive" > "$GHOST_STATUS_FILE"
    echo "✅ Ghost Mode DISABLED - Direct connection"
}

toggle_ghost_mode() {
    local current_status=$(get_ghost_status)
    
    if [[ "$current_status" == "active" ]]; then
        disable_ghost_mode
    else
        enable_ghost_mode
    fi
}

case "$1" in
    "enable")
        enable_ghost_mode
        ;;
    "disable") 
        disable_ghost_mode
        ;;
    "toggle")
        toggle_ghost_mode
        ;;
    "status")
        echo "Ghost Mode: $(get_ghost_status)"
        ;;
    *)
        echo "Usage: $0 {enable|disable|toggle|status}"
        ;;
esac
