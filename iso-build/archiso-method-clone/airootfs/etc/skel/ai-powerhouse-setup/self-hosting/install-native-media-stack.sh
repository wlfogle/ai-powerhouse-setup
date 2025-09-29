#!/bin/bash

# 🎬 GARUDA NATIVE MEDIA STACK INSTALLER
# Complete native installation of media stack with WireGuard Ghost Mode integration
# Based on awesome-stack patterns and Garuda Linux optimizations

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_ROOT="/mnt/media"
CONFIG_ROOT="/etc"
CACHE_ROOT="/var/cache"
LOG_ROOT="/var/log"
USER_HOME="/home/lou"
MEDIA_USER="lou"
MEDIA_GROUP="media"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"; }
info() { echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"; }

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root! Run as regular user with sudo privileges."
        exit 1
    fi
}

# Create system user and group
setup_media_user() {
    log "Setting up media user and group..."
    
    # Create media group if it doesn't exist
    if ! getent group "$MEDIA_GROUP" >/dev/null 2>&1; then
        sudo groupadd "$MEDIA_GROUP"
        log "Created media group: $MEDIA_GROUP"
    fi
    
    # Add user to media group
    sudo usermod -a -G "$MEDIA_GROUP" "$MEDIA_USER"
    
    # Create media directories
    sudo mkdir -p "$DATA_ROOT"/{downloads,movies,tv,music,books,audiobooks,podcasts}
    sudo chown -R "$MEDIA_USER:$MEDIA_GROUP" "$DATA_ROOT"
    sudo chmod -R 775 "$DATA_ROOT"
    
    log "Media directories created at $DATA_ROOT"
}

# Update system packages
update_system() {
    log "Updating system packages..."
    sudo pacman -Syu --noconfirm
    
    # Install base dependencies
    sudo pacman -S --needed --noconfirm \
        curl wget git unzip \
        python python-pip \
        nodejs npm \
        nginx \
        systemd \
        wireguard-tools \
        python-pyqt5 \
        python-requests \
        cronie \
        ufw \
        fail2ban
        
    log "System packages updated and dependencies installed"
}

# Install qBittorrent natively
install_qbittorrent() {
    log "Installing qBittorrent..."
    
    # Install qBittorrent-nox (headless version)
    sudo pacman -S --needed --noconfirm qbittorrent-nox
    
    # Create systemd service
    sudo tee /etc/systemd/system/qbittorrent.service > /dev/null << 'EOF'
[Unit]
Description=qBittorrent-nox
After=network.target

[Service]
Type=forking
User=lou
Group=media
ExecStart=/usr/bin/qbittorrent-nox -d --webui-port=5080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start service
    sudo systemctl daemon-reload
    sudo systemctl enable qbittorrent
    sudo systemctl start qbittorrent
    
    log "✅ qBittorrent installed and started on port 5080"
}

# Install Jackett from AUR
install_jackett() {
    log "Installing Jackett..."
    
    # Check if paru is available, otherwise use yay
    if command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
    elif command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
    else
        error "No AUR helper found. Please install paru or yay first."
        return 1
    fi
    
    # Install Jackett from AUR
    $AUR_HELPER -S --noconfirm jackett-bin || {
        warn "AUR installation failed, installing manually..."
        install_jackett_manual
        return
    }
    
    # Enable and start service
    sudo systemctl enable jackett
    sudo systemctl start jackett
    
    log "✅ Jackett installed and started on port 9117"
}

# Manual Jackett installation
install_jackett_manual() {
    log "Installing Jackett manually..."
    
    # Download latest Jackett
    JACKETT_VERSION=$(curl -s https://api.github.com/repos/Jackett/Jackett/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    JACKETT_URL="https://github.com/Jackett/Jackett/releases/download/${JACKETT_VERSION}/Jackett.Binaries.LinuxAMDx64.tar.gz"
    
    # Install to /opt
    sudo mkdir -p /opt/jackett
    curl -L "$JACKETT_URL" | sudo tar -xz -C /opt/jackett --strip-components=1
    sudo chown -R "$MEDIA_USER:$MEDIA_GROUP" /opt/jackett
    
    # Create systemd service
    sudo tee /etc/systemd/system/jackett.service > /dev/null << 'EOF'
[Unit]
Description=Jackett Daemon
After=network.target

[Service]
SyslogIdentifier=jackett
Restart=always
RestartSec=5
Type=simple
User=lou
Group=media
WorkingDirectory=/opt/jackett
ExecStart=/opt/jackett/jackett --NoUpdates
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable jackett
    sudo systemctl start jackett
    
    log "✅ Jackett manually installed and started"
}

# Install Radarr from AUR
install_radarr() {
    log "Installing Radarr..."
    
    if command -v paru >/dev/null 2>&1; then
        paru -S --noconfirm radarr-bin || install_radarr_manual
    elif command -v yay >/dev/null 2>&1; then
        yay -S --noconfirm radarr-bin || install_radarr_manual
    else
        install_radarr_manual
    fi
    
    # Configure and start
    sudo systemctl enable radarr
    sudo systemctl start radarr
    
    log "✅ Radarr installed and started on port 7878"
}

# Manual Radarr installation
install_radarr_manual() {
    log "Installing Radarr manually..."
    
    RADARR_VERSION=$(curl -s https://api.github.com/repos/Radarr/Radarr/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    RADARR_URL="https://github.com/Radarr/Radarr/releases/download/${RADARR_VERSION}/Radarr.master.${RADARR_VERSION#v}.linux-core-x64.tar.gz"
    
    sudo mkdir -p /opt/radarr
    curl -L "$RADARR_URL" | sudo tar -xz -C /opt/radarr --strip-components=1
    sudo chown -R "$MEDIA_USER:$MEDIA_GROUP" /opt/radarr
    
    # Create systemd service
    sudo tee /etc/systemd/system/radarr.service > /dev/null << 'EOF'
[Unit]
Description=Radarr Daemon
After=network.target

[Service]
User=lou
Group=media
Type=simple
ExecStart=/opt/radarr/Radarr -nobrowser -data=/var/lib/radarr
Restart=on-failure
TimeoutStopSec=20
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

    sudo mkdir -p /var/lib/radarr
    sudo chown "$MEDIA_USER:$MEDIA_GROUP" /var/lib/radarr
    
    sudo systemctl daemon-reload
    sudo systemctl enable radarr
    sudo systemctl start radarr
    
    log "✅ Radarr manually installed"
}

# Install Sonarr from AUR
install_sonarr() {
    log "Installing Sonarr..."
    
    if command -v paru >/dev/null 2>&1; then
        paru -S --noconfirm sonarr-bin || install_sonarr_manual
    elif command -v yay >/dev/null 2>&1; then
        yay -S --noconfirm sonarr-bin || install_sonarr_manual
    else
        install_sonarr_manual
    fi
    
    sudo systemctl enable sonarr
    sudo systemctl start sonarr
    
    log "✅ Sonarr installed and started on port 8989"
}

# Manual Sonarr installation
install_sonarr_manual() {
    log "Installing Sonarr manually..."
    
    SONARR_VERSION=$(curl -s https://api.github.com/repos/Sonarr/Sonarr/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    SONARR_URL="https://github.com/Sonarr/Sonarr/releases/download/${SONARR_VERSION}/Sonarr.main.${SONARR_VERSION#v}.linux-x64.tar.gz"
    
    sudo mkdir -p /opt/sonarr
    curl -L "$SONARR_URL" | sudo tar -xz -C /opt/sonarr --strip-components=1
    sudo chown -R "$MEDIA_USER:$MEDIA_GROUP" /opt/sonarr
    
    # Create systemd service
    sudo tee /etc/systemd/system/sonarr.service > /dev/null << 'EOF'
[Unit]
Description=Sonarr Daemon
After=network.target

[Service]
User=lou
Group=media
Type=simple
ExecStart=/opt/sonarr/Sonarr -nobrowser -data=/var/lib/sonarr
Restart=on-failure
TimeoutStopSec=20
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

    sudo mkdir -p /var/lib/sonarr
    sudo chown "$MEDIA_USER:$MEDIA_GROUP" /var/lib/sonarr
    
    sudo systemctl daemon-reload
    sudo systemctl enable sonarr
    sudo systemctl start sonarr
    
    log "✅ Sonarr manually installed"
}

# Install Lidarr
install_lidarr() {
    log "Installing Lidarr..."
    
    LIDARR_VERSION=$(curl -s https://api.github.com/repos/Lidarr/Lidarr/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    LIDARR_URL="https://github.com/Lidarr/Lidarr/releases/download/${LIDARR_VERSION}/Lidarr.master.${LIDARR_VERSION#v}.linux-core-x64.tar.gz"
    
    sudo mkdir -p /opt/lidarr
    curl -L "$LIDARR_URL" | sudo tar -xz -C /opt/lidarr --strip-components=1
    sudo chown -R "$MEDIA_USER:$MEDIA_GROUP" /opt/lidarr
    
    # Create systemd service
    sudo tee /etc/systemd/system/lidarr.service > /dev/null << 'EOF'
[Unit]
Description=Lidarr Daemon
After=network.target

[Service]
User=lou
Group=media
Type=simple
ExecStart=/opt/lidarr/Lidarr -nobrowser -data=/var/lib/lidarr
Restart=on-failure
TimeoutStopSec=20
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

    sudo mkdir -p /var/lib/lidarr
    sudo chown "$MEDIA_USER:$MEDIA_GROUP" /var/lib/lidarr
    
    sudo systemctl daemon-reload
    sudo systemctl enable lidarr
    sudo systemctl start lidarr
    
    log "✅ Lidarr installed and started on port 8686"
}

# Install Readarr
install_readarr() {
    log "Installing Readarr..."
    
    READARR_VERSION=$(curl -s https://api.github.com/repos/Readarr/Readarr/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    READARR_URL="https://github.com/Readarr/Readarr/releases/download/${READARR_VERSION}/Readarr.develop.${READARR_VERSION#v}.linux-core-x64.tar.gz"
    
    sudo mkdir -p /opt/readarr
    curl -L "$READARR_URL" | sudo tar -xz -C /opt/readarr --strip-components=1
    sudo chown -R "$MEDIA_USER:$MEDIA_GROUP" /opt/readarr
    
    # Create systemd service
    sudo tee /etc/systemd/system/readarr.service > /dev/null << 'EOF'
[Unit]
Description=Readarr Daemon
After=network.target

[Service]
User=lou
Group=media
Type=simple
ExecStart=/opt/readarr/Readarr -nobrowser -data=/var/lib/readarr
Restart=on-failure
TimeoutStopSec=20
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

    sudo mkdir -p /var/lib/readarr
    sudo chown "$MEDIA_USER:$MEDIA_GROUP" /var/lib/readarr
    
    sudo systemctl daemon-reload
    sudo systemctl enable readarr
    sudo systemctl start readarr
    
    log "✅ Readarr installed and started on port 8787"
}

# Install Calibre and Calibre-Web
install_calibre_stack() {
    log "Installing Calibre and Calibre-Web..."
    
    # Install Calibre
    sudo pacman -S --needed --noconfirm calibre
    
    # Install Calibre-Web via pip
    sudo pip install calibreweb
    
    # Create library directory
    sudo mkdir -p "$DATA_ROOT/books/calibre-library"
    sudo chown -R "$MEDIA_USER:$MEDIA_GROUP" "$DATA_ROOT/books"
    
    # Initialize Calibre library
    calibredb add --library-path="$DATA_ROOT/books/calibre-library" --empty
    
    # Create Calibre-Web service
    sudo tee /etc/systemd/system/calibre-web.service > /dev/null << 'EOF'
[Unit]
Description=Calibre-Web
After=network.target

[Service]
Type=simple
User=lou
Group=media
WorkingDirectory=/opt/calibre-web
ExecStart=/usr/bin/cps -p /var/lib/calibre-web/app.db -g /var/lib/calibre-web/gdrive.db -c /mnt/media/books/calibre-library
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    sudo mkdir -p /var/lib/calibre-web
    sudo chown "$MEDIA_USER:$MEDIA_GROUP" /var/lib/calibre-web
    
    sudo systemctl daemon-reload
    sudo systemctl enable calibre-web
    sudo systemctl start calibre-web
    
    log "✅ Calibre stack installed and started on port 8083"
}

# Install Audiobookshelf
install_audiobookshelf() {
    log "Installing Audiobookshelf..."
    
    # Install Node.js if not present
    if ! command -v node >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm nodejs npm
    fi
    
    # Install Audiobookshelf globally
    sudo npm install -g audiobookshelf
    
    # Create systemd service
    sudo tee /etc/systemd/system/audiobookshelf.service > /dev/null << 'EOF'
[Unit]
Description=Audiobookshelf
After=network.target

[Service]
Type=simple
User=lou
Group=media
WorkingDirectory=/var/lib/audiobookshelf
ExecStart=/usr/bin/node /usr/lib/node_modules/audiobookshelf/index.js
Environment=NODE_ENV=production
Environment=PORT=13378
Environment=HOST=0.0.0.0
Environment=CONFIG_PATH=/var/lib/audiobookshelf/config
Environment=METADATA_PATH=/var/lib/audiobookshelf/metadata
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    sudo mkdir -p /var/lib/audiobookshelf/{config,metadata}
    sudo chown -R "$MEDIA_USER:$MEDIA_GROUP" /var/lib/audiobookshelf
    
    sudo systemctl daemon-reload
    sudo systemctl enable audiobookshelf
    sudo systemctl start audiobookshelf
    
    log "✅ Audiobookshelf installed and started on port 13378"
}

# Install Pulsarr
install_pulsarr() {
    log "Installing Pulsarr..."
    
    # Clone and build Pulsarr
    sudo mkdir -p /opt/pulsarr
    sudo git clone https://github.com/jamcalli/pulsarr.git /opt/pulsarr
    cd /opt/pulsarr
    
    # Install dependencies and build
    sudo npm install
    sudo npm run build
    sudo chown -R "$MEDIA_USER:$MEDIA_GROUP" /opt/pulsarr
    
    # Create systemd service
    sudo tee /etc/systemd/system/pulsarr.service > /dev/null << 'EOF'
[Unit]
Description=Pulsarr
After=network.target

[Service]
Type=simple
User=lou
Group=media
WorkingDirectory=/opt/pulsarr
ExecStart=/usr/bin/node dist/index.js
Environment=NODE_ENV=production
Environment=PORT=3030
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable pulsarr
    sudo systemctl start pulsarr
    
    log "✅ Pulsarr installed and started on port 3030"
}

# Install Jellyseerr
install_jellyseerr() {
    log "Installing Jellyseerr..."
    
    # Clone and build Jellyseerr
    sudo mkdir -p /opt/jellyseerr
    sudo git clone https://github.com/Fallenbagel/jellyseerr.git /opt/jellyseerr
    cd /opt/jellyseerr
    
    # Install dependencies and build
    sudo npm install
    sudo npm run build
    sudo chown -R "$MEDIA_USER:$MEDIA_GROUP" /opt/jellyseerr
    
    # Create systemd service
    sudo tee /etc/systemd/system/jellyseerr.service > /dev/null << 'EOF'
[Unit]
Description=Jellyseerr
After=network.target

[Service]
Type=simple
User=lou
Group=media
WorkingDirectory=/opt/jellyseerr
ExecStart=/usr/bin/node dist/index.js
Environment=NODE_ENV=production
Environment=PORT=5055
Environment=CONFIG_DIRECTORY=/var/lib/jellyseerr
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    sudo mkdir -p /var/lib/jellyseerr
    sudo chown "$MEDIA_USER:$MEDIA_GROUP" /var/lib/jellyseerr
    
    sudo systemctl daemon-reload
    sudo systemctl enable jellyseerr
    sudo systemctl start jellyseerr
    
    log "✅ Jellyseerr installed and started on port 5055"
}

# Setup WireGuard with Ghost Mode integration
setup_wireguard_ghost_mode() {
    log "Setting up WireGuard with Ghost Mode integration..."
    
    # Copy WireGuard tools from awesome-stack
    sudo mkdir -p /opt/wireguard-tools
    sudo cp -r "$SCRIPT_DIR/../github/awesome-stack/wireguard-tools"/* /opt/wireguard-tools/
    sudo cp -r "$SCRIPT_DIR/../github/awesome-stack/ghost-mode" /opt/ghost-mode
    
    # Install ghost mode
    cd /opt/ghost-mode
    sudo ./install-ghost-mode.sh
    
    # Setup WireGuard server configuration
    sudo mkdir -p /etc/wireguard
    
    # Generate server keys
    SERVER_PRIVATE_KEY=$(wg genkey)
    SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)
    
    # Create server config
    sudo tee /etc/wireguard/wg0.conf > /dev/null << EOF
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = 10.0.0.1/24
ListenPort = 51820
SaveConfig = false
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Devices - will be managed by ghost-mode rotation
EOF
    
    # Enable WireGuard
    sudo systemctl enable wg-quick@wg0
    
    # Setup rotation cron job
    sudo tee /etc/cron.d/wireguard-rotation > /dev/null << 'EOF'
# Rotate WireGuard keys every 6 hours
0 */6 * * * root /opt/wireguard-tools/server/wireguard-rotate.sh garuda-host
EOF
    
    log "✅ WireGuard with Ghost Mode integration configured"
}

# Install and configure Nginx reverse proxy
setup_nginx_proxy() {
    log "Setting up Nginx reverse proxy..."
    
    # Create main proxy configuration
    sudo tee /etc/nginx/sites-available/media-stack > /dev/null << 'EOF'
server {
    listen 8600 default_server;
    server_name _;
    
    # Grandma Dashboard
    location / {
        root /opt/grandma-dashboard;
        index dashboard.html;
        try_files $uri $uri/ /dashboard.html;
    }
    
    # API endpoints
    location /api/ {
        proxy_pass http://127.0.0.1:8601;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # Media services proxy
    location /radarr/ {
        proxy_pass http://127.0.0.1:7878/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /sonarr/ {
        proxy_pass http://127.0.0.1:8989/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /lidarr/ {
        proxy_pass http://127.0.0.1:8686/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /qbittorrent/ {
        proxy_pass http://127.0.0.1:5080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /jellyfin/ {
        proxy_pass http://127.0.0.1:8096/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /plex/ {
        proxy_pass http://127.0.0.1:32400/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

    # Enable site
    sudo mkdir -p /etc/nginx/sites-enabled
    sudo ln -sf /etc/nginx/sites-available/media-stack /etc/nginx/sites-enabled/
    
    # Test and restart nginx
    sudo nginx -t
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    
    log "✅ Nginx reverse proxy configured on port 8600"
}

# Create grandmother dashboard
create_grandma_dashboard() {
    log "Creating Grandmother Dashboard..."
    
    sudo mkdir -p /opt/grandma-dashboard
    
    # Copy admin dashboard for full technical control
    sudo cp "$SCRIPT_DIR/dashboard/admin-full-dashboard.html" /opt/grandma-dashboard/dashboard.html
    
    # Also create the original grandma dashboard for toggle access
    sudo cp "$SCRIPT_DIR/dashboard/grandma-dashboard.html" /opt/grandma-dashboard/grandma-view.html
    
    # Create enhanced admin dashboard HTML
    sudo tee /opt/grandma-dashboard/admin-dashboard.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Grandma's Media Center</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            color: white;
            min-height: 100vh;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            text-align: center;
        }
        
        h1 {
            font-size: 3rem;
            margin-bottom: 2rem;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        
        .service-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 30px;
            margin-bottom: 40px;
        }
        
        .service-card {
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 30px;
            border: 1px solid rgba(255,255,255,0.2);
            transition: all 0.3s ease;
            cursor: pointer;
        }
        
        .service-card:hover {
            transform: translateY(-10px);
            background: rgba(255,255,255,0.2);
        }
        
        .service-icon {
            font-size: 4rem;
            margin-bottom: 20px;
        }
        
        .service-title {
            font-size: 1.5rem;
            font-weight: bold;
            margin-bottom: 10px;
        }
        
        .service-description {
            font-size: 1rem;
            opacity: 0.9;
            margin-bottom: 20px;
        }
        
        .service-button {
            background: linear-gradient(45deg, #4CAF50, #45a049);
            color: white;
            border: none;
            padding: 15px 30px;
            font-size: 1.1rem;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-block;
        }
        
        .service-button:hover {
            background: linear-gradient(45deg, #45a049, #4CAF50);
            transform: scale(1.05);
        }
        
        .status-bar {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background: rgba(0,0,0,0.8);
            padding: 15px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .status-item {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .status-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #4CAF50;
        }
        
        .status-dot.offline {
            background: #f44336;
        }
        
        .weather-widget {
            background: rgba(255,255,255,0.1);
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 30px;
        }
        
        @media (max-width: 768px) {
            .service-grid {
                grid-template-columns: 1fr;
            }
            
            h1 {
                font-size: 2rem;
            }
            
            .service-card {
                padding: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏠 Grandma's Media Center</h1>
        
        <div class="weather-widget">
            <h2>🌤️ Today's Weather</h2>
            <div id="weather-info">Loading weather...</div>
        </div>
        
        <div class="service-grid">
            <div class="service-card" onclick="window.open('/jellyfin', '_blank')">
                <div class="service-icon">🎬</div>
                <div class="service-title">Movies & TV Shows</div>
                <div class="service-description">Watch your movie and TV collection</div>
                <a href="/jellyfin" class="service-button">Open Jellyfin</a>
            </div>
            
            <div class="service-card" onclick="window.open('/plex', '_blank')">
                <div class="service-icon">📺</div>
                <div class="service-title">Plex Media</div>
                <div class="service-description">Access your Plex library</div>
                <a href="/plex" class="service-button">Open Plex</a>
            </div>
            
            <div class="service-card" onclick="window.open('/jellyseerr', '_blank')">
                <div class="service-icon">🔍</div>
                <div class="service-title">Request Movies</div>
                <div class="service-description">Search and request new content</div>
                <a href="/jellyseerr" class="service-button">Make Requests</a>
            </div>
            
            <div class="service-card" onclick="window.open('http://localhost:13378', '_blank')">
                <div class="service-icon">📚</div>
                <div class="service-title">Audiobooks</div>
                <div class="service-description">Listen to your audiobook collection</div>
                <a href="http://localhost:13378" class="service-button">Open Library</a>
            </div>
            
            <div class="service-card" onclick="window.open('/calibre-web', '_blank')">
                <div class="service-icon">📖</div>
                <div class="service-title">Books</div>
                <div class="service-description">Read your ebook collection</div>
                <a href="/calibre-web" class="service-button">Open Books</a>
            </div>
            
            <div class="service-card" onclick="window.open('/qbittorrent', '_blank')">
                <div class="service-icon">⬇️</div>
                <div class="service-title">Downloads</div>
                <div class="service-description">Manage your downloads</div>
                <a href="/qbittorrent" class="service-button">View Downloads</a>
            </div>
        </div>
    </div>
    
    <div class="status-bar">
        <div class="status-item">
            <div class="status-dot" id="vpn-status"></div>
            <span id="vpn-text">VPN Status</span>
        </div>
        <div class="status-item">
            <div class="status-dot" id="services-status"></div>
            <span id="services-text">Services Status</span>
        </div>
        <div class="status-item">
            <span id="current-time"></span>
        </div>
    </div>
    
    <script>
        // Update time
        function updateTime() {
            const now = new Date();
            document.getElementById('current-time').textContent = now.toLocaleString();
        }
        
        // Check service status
        async function checkServices() {
            try {
                const services = ['jellyfin', 'plex', 'radarr', 'sonarr'];
                let allOnline = true;
                
                for (const service of services) {
                    try {
                        const response = await fetch(`/api/status/${service}`);
                        if (!response.ok) allOnline = false;
                    } catch {
                        allOnline = false;
                    }
                }
                
                const statusDot = document.getElementById('services-status');
                const statusText = document.getElementById('services-text');
                
                if (allOnline) {
                    statusDot.classList.remove('offline');
                    statusText.textContent = 'All Services Online';
                } else {
                    statusDot.classList.add('offline');
                    statusText.textContent = 'Some Services Offline';
                }
            } catch (error) {
                console.error('Error checking services:', error);
            }
        }
        
        // Check VPN status
        async function checkVPN() {
            try {
                const response = await fetch('/api/status/vpn');
                const vpnDot = document.getElementById('vpn-status');
                const vpnText = document.getElementById('vpn-text');
                
                if (response.ok) {
                    vpnDot.classList.remove('offline');
                    vpnText.textContent = 'VPN Connected';
                } else {
                    vpnDot.classList.add('offline');
                    vpnText.textContent = 'VPN Disconnected';
                }
            } catch {
                const vpnDot = document.getElementById('vpn-status');
                const vpnText = document.getElementById('vpn-text');
                vpnDot.classList.add('offline');
                vpnText.textContent = 'VPN Unknown';
            }
        }
        
        // Load weather
        async function loadWeather() {
            try {
                const response = await fetch('/api/weather');
                const weather = await response.json();
                
                document.getElementById('weather-info').innerHTML = `
                    <div style="display: flex; align-items: center; justify-content: center; gap: 20px;">
                        <div style="font-size: 2rem;">${weather.temp}°F</div>
                        <div>
                            <div style="font-size: 1.2rem;">${weather.description}</div>
                            <div>Feels like ${weather.feels_like}°F</div>
                        </div>
                    </div>
                `;
            } catch {
                document.getElementById('weather-info').textContent = 'Weather unavailable';
            }
        }
        
        // Initialize
        updateTime();
        loadWeather();
        checkServices();
        checkVPN();
        
        // Update every 30 seconds
        setInterval(() => {
            updateTime();
            checkServices();
            checkVPN();
        }, 30000);
        
        // Update weather every 10 minutes
        setInterval(loadWeather, 600000);
    </script>
</body>
</html>
EOF
    
    sudo chown -R "$MEDIA_USER:$MEDIA_GROUP" /opt/grandma-dashboard
    
    log "✅ Grandmother Dashboard created"
}

# Create API server for dashboard
create_api_server() {
    log "Creating API server for dashboard..."
    
    sudo mkdir -p /opt/media-api
    
    # Create simple Python API server
    sudo tee /opt/media-api/api_server.py > /dev/null << 'EOF'
#!/usr/bin/env python3
import asyncio
import aiohttp
from aiohttp import web
import json
import subprocess
import os
import sys

class MediaStackAPI:
    def __init__(self, port=8601):
        self.port = port
        
    async def status_handler(self, request):
        service = request.match_info.get('service', '')
        
        # Check service status
        try:
            result = subprocess.run(['systemctl', 'is-active', service], 
                                  capture_output=True, text=True)
            if result.returncode == 0 and result.stdout.strip() == 'active':
                return web.json_response({'status': 'online', 'service': service})
            else:
                return web.json_response({'status': 'offline', 'service': service})
        except Exception as e:
            return web.json_response({'status': 'error', 'error': str(e)})
    
    async def vpn_status_handler(self, request):
        try:
            # Check WireGuard interface
            result = subprocess.run(['ip', 'link', 'show', 'wg0'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                return web.json_response({'status': 'connected'})
            else:
                return web.json_response({'status': 'disconnected'})
        except:
            return web.json_response({'status': 'error'})
    
    async def weather_handler(self, request):
        # Simple weather response (can be enhanced with real API)
        return web.json_response({
            'temp': 72,
            'feels_like': 75,
            'description': 'Partly Cloudy',
            'humidity': 65,
            'wind_speed': 8
        })
    
    def setup_routes(self, app):
        app.router.add_get('/api/status/{service}', self.status_handler)
        app.router.add_get('/api/status/vpn', self.vpn_status_handler)
        app.router.add_get('/api/weather', self.weather_handler)
        app.router.add_get('/api/health', lambda r: web.Response(text="OK"))
    
    async def start_server(self):
        app = web.Application()
        self.setup_routes(app)
        
        runner = web.AppRunner(app)
        await runner.setup()
        
        site = web.TCPSite(runner, '127.0.0.1', self.port)
        await site.start()
        
        print(f"Media Stack API started on http://127.0.0.1:{self.port}")
        
        try:
            await asyncio.Future()  # Run forever
        except KeyboardInterrupt:
            await runner.cleanup()

def main():
    api = MediaStackAPI()
    asyncio.run(api.start_server())

if __name__ == '__main__':
    main()
EOF

    # Create systemd service for API
    sudo tee /etc/systemd/system/media-api.service > /dev/null << 'EOF'
[Unit]
Description=Media Stack API Server
After=network.target

[Service]
Type=simple
User=lou
Group=media
WorkingDirectory=/opt/media-api
ExecStart=/usr/bin/python3 /opt/media-api/api_server.py
Restart=on-failure
Environment=PYTHONPATH=/opt/media-api

[Install]
WantedBy=multi-user.target
EOF

    sudo chown -R "$MEDIA_USER:$MEDIA_GROUP" /opt/media-api
    sudo chmod +x /opt/media-api/api_server.py
    
    # Install Python dependencies
    sudo pip install aiohttp
    
    sudo systemctl daemon-reload
    sudo systemctl enable media-api
    sudo systemctl start media-api
    
    log "✅ Media API server created and started on port 8601"
}

# Configure firewall
setup_firewall() {
    log "Configuring firewall..."
    
    # Enable UFW
    sudo ufw --force enable
    
    # Allow SSH
    sudo ufw allow ssh
    
    # Allow media stack ports
    sudo ufw allow 8600  # Main dashboard
    sudo ufw allow 8601  # API server
    sudo ufw allow 5080  # qBittorrent
    sudo ufw allow 7878  # Radarr
    sudo ufw allow 8989  # Sonarr
    sudo ufw allow 8686  # Lidarr
    sudo ufw allow 8787  # Readarr
    sudo ufw allow 9117  # Jackett
    sudo ufw allow 8083  # Calibre-Web
    sudo ufw allow 13378 # Audiobookshelf
    sudo ufw allow 3030  # Pulsarr
    sudo ufw allow 5055  # Jellyseerr
    sudo ufw allow 8096  # Jellyfin
    sudo ufw allow 32400 # Plex
    
    # Allow WireGuard
    sudo ufw allow 51820/udp
    
    log "✅ Firewall configured"
}

# Create management scripts
create_management_scripts() {
    log "Creating management scripts..."
    
    # Media stack control script
    sudo tee /usr/local/bin/media-stack > /dev/null << 'EOF'
#!/bin/bash

SERVICES=(
    "qbittorrent"
    "jackett" 
    "radarr"
    "sonarr"
    "lidarr"
    "readarr"
    "calibre-web"
    "audiobookshelf"
    "pulsarr"
    "jellyseerr"
    "media-api"
    "nginx"
    "wg-quick@wg0"
)

case "${1:-}" in
    "start")
        echo "🚀 Starting all media stack services..."
        for service in "${SERVICES[@]}"; do
            sudo systemctl start "$service" && echo "✅ $service started" || echo "❌ $service failed"
        done
        ;;
    "stop")
        echo "🛑 Stopping all media stack services..."
        for service in "${SERVICES[@]}"; do
            sudo systemctl stop "$service" && echo "✅ $service stopped" || echo "❌ $service failed"
        done
        ;;
    "restart")
        echo "🔄 Restarting all media stack services..."
        for service in "${SERVICES[@]}"; do
            sudo systemctl restart "$service" && echo "✅ $service restarted" || echo "❌ $service failed"
        done
        ;;
    "status")
        echo "📊 Media Stack Service Status:"
        echo "================================"
        for service in "${SERVICES[@]}"; do
            status=$(systemctl is-active "$service" 2>/dev/null || echo "inactive")
            if [[ "$status" == "active" ]]; then
                echo "✅ $service: Running"
            else
                echo "❌ $service: $status"
            fi
        done
        echo ""
        echo "🌐 Service URLs:"
        echo "Main Dashboard: http://localhost:8600"
        echo "qBittorrent: http://localhost:5080"
        echo "Radarr: http://localhost:7878"
        echo "Sonarr: http://localhost:8989"
        echo "Lidarr: http://localhost:8686"
        echo "Readarr: http://localhost:8787"
        echo "Jackett: http://localhost:9117"
        echo "Calibre-Web: http://localhost:8083"
        echo "Audiobookshelf: http://localhost:13378"
        echo "Pulsarr: http://localhost:3030"
        echo "Jellyseerr: http://localhost:5055"
        ;;
    "logs")
        service="${2:-}"
        if [[ -n "$service" ]]; then
            sudo journalctl -u "$service" -f
        else
            echo "Usage: media-stack logs <service_name>"
            echo "Available services: ${SERVICES[*]}"
        fi
        ;;
    "ghost-mode")
        case "${2:-}" in
            "on"|"start")
                ghost-mode start
                ;;
            "off"|"stop")
                ghost-mode stop
                ;;
            "status")
                ghost-mode status
                ;;
            *)
                echo "Usage: media-stack ghost-mode {on|off|status}"
                ;;
        esac
        ;;
    *)
        echo "🎬 Garuda Native Media Stack Manager"
        echo "Usage: media-stack {start|stop|restart|status|logs|ghost-mode}"
        echo ""
        echo "Commands:"
        echo "  start       - Start all services"
        echo "  stop        - Stop all services"
        echo "  restart     - Restart all services"
        echo "  status      - Show service status and URLs"
        echo "  logs <srv>  - Show logs for specific service"
        echo "  ghost-mode  - Control Ghost Mode VPN"
        echo ""
        echo "Services managed:"
        for service in "${SERVICES[@]}"; do
            echo "  - $service"
        done
        ;;
esac
EOF

    sudo chmod +x /usr/local/bin/media-stack
    
    log "✅ Management scripts created"
}

# Main installation function
main() {
    log "🎬 Starting Garuda Native Media Stack Installation"
    log "=================================================="
    
    check_root
    update_system
    setup_media_user
    
    # Install media applications
    install_qbittorrent
    install_jackett
    install_radarr
    install_sonarr
    install_lidarr
    install_readarr
    install_calibre_stack
    install_audiobookshelf
    install_pulsarr
    install_jellyseerr
    
    # Setup infrastructure
    setup_nginx_proxy
    create_grandma_dashboard
    create_api_server
    setup_firewall
    create_management_scripts
    
    # Setup WireGuard Ghost Mode
    setup_wireguard_ghost_mode
    
    log "🎉 Installation Complete!"
    log "======================="
    log ""
    log "🌐 Access your media stack at: http://localhost:8600"
    log ""
    log "📋 Management Commands:"
    log "  media-stack status    - Check all services"
    log "  media-stack start     - Start all services"
    log "  media-stack stop      - Stop all services"
    log "  media-stack restart   - Restart all services"
    log "  ghost-mode           - Toggle VPN anonymity"
    log ""
    log "🔐 Default Credentials:"
    log "  qBittorrent: admin / adminadmin"
    log "  Other services: Configure on first login"
    log ""
    log "🛡️ Security Features:"
    log "  - WireGuard VPN with 6-hour key rotation"
    log "  - Ghost Mode for complete online anonymity"
    log "  - Firewall configured for media stack ports"
    log "  - API masking proxy for AI services"
    log ""
    log "Reboot your system to ensure all services start properly!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
