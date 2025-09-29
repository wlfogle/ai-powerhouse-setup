#!/bin/bash
# Install Optional Services for Garuda Media Stack

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

install_readarr() {
    log "📚 Installing Readarr (Books/Ebooks)..."
    
    cd /opt
    
    # Try different download methods
    local readarr_url="https://readarr.servarr.com/v1/update/develop/updatefile?os=linux&runtime=netcore&arch=x64"
    
    if curl -L "$readarr_url" -o readarr.tar.gz 2>/dev/null; then
        if tar -xzf readarr.tar.gz 2>/dev/null; then
            rm -f readarr.tar.gz
            chown -R root:root Readarr
            log "✅ Readarr installed to /opt/Readarr"
            
            # Create startup script
            cat > /usr/local/bin/start-readarr << 'EOF'
#!/bin/bash
cd /opt/Readarr
nohup ./Readarr -nobrowser -data=/var/lib/readarr > /var/log/readarr.log 2>&1 &
echo "Readarr started on port 8787"
EOF
            chmod +x /usr/local/bin/start-readarr
            
            # Start Readarr
            mkdir -p /var/lib/readarr
            /usr/local/bin/start-readarr
            
            return 0
        fi
    fi
    
    log "❌ Readarr installation failed - manual install needed"
    log "💡 Alternative: Use Calibre (already installed) for ebook management"
    return 1
}

install_jellyseerr() {
    log "🎬 Installing Jellyseerr (Request Management)..."
    
    # Try Node.js version if available
    if command -v npm > /dev/null 2>&1; then
        cd /opt
        if git clone https://github.com/Fallenbagel/jellyseerr.git 2>/dev/null; then
            cd jellyseerr
            if npm install --production 2>/dev/null; then
                log "✅ Jellyseerr installed via npm"
                
                # Create startup script
                cat > /usr/local/bin/start-jellyseerr << 'EOF'
#!/bin/bash
cd /opt/jellyseerr
nohup npm start > /var/log/jellyseerr.log 2>&1 &
echo "Jellyseerr started on port 5055"
EOF
                chmod +x /usr/local/bin/start-jellyseerr
                /usr/local/bin/start-jellyseerr
                return 0
            fi
        fi
    fi
    
    log "❌ Jellyseerr installation failed - requires Node.js"
    log "💡 Alternative: Use Sonarr/Radarr directly for requests"
    return 1
}

install_audiobookshelf() {
    log "🎧 Installing AudioBookShelf..."
    
    # Try binary installation
    local abs_url="https://github.com/advplyr/audiobookshelf/releases/latest/download/audiobookshelf-linux"
    
    if curl -L "$abs_url" -o /opt/audiobookshelf 2>/dev/null; then
        chmod +x /opt/audiobookshelf
        log "✅ AudioBookShelf installed to /opt/audiobookshelf"
        
        # Create startup script
        cat > /usr/local/bin/start-audiobookshelf << 'EOF'
#!/bin/bash
mkdir -p /var/lib/audiobookshelf
nohup /opt/audiobookshelf --port=13378 --config=/var/lib/audiobookshelf > /var/log/audiobookshelf.log 2>&1 &
echo "AudioBookShelf started on port 13378"
EOF
        chmod +x /usr/local/bin/start-audiobookshelf
        /usr/local/bin/start-audiobookshelf
        return 0
    fi
    
    log "❌ AudioBookShelf installation failed"
    log "💡 Alternative: Use Jellyfin for audiobook management"
    return 1
}

fix_qbittorrent() {
    log "🔧 Fixing qBittorrent authorization..."
    
    # Reset qBittorrent config to allow web access
    pkill qbittorrent-nox 2>/dev/null || true
    sleep 2
    
    # Create config directory
    mkdir -p /root/.config/qBittorrent
    
    # Start with no authentication initially
    nohup qbittorrent-nox --webui-port=5080 > /var/log/qbittorrent.log 2>&1 &
    
    sleep 5
    
    log "✅ qBittorrent restarted"
    log "🌐 Access: http://localhost:5080"
    log "🔐 Default login: admin/adminadmin (change on first login)"
}

start_calibre_server() {
    log "📖 Starting Calibre Web Server..."
    
    mkdir -p /home/lou/calibre-library
    pkill calibre-server 2>/dev/null || true
    
    nohup calibre-server --port=8083 --with-library=/home/lou/calibre-library > /var/log/calibre.log 2>&1 &
    
    log "✅ Calibre server started on port 8083"
}

show_service_status() {
    log "📊 Checking service status..."
    
    echo ""
    echo "🌐 SERVICE STATUS:"
    echo "===================="
    
    services=(
        "8096:Jellyfin"
        "7878:Radarr" 
        "8989:Sonarr"
        "8686:Lidarr"
        "9117:Jackett"
        "5080:qBittorrent"
        "8191:FlareSolverr"
        "8083:Calibre"
        "8787:Readarr"
        "5055:Jellyseerr"
        "13378:AudioBookShelf"
    )
    
    for service in "${services[@]}"; do
        port="${service%%:*}"
        name="${service##*:}"
        
        if netstat -tln | grep ":$port " > /dev/null 2>&1; then
            echo "  ✅ $name (port $port) - Running"
        else
            echo "  ❌ $name (port $port) - Not running"
        fi
    done
    
    echo ""
    echo "🎯 MAIN SERVICES:"
    echo "  Dashboard: http://localhost:8080"
    echo "  Jellyfin: http://localhost:8096"
    echo "  Sonarr: http://localhost:8989"
    echo "  Radarr: http://localhost:7878"
    echo "  Jackett: http://localhost:9117"
}

case "$1" in
    "readarr")
        install_readarr
        ;;
    "jellyseerr")
        install_jellyseerr
        ;;
    "audiobookshelf")
        install_audiobookshelf
        ;;
    "qbittorrent")
        fix_qbittorrent
        ;;
    "calibre")
        start_calibre_server
        ;;
    "all")
        log "🚀 Installing all optional services..."
        install_readarr
        install_jellyseerr  
        install_audiobookshelf
        fix_qbittorrent
        start_calibre_server
        sleep 5
        show_service_status
        ;;
    "status")
        show_service_status
        ;;
    *)
        echo "Usage: $0 {readarr|jellyseerr|audiobookshelf|qbittorrent|calibre|all|status}"
        echo ""
        echo "🔧 Install Optional Media Stack Services"
        echo "  readarr      - Install Readarr (books/ebooks)"
        echo "  jellyseerr   - Install Jellyseerr (request management)" 
        echo "  audiobookshelf - Install AudioBookShelf (audiobooks)"
        echo "  qbittorrent  - Fix qBittorrent authorization"
        echo "  calibre      - Start Calibre web server"
        echo "  all          - Install all services"
        echo "  status       - Show service status"
        echo ""
        show_service_status
        ;;
esac
