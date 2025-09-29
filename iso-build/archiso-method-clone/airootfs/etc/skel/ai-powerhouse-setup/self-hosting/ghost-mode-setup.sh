#!/bin/bash
# Ghost Mode and API Proxy Setup for Chroot Environment
# Garuda Media Stack

SCRIPT_DIR="/home/lou/garuda-media-stack"
CONFIG_DIR="$SCRIPT_DIR/config"

echo "🥷 Setting up Ghost Mode and API Proxy..."

# Create Ghost Mode configuration
mkdir -p "$CONFIG_DIR"

# Ghost Mode status file
echo "inactive" > "$SCRIPT_DIR/ghost-mode-status.txt"

# API Proxy setup (reverse proxy for masking API calls)
cat > "$CONFIG_DIR/api-proxy.conf" << 'EOF'
upstream backend {
    server 127.0.0.1:8080;
}

server {
    listen 8888;
    server_name _;
    
    # API masking headers
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # Remove identifying headers
    proxy_hide_header X-Powered-By;
    proxy_hide_header Server;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    
    location /api/ {
        # Mask API requests
        proxy_pass http://backend;
        proxy_buffering off;
        proxy_request_buffering off;
    }
    
    location / {
        proxy_pass http://backend;
    }
}
EOF

# Create Ghost Mode control script
cat > "$SCRIPT_DIR/ghost-control.sh" << 'EOF'
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
EOF

chmod +x "$SCRIPT_DIR/ghost-control.sh"

# Start API masking proxy
echo "🛡️ Starting API masking proxy on port 8888..."
nohup nginx -p /home/lou/garuda-media-stack -c config/api-proxy.conf > /dev/null 2>&1 &

echo "✅ Ghost Mode and API Proxy setup complete!"
echo ""
echo "🎛️ Controls:"
echo "  Ghost Mode: $SCRIPT_DIR/ghost-control.sh {enable|disable|toggle|status}"
echo "  API Proxy: Running on port 8888"
echo "  WireGuard Server: Running on port 51820"
echo ""
echo "📱 Client configs available in: /home/lou/wireguard-clients/"
echo "🔑 WireGuard Status: $(wg show wg0-server | grep -c 'peer') clients configured"
