#!/bin/bash

# Configuration section - Customize these paths for your environment
# Use environment variables with sensible defaults
USER_NAME="${USER:-$(whoami)}"
USER_HOME="${HOME:-$(eval echo ~$USER_NAME)}"
DATA_ROOT="${DATA_ROOT:-/media}"
CONFIG_ROOT="${CONFIG_ROOT:-$USER_HOME/.config}"
CACHE_ROOT="${CACHE_ROOT:-$USER_HOME/.cache}"
LOG_ROOT="${LOG_ROOT:-/var/log}"
INSTALL_ROOT="${INSTALL_ROOT:-/opt}"

# 🏠 Garuda Media Stack - Native Installation
# Complete media center solution for Garuda Linux
# Adapted from awesome-stack patterns

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"; }
info() { echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"; }
section() { echo -e "${PURPLE}[$(date +'%H:%M:%S')] ═══${NC} $1 ${PURPLE}═══${NC}"; }

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root. Run as regular user with sudo privileges."
    exit 1
fi

# Banner
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                🏠 Garuda Media Stack Installer              ║
║              Native Installation - No Docker                ║
║                                                              ║
║  🎬 Movies  📺 TV Shows  🎵 Music  📚 Books  🎧 Audiobooks  ║
║                                                              ║
║           Grandmother-Friendly • Professional               ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Pre-installation checks
section "Pre-Installation Checks"

# Check for required system
if ! grep -q "Garuda Linux" /etc/os-release; then
    warn "This script is optimized for Garuda Linux but will attempt to run anyway"
fi

# Check available space
available_space=$(df / | awk 'NR==2{printf "%.0f", $4/1024/1024}')
if [[ $available_space -lt 10 ]]; then
    error "Insufficient disk space. Need at least 10GB free, have ${available_space}GB"
    exit 1
fi

log "System checks passed ✅"
log "Available disk space: ${available_space}GB"

# Create directory structure
section "Creating Directory Structure"

# Create main directories
log "Creating media directories..."
sudo mkdir -p "$DATA_ROOT"/{movies,tv,music,books,audiobooks,podcasts,downloads}
sudo mkdir -p "$CONFIG_ROOT"/media-stack/{radarr,sonarr,lidarr,readarr,jackett,audiobookshelf,calibre-web,pulsarr,jellyseerr}
sudo mkdir -p "$INSTALL_ROOT"/media-stack/{lidarr,readarr,audiobookshelf,pulsarr,jellyseerr}
sudo mkdir -p /var/log/media-stack

# Set proper permissions
sudo chown -R "$USER_NAME:$USER_NAME" "$DATA_ROOT"
sudo chown -R "$USER_NAME:$USER_NAME" "$CONFIG_ROOT"/media-stack
sudo chown -R "$USER_NAME:$USER_NAME" "$LOG_ROOT"/media-stack

log "Directory structure created ✅"

# Update system
section "Updating System Packages"
log "Updating package database..."
sudo pacman -Sy --noconfirm

# Install core packages that are available in repos
section "Installing Core Media Applications"

log "Installing qBittorrent..."
sudo pacman -S --needed --noconfirm qbittorrent

log "Installing Radarr..."
sudo pacman -S --needed --noconfirm radarr

log "Installing Sonarr..."
sudo pacman -S --needed --noconfirm sonarr

log "Installing Jackett..."
sudo pacman -S --needed --noconfirm jackett

log "Installing Calibre (base for Calibre-web)..."
sudo pacman -S --needed --noconfirm calibre python-flask python-pip

log "Core applications installed ✅"

# Install dependencies for manual installations
section "Installing Dependencies"

log "Installing build tools and dependencies..."
sudo pacman -S --needed --noconfirm \
    curl \
    wget \
    unzip \
    tar \
    gzip \
    nodejs \
    npm \
    python \
    python-pip \
    python-flask \
    python-requests \
    sqlite \
    ffmpeg \
    mono \
    aspnet-runtime-6.0 \
    dotnet-runtime-6.0

log "Dependencies installed ✅"

# Create systemd services for applications that need them
section "Creating Systemd Services"

# Enable and start native services
log "Configuring native services..."

# Enable the services that were installed via pacman
sudo systemctl enable --now radarr
sudo systemctl enable --now sonarr  
sudo systemctl enable --now jackett

log "Native services configured ✅"

# Install applications that need manual installation
section "Installing Additional Applications"

# Install Lidarr
log "Installing Lidarr..."
LIDARR_VERSION="2.13.3.4711"
cd /tmp
wget -q "https://github.com/Lidarr/Lidarr/releases/download/v${LIDARR_VERSION}/Lidarr.master.${LIDARR_VERSION}.linux-core-x64.tar.gz"
sudo tar -xzf "Lidarr.master.${LIDARR_VERSION}.linux-core-x64.tar.gz" -C "$INSTALL_ROOT"/media-stack/
sudo chown -R lou:lou "$INSTALL_ROOT"/media-stack/Lidarr
rm "Lidarr.master.${LIDARR_VERSION}.linux-core-x64.tar.gz"

# Install Readarr
log "Installing Readarr..."
READARR_VERSION="0.4.5.2671"
wget -q "https://github.com/Readarr/Readarr/releases/download/v${READARR_VERSION}/Readarr.develop.${READARR_VERSION}.linux-core-x64.tar.gz"
sudo tar -xzf "Readarr.develop.${READARR_VERSION}.linux-core-x64.tar.gz" -C "$INSTALL_ROOT"/media-stack/
sudo chown -R lou:lou "$INSTALL_ROOT"/media-stack/Readarr
rm "Readarr.develop.${READARR_VERSION}.linux-core-x64.tar.gz"

# Install Audiobookshelf
log "Installing Audiobookshelf..."
AUDIOBOOKSHELF_VERSION="2.18.4"
wget -q "https://github.com/advplyr/audiobookshelf/releases/download/v${AUDIOBOOKSHELF_VERSION}/audiobookshelf-${AUDIOBOOKSHELF_VERSION}-linux.tar.gz"
sudo tar -xzf "audiobookshelf-${AUDIOBOOKSHELF_VERSION}-linux.tar.gz" -C "$INSTALL_ROOT"/media-stack/
sudo chown -R lou:lou "$INSTALL_ROOT"/media-stack/audiobookshelf
rm "audiobookshelf-${AUDIOBOOKSHELF_VERSION}-linux.tar.gz"

# Install Jellyseerr  
log "Installing Jellyseerr..."
cd "$INSTALL_ROOT"/media-stack/
sudo git clone https://github.com/Fallenbagel/jellyseerr.git
cd jellyseerr
sudo npm ci --production && sudo npm run build
sudo chown -R lou:lou "$INSTALL_ROOT"/media-stack/jellyseerr

# Install Calibre-web
log "Installing Calibre-web..."
sudo pip install calibre-web

# Install Pulsarr
log "Installing Pulsarr..."
cd "$INSTALL_ROOT"/media-stack/
sudo git clone https://github.com/jamcalli/pulsarr.git
cd pulsarr
sudo npm ci --production
sudo chown -R lou:lou "$INSTALL_ROOT"/media-stack/pulsarr

log "Additional applications installed ✅"

# Create systemd service files for manual installations
section "Creating Systemd Service Files"

# Lidarr service
log "Creating Lidarr systemd service..."
sudo tee /etc/systemd/system/lidarr.service > /dev/null << EOF
[Unit]
Description=Lidarr Daemon
After=network.target

[Service]
User=lou
Group=lou
Type=notify
ExecStart=$INSTALL_ROOT/media-stack/Lidarr/Lidarr -nobrowser -data=$CONFIG_ROOT/media-stack/lidarr
TimeoutStopSec=20
KillMode=process
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Readarr service  
log "Creating Readarr systemd service..."
sudo tee /etc/systemd/system/readarr.service > /dev/null << EOF
[Unit]
Description=Readarr Daemon
After=network.target

[Service]
User=lou
Group=lou
Type=notify
ExecStart=$INSTALL_ROOT/media-stack/Readarr/Readarr -nobrowser -data=$CONFIG_ROOT/media-stack/readarr
TimeoutStopSec=20
KillMode=process
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Audiobookshelf service
log "Creating Audiobookshelf systemd service..."
sudo tee /etc/systemd/system/audiobookshelf.service > /dev/null << EOF
[Unit]
Description=Audiobookshelf Server
After=network.target

[Service]
User=lou
Group=lou
Type=simple
WorkingDirectory=$INSTALL_ROOT/media-stack/audiobookshelf
ExecStart=$INSTALL_ROOT/media-stack/audiobookshelf/audiobookshelf --config $CONFIG_ROOT/media-stack/audiobookshelf --metadata $CONFIG_ROOT/media-stack/audiobookshelf/metadata
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Jellyseerr service
log "Creating Jellyseerr systemd service..."
sudo tee /etc/systemd/system/jellyseerr.service > /dev/null << EOF
[Unit]
Description=Jellyseerr Request Management
After=network.target

[Service]
User=lou
Group=lou
Type=simple
WorkingDirectory=$INSTALL_ROOT/media-stack/jellyseerr
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=production
Environment=CONFIG_DIRECTORY=$CONFIG_ROOT/media-stack/jellyseerr

[Install]
WantedBy=multi-user.target
EOF

# Pulsarr service
log "Creating Pulsarr systemd service..."
sudo tee /etc/systemd/system/pulsarr.service > /dev/null << EOF
[Unit]
Description=Pulsarr Plex Watchlist Monitor
After=network.target

[Service]
User=lou
Group=lou
Type=simple
WorkingDirectory=$INSTALL_ROOT/media-stack/pulsarr
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=production
Environment=CONFIG_DIR=$CONFIG_ROOT/media-stack/pulsarr

[Install]
WantedBy=multi-user.target
EOF

# Calibre-web service
log "Creating Calibre-web systemd service..."
sudo tee /etc/systemd/system/calibre-web.service > /dev/null << EOF
[Unit]
Description=Calibre-web Ebook Server
After=network.target

[Service]
User=lou
Group=lou
Type=simple
ExecStart=/usr/bin/cps -c $CONFIG_ROOT/media-stack/calibre-web
WorkingDirectory=$CONFIG_ROOT/media-stack/calibre-web
Restart=on-failure
RestartSec=5
Environment=CALIBRE_DBPATH=$DATA_ROOT/books

[Install]
WantedBy=multi-user.target
EOF

log "Systemd service files created ✅"

# Reload systemd and enable services
section "Enabling Services"

sudo systemctl daemon-reload

services=("lidarr" "readarr" "audiobookshelf" "jellyseerr" "pulsarr" "calibre-web")

for service in "${services[@]}"; do
    log "Enabling $service..."
    sudo systemctl enable "$service"
    log "Starting $service..."
    sudo systemctl start "$service" || warn "Could not start $service - check configuration"
done

log "All services enabled and started ✅"

# Create management scripts
section "Creating Management Scripts"

# Health check script
cat > scripts/health-check.sh << 'EOF'
#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m' 
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🏠 Garuda Media Stack - Health Check${NC}"
echo "════════════════════════════════════════════"

services=("radarr" "sonarr" "lidarr" "readarr" "jackett" "audiobookshelf" "jellyseerr" "pulsarr" "calibre-web" "qbittorrent" "jellyfin-server" "plexmediaserver")

for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "✅ ${GREEN}$service${NC}: Running"
        # Check if service is responding on expected port
        case $service in
            "radarr") curl -s http://localhost:7878 >/dev/null && echo "   🌐 Web interface accessible" || echo "   ⚠️  Web interface not responding" ;;
            "sonarr") curl -s http://localhost:8989 >/dev/null && echo "   🌐 Web interface accessible" || echo "   ⚠️  Web interface not responding" ;;
            "lidarr") curl -s http://localhost:8686 >/dev/null && echo "   🌐 Web interface accessible" || echo "   ⚠️  Web interface not responding" ;;
            "jellyseerr") curl -s http://localhost:5055 >/dev/null && echo "   🌐 Web interface accessible" || echo "   ⚠️  Web interface not responding" ;;
        esac
    elif systemctl list-unit-files | grep -q "^$service"; then
        echo -e "❌ ${RED}$service${NC}: Stopped/Failed"
    else
        echo -e "⭕ ${YELLOW}$service${NC}: Not installed/configured"
    fi
done

echo ""
echo -e "${GREEN}📊 System Resources:${NC}"
echo "Memory Usage: $(free -h | awk 'NR==2{printf "%.1f%%", $3/$2*100}')"
echo "Disk Usage: $(df / | awk 'NR==2{printf "%.1f%%", $5}' | sed 's/%//')"
EOF

chmod +x scripts/health-check.sh

# Service start script
cat > start-all-services.sh << 'EOF'
#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}🚀 Starting Garuda Media Stack Services${NC}"
echo "════════════════════════════════════════════"

services=("radarr" "sonarr" "lidarr" "readarr" "jackett" "audiobookshelf" "jellyseerr" "pulsarr" "calibre-web")

for service in "${services[@]}"; do
    echo "Starting $service..."
    sudo systemctl start "$service"
done

echo ""
echo "✅ All services started!"
echo "Run ./scripts/health-check.sh to verify status"
EOF

chmod +x start-all-services.sh

# Service stop script
cat > stop-all-services.sh << 'EOF'
#!/bin/bash

RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}🛑 Stopping Garuda Media Stack Services${NC}"
echo "══════════════════════════════════════════"

services=("radarr" "sonarr" "lidarr" "readarr" "jackett" "audiobookshelf" "jellyseerr" "pulsarr" "calibre-web")

for service in "${services[@]}"; do
    echo "Stopping $service..."
    sudo systemctl stop "$service"
done

echo ""
echo "✅ All services stopped!"
EOF

chmod +x stop-all-services.sh

log "Management scripts created ✅"

# Create service URLs summary
section "Creating Quick Access Guide"

cat > SERVICE_URLS.md << EOF
# 🌐 Garuda Media Stack - Service Access URLs

## 🎬 Media Servers
- **🎥 Jellyfin**: [http://localhost:8096](http://localhost:8096) - Open-source media server
- **🎬 Plex**: [http://localhost:32400/web](http://localhost:32400/web) - Premium media server

## 🔧 Content Management  
- **🎬 Radarr**: [http://localhost:7878](http://localhost:7878) - Movie automation
- **📺 Sonarr**: [http://localhost:8989](http://localhost:8989) - TV show automation
- **🎵 Lidarr**: [http://localhost:8686](http://localhost:8686) - Music automation  
- **📚 Readarr**: [http://localhost:8787](http://localhost:8787) - Book automation

## 📖 Reading & Listening
- **📖 Calibre-web**: [http://localhost:8083](http://localhost:8083) - Ebook reader
- **🎧 Audiobookshelf**: [http://localhost:13378](http://localhost:13378) - Audiobook server

## 🔍 Search & Downloads
- **🔍 Jackett**: [http://localhost:9117](http://localhost:9117) - Indexer proxy
- **⬇️ qBittorrent**: [http://localhost:5080](http://localhost:5080) - Torrent client
  - **Default credentials**: admin / adminadmin
  - **⚠️ Change password after first login!**

## 🎯 Request Systems
- **🔄 Pulsarr**: [http://localhost:3030](http://localhost:3030) - Plex watchlist automation
- **🎯 Jellyseerr**: [http://localhost:5055](http://localhost:5055) - Jellyfin request management

## 🏠 Quick Commands

\`\`\`bash
# Check all service status
./scripts/health-check.sh

# Start all services
./start-all-services.sh

# Stop all services  
./stop-all-services.sh

# View service logs
sudo journalctl -u radarr -f
\`\`\`

## 📝 Setup Notes

1. **First-time setup**: Access each service and complete initial configuration
2. **Configure indexers**: Set up Jackett with your preferred indexers
3. **Connect downloaders**: Configure qBittorrent in each *arr application
4. **Add media libraries**: Set up libraries in Plex and Jellyfin
5. **Configure automation**: Set up Pulsarr and Jellyseerr for requests

**🎉 Enjoy your complete native media stack!**
EOF

# Installation complete
section "Installation Complete"

echo -e "${GREEN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                   🎉 Installation Complete! 🎉              ║
║                                                              ║
║         Your Garuda Media Stack is ready to use!            ║
║                                                              ║
║  Next steps:                                                 ║
║  1. Run: ./scripts/health-check.sh                          ║
║  2. Access services via SERVICE_URLS.md                     ║
║  3. Configure each service through web interfaces           ║
║                                                              ║
║              🏠 Grandmother-Friendly • Native               ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

log "📋 Quick access: cat SERVICE_URLS.md"
log "🔍 Health check: ./scripts/health-check.sh"
log "🚀 Start services: ./start-all-services.sh"

echo ""
echo -e "${CYAN}🔗 Main dashboard coming soon at: http://localhost:8600${NC}"
echo -e "${CYAN}📱 Mobile-friendly interface for grandmother access!${NC}"
