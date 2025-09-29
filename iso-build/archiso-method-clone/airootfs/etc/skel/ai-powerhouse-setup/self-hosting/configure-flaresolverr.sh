#!/bin/bash
# Configure Jackett to use FlareSolverr for Cloudflare bypass

JACKETT_CONFIG="/var/lib/jackett/ServerConfig.json"
FLARESOLVERR_URL="http://localhost:8191/v1"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

configure_jackett() {
    log "🔧 Configuring Jackett to use FlareSolverr..."
    
    # Stop Jackett
    pkill -f jackett || true
    sleep 2
    
    # Update configuration
    if [ -f "$JACKETT_CONFIG" ]; then
        # Backup original config
        cp "$JACKETT_CONFIG" "$JACKETT_CONFIG.backup"
        
        # Update FlareSolverr URL
        sed -i "s|\"FlareSolverrUrl\": null|\"FlareSolverrUrl\": \"$FLARESOLVERR_URL\"|" "$JACKETT_CONFIG"
        sed -i "s|\"FlareSolverrUrl\": \".*\"|\"FlareSolverrUrl\": \"$FLARESOLVERR_URL\"|" "$JACKETT_CONFIG"
        
        log "✅ Updated Jackett configuration with FlareSolverr URL: $FLARESOLVERR_URL"
        
        # Show current config
        grep -A1 -B1 FlareSolverr "$JACKETT_CONFIG"
    else
        log "❌ Jackett config file not found: $JACKETT_CONFIG"
        return 1
    fi
    
    # Start Jackett
    log "🚀 Starting Jackett..."
    cd /usr/lib/jackett
    nohup /usr/lib/jackett/jackett --NoRestart --NoUpdates --DataFolder /var/lib/jackett > /var/log/jackett/jackett-startup.log 2>&1 &
    
    sleep 5
    
    # Test Jackett
    if curl -s -w "%{http_code}" http://localhost:9117 -o /dev/null | grep -q "200\|301"; then
        log "✅ Jackett is running successfully"
        log "📡 Jackett WebUI: http://localhost:9117"
        log "🔥 FlareSolverr configured at: $FLARESOLVERR_URL"
        return 0
    else
        log "❌ Jackett failed to start properly"
        return 1
    fi
}

test_flaresolverr_integration() {
    log "🧪 Testing FlareSolverr integration..."
    
    # Check if FlareSolverr is running
    if curl -s -X POST "$FLARESOLVERR_URL" \
       -H "Content-Type: application/json" \
       -d '{"cmd": "request.get", "url": "https://httpbin.org/ip", "maxTimeout": 30000}' \
       | grep -q '"status": "ok"'; then
        log "✅ FlareSolverr is responding correctly"
    else
        log "❌ FlareSolverr test failed"
        return 1
    fi
    
    # Check Jackett config
    if grep -q "\"FlareSolverrUrl\": \"$FLARESOLVERR_URL\"" "$JACKETT_CONFIG"; then
        log "✅ Jackett is configured to use FlareSolverr"
    else
        log "❌ Jackett FlareSolverr configuration not found"
        return 1
    fi
    
    log "🎉 FlareSolverr integration is working!"
    log ""
    log "📋 Next steps:"
    log "1. Go to http://localhost:9117"
    log "2. Add indexers that require Cloudflare bypass"
    log "3. Test indexers - they should now bypass Cloudflare automatically"
    log "4. Common protected indexers: 1337x, RARBG, Torrentleech, etc."
    
    return 0
}

show_status() {
    log "📊 Current Status:"
    
    # FlareSolverr status
    if curl -s "$FLARESOLVERR_URL" | grep -q "Method not allowed"; then
        log "✅ FlareSolverr: Running on port 8191"
    else
        log "❌ FlareSolverr: Not responding"
    fi
    
    # Jackett status  
    if curl -s -w "%{http_code}" http://localhost:9117 -o /dev/null | grep -q "200\|301"; then
        log "✅ Jackett: Running on port 9117"
    else
        log "❌ Jackett: Not responding"
    fi
    
    # Configuration status
    if [ -f "$JACKETT_CONFIG" ] && grep -q "\"FlareSolverrUrl\": \"$FLARESOLVERR_URL\"" "$JACKETT_CONFIG"; then
        log "✅ Configuration: FlareSolverr properly configured in Jackett"
    else
        log "❌ Configuration: FlareSolverr not configured in Jackett"
    fi
}

case "$1" in
    "configure")
        configure_jackett
        ;;
    "test")
        test_flaresolverr_integration
        ;;
    "status")
        show_status
        ;;
    *)
        echo "Usage: $0 {configure|test|status}"
        echo ""
        echo "🔥 FlareSolverr + Jackett Configuration Script"
        echo "  configure - Configure Jackett to use FlareSolverr"
        echo "  test     - Test FlareSolverr integration"
        echo "  status   - Show current status"
        echo ""
        show_status
        ;;
esac
