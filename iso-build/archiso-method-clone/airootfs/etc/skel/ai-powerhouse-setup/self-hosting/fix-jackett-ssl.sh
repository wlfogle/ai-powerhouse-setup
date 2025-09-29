#!/bin/bash
# Fix common SSL and connectivity issues with Jackett indexers

JACKETT_CONFIG="/var/lib/jackett/ServerConfig.json"
JACKETT_INDEXERS="/var/lib/jackett/Indexers"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

test_indexer_connectivity() {
    local indexer_name="$1"
    local test_url="$2"
    
    log "🌐 Testing connectivity to $indexer_name ($test_url)..."
    
    # Test basic connectivity
    if timeout 10 curl -s -k --connect-timeout 5 "$test_url" > /dev/null 2>&1; then
        log "✅ $indexer_name: Basic connectivity OK"
        return 0
    else
        log "❌ $indexer_name: Connection failed"
        
        # Try alternative approaches
        log "🔄 Trying alternative connection methods..."
        
        # Test with different TLS versions
        if timeout 10 curl -s -k --tlsv1.2 --connect-timeout 5 "$test_url" > /dev/null 2>&1; then
            log "✅ $indexer_name: Works with TLS 1.2"
            return 0
        elif timeout 10 curl -s -k --tlsv1.3 --connect-timeout 5 "$test_url" > /dev/null 2>&1; then
            log "✅ $indexer_name: Works with TLS 1.3"
            return 0
        else
            log "❌ $indexer_name: All connection methods failed"
            return 1
        fi
    fi
}

check_common_indexers() {
    log "🔍 Checking common indexer connectivity..."
    
    # Common indexers and their test URLs
    declare -A indexers=(
        ["1337x"]="https://1337x.to"
        ["idope"]="https://idope.se"
        ["limetorrents"]="https://www.limetorrents.info"
        ["torlock"]="https://www.torlock.com"
        ["torrentgalaxy"]="https://torrentgalaxy.to"
        ["glotorrents"]="https://glotorrents.fr"
        ["thepiratebay"]="https://thepiratebay.org"
    )
    
    local working_count=0
    local total_count=0
    
    for indexer in "${!indexers[@]}"; do
        total_count=$((total_count + 1))
        if test_indexer_connectivity "$indexer" "${indexers[$indexer]}"; then
            working_count=$((working_count + 1))
        fi
        echo ""
    done
    
    log "📊 Results: $working_count/$total_count indexers are accessible"
}

fix_ssl_issues() {
    log "🔧 Applying SSL/TLS fixes..."
    
    # Update CA certificates
    log "📜 Updating CA certificates..."
    update-ca-certificates > /dev/null 2>&1 || true
    
    # Check .NET SSL configuration
    if [ -f "/usr/lib/jackett/Jackett.dll" ]; then
        log "🔧 Configuring .NET SSL settings..."
        
        # Set environment variables for better SSL compatibility
        export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
        export DOTNET_SYSTEM_NET_HTTP_SOCKETSHTTPHANDLER_HTTP2SUPPORT=false
        
        # Create SSL fix script
        cat > /tmp/jackett_ssl_fix.sh << 'EOF'
export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
export DOTNET_SYSTEM_NET_HTTP_SOCKETSHTTPHANDLER_HTTP2SUPPORT=false
export SSL_CERT_DIR=/etc/ssl/certs
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# Restart Jackett with fixed SSL settings
pkill -f jackett || true
sleep 2

cd /usr/lib/jackett
nohup /usr/lib/jackett/jackett --NoRestart --NoUpdates --DataFolder /var/lib/jackett > /var/log/jackett/jackett-ssl-fix.log 2>&1 &
EOF
        
        chmod +x /tmp/jackett_ssl_fix.sh
        log "✅ Created SSL fix script: /tmp/jackett_ssl_fix.sh"
    fi
}

suggest_alternatives() {
    local failed_indexer="$1"
    
    log "💡 Alternatives for $failed_indexer:"
    
    case "$failed_indexer" in
        "idope")
            log "  • Try: Torlock, TorrentGalaxy, LimeTorrents"
            log "  • Mirror sites: idope.top, idope.click"
            ;;
        "1337x")
            log "  • Try: 1337x.to, x1337x.ws, x1337x.eu"
            log "  • Alternatives: TorrentGalaxy, LimeTorrents"
            ;;
        "thepiratebay")
            log "  • Try: thepiratebay.org, piratebay.live"
            log "  • Alternatives: 1337x, TorrentGalaxy"
            ;;
        *)
            log "  • Check if the site is down: downforeveryoneorjustme.com"
            log "  • Try using a VPN or different DNS"
            log "  • Look for mirror/proxy sites"
            ;;
    esac
}

create_jackett_restart_script() {
    log "📝 Creating optimized Jackett restart script..."
    
    cat > /home/lou/garuda-media-stack/restart-jackett-ssl.sh << 'EOF'
#!/bin/bash
# Restart Jackett with SSL optimizations

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🛑 Stopping Jackett..."
pkill -f jackett || true
sleep 3

log "🔧 Setting SSL environment variables..."
export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
export DOTNET_SYSTEM_NET_HTTP_SOCKETSHTTPHANDLER_HTTP2SUPPORT=false
export SSL_CERT_DIR=/etc/ssl/certs
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

log "🚀 Starting Jackett with SSL fixes..."
cd /usr/lib/jackett
nohup /usr/lib/jackett/jackett --NoRestart --NoUpdates --DataFolder /var/lib/jackett > /var/log/jackett/jackett.log 2>&1 &

sleep 5

if curl -s -w "%{http_code}" http://localhost:9117 -o /dev/null | grep -q "200\|301"; then
    log "✅ Jackett restarted successfully"
    log "📡 WebUI: http://localhost:9117"
else
    log "❌ Jackett failed to start"
fi
EOF
    
    chmod +x /home/lou/garuda-media-stack/restart-jackett-ssl.sh
    log "✅ Created restart script: /home/lou/garuda-media-stack/restart-jackett-ssl.sh"
}

show_indexer_recommendations() {
    log "🎯 Recommended working indexers:"
    log ""
    log "✅ Usually reliable:"
    log "  • TorrentGalaxy (https://torrentgalaxy.to)"
    log "  • LimeTorrents (https://www.limetorrents.info)"  
    log "  • Torlock (https://www.torlock.com)"
    log "  • YTS (https://yts.mx)"
    log "  • EZTV (https://eztv.re)"
    log ""
    log "⚠️ May require FlareSolverr:"
    log "  • 1337x"
    log "  • The Pirate Bay"
    log "  • RARBG (often blocked)"
    log ""
    log "❌ Currently having issues:"
    log "  • idope.se (SSL/connectivity problems)"
    log ""
    log "💡 Pro tip: Add multiple indexers for redundancy!"
}

case "$1" in
    "test")
        check_common_indexers
        ;;
    "fix")
        fix_ssl_issues
        create_jackett_restart_script
        log "🔧 SSL fixes applied. Run 'restart' to restart Jackett."
        ;;
    "restart")
        if [ -f "/home/lou/garuda-media-stack/restart-jackett-ssl.sh" ]; then
            /home/lou/garuda-media-stack/restart-jackett-ssl.sh
        else
            log "❌ SSL restart script not found. Run 'fix' first."
        fi
        ;;
    "alternatives")
        show_indexer_recommendations
        ;;
    "help-idope")
        log "🔍 idope.se troubleshooting:"
        log "• The site appears to be having SSL/connectivity issues"
        log "• This is a known problem with idope indexers"
        log "• Try these alternatives instead:"
        suggest_alternatives "idope"
        ;;
    *)
        echo "Usage: $0 {test|fix|restart|alternatives|help-idope}"
        echo ""
        echo "🔧 Jackett SSL & Connectivity Troubleshooting"
        echo "  test        - Test connectivity to common indexers"
        echo "  fix         - Apply SSL fixes and create restart script"
        echo "  restart     - Restart Jackett with SSL optimizations"
        echo "  alternatives - Show recommended working indexers"
        echo "  help-idope  - Specific help for idope SSL issues"
        echo ""
        log "Current issue: idope.se SSL connection problems"
        suggest_alternatives "idope"
        ;;
esac
