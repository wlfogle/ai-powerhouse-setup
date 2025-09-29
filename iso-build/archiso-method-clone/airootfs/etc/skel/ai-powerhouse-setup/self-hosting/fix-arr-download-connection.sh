#!/bin/bash

# Fix *arr programs connection to download clients (qBittorrent/Deluge)
# This script addresses common connection issues between Sonarr/Radarr/Lidarr and download clients

echo "🔧 Fixing *arr programs connection to download clients..."

# 1. Ensure qBittorrent is accessible from *arr applications
echo "📡 Step 1: Checking qBittorrent configuration..."

# Check if qBittorrent is running and listening
if pgrep -x "qbittorrent-nox" > /dev/null; then
    echo "✅ qBittorrent-nox is running"
else
    echo "❌ qBittorrent-nox is not running, starting it..."
    systemctl start qbittorrent-nox@lou.service
fi

# Test if port 5080 is accessible
if netstat -tlnp | grep -q ":5080"; then
    echo "✅ qBittorrent is listening on port 5080"
else
    echo "❌ qBittorrent is not listening on port 5080"
    echo "🔄 Restarting qBittorrent service..."
    systemctl restart qbittorrent-nox@lou.service
    sleep 3
fi

# 2. Test connectivity from localhost
echo "📡 Step 2: Testing localhost connectivity to qBittorrent..."

# Test basic HTTP connectivity
if curl -s --connect-timeout 5 http://localhost:5080 > /dev/null; then
    echo "✅ qBittorrent web interface is accessible via localhost"
else
    echo "❌ qBittorrent web interface is not accessible via localhost"
    
    # Try with 127.0.0.1
    if curl -s --connect-timeout 5 http://127.0.0.1:5080 > /dev/null; then
        echo "✅ qBittorrent accessible via 127.0.0.1"
    else
        echo "❌ qBittorrent not accessible via 127.0.0.1"
        echo "🔄 This suggests a binding issue..."
    fi
fi

# 3. Check qBittorrent configuration for proper binding
echo "📡 Step 3: Checking qBittorrent binding configuration..."

QB_CONFIG="/home/lou/.config/qBittorrent/qBittorrent.conf"
if [ -f "$QB_CONFIG" ]; then
    if grep -q "WebUI\\Address=" "$QB_CONFIG"; then
        ADDRESS=$(grep "WebUI\\Address=" "$QB_CONFIG" | cut -d'=' -f2)
        echo "📋 qBittorrent WebUI Address: $ADDRESS"
        if [ "$ADDRESS" = "*" ] || [ "$ADDRESS" = "0.0.0.0" ] || [ -z "$ADDRESS" ]; then
            echo "✅ qBittorrent is configured to accept connections from any host"
        else
            echo "⚠️ qBittorrent is only accepting connections from: $ADDRESS"
            echo "🔧 Fixing binding to accept connections from any host..."
            sed -i 's/WebUI\\Address=.*/WebUI\\Address=*/' "$QB_CONFIG"
            systemctl restart qbittorrent-nox@lou.service
            echo "✅ Fixed qBittorrent binding - restart complete"
        fi
    else
        echo "📝 Adding WebUI address configuration..."
        echo "WebUI\\Address=*" >> "$QB_CONFIG"
        systemctl restart qbittorrent-nox@lou.service
        echo "✅ Added binding configuration - restart complete"
    fi
else
    echo "❌ qBittorrent configuration file not found at $QB_CONFIG"
fi

# 4. Test API endpoint that *arr programs use
echo "📡 Step 4: Testing qBittorrent API endpoints..."

# Test the WebUI API
sleep 3  # Give service time to restart
curl -s --connect-timeout 5 -X GET "http://localhost:5080/api/v2/app/version" && echo "✅ qBittorrent API is responding" || echo "❌ qBittorrent API is not responding"

# 5. Provide connection details for *arr configuration
echo ""
echo "📋 Connection Details for *arr Applications:"
echo "═══════════════════════════════════════════"
echo "🖥️  Host: localhost (or 127.0.0.1)"
echo "🔌 Port: 5080"
echo "👤 Username: lou"
echo "🔑 Password: (check qBittorrent WebUI for current password)"
echo "🌐 URL Category: Optional (leave blank or use 'arr-movies', 'arr-tv', etc.)"
echo ""

# 6. Show final status
echo "📊 Final Status Check:"
echo "═══════════════════════"
netstat -tlnp | grep ":5080" && echo "✅ qBittorrent is listening on port 5080" || echo "❌ qBittorrent is still not accessible"

# 7. Instructions for *arr configuration
echo ""
echo "🎯 Next Steps for *arr Configuration:"
echo "════════════════════════════════════"
echo "1. Open Sonarr: http://localhost:8989"
echo "2. Go to Settings → Download Clients"
echo "3. Add qBittorrent with these settings:"
echo "   - Host: localhost"
echo "   - Port: 5080"
echo "   - Username: lou"
echo "   - Password: (from qBittorrent WebUI)"
echo "   - Category: sonarr (optional)"
echo "4. Test the connection"
echo "5. Repeat for Radarr (port 7878) and Lidarr (port 8686)"

echo ""
echo "🔧 Connection fix script completed!"
