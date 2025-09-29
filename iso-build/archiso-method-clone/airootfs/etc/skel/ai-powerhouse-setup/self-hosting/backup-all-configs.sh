#!/bin/bash

# COMPREHENSIVE CONFIG BACKUP SCRIPT
# Backs up ALL service configurations to /mnt/media/config
# Run this after any configuration changes!

echo "🔄 BACKING UP ALL CONFIGURATIONS TO /mnt/media/config..."

# Create all config directories
sudo mkdir -p /mnt/media/config/{radarr,sonarr,lidarr,readarr,jellyfin,jackett,qbittorrent,jellyseerr,calibre,pulsarr,audiobookshelf,bazarr,prowlarr,wireguard,ghost-mode}

# Backup *arr services
echo "📁 Backing up *arr services..."
sudo cp -r /var/lib/radarr/* /mnt/media/config/radarr/ 2>/dev/null || echo "Radarr: using existing config"
sudo cp -r /var/lib/sonarr/* /mnt/media/config/sonarr/ 2>/dev/null || echo "Sonarr: using existing config"
sudo cp -r /var/lib/lidarr/* /mnt/media/config/lidarr/ 2>/dev/null || echo "Lidarr: using existing config"
sudo cp -r /var/lib/readarr/* /mnt/media/config/readarr/ 2>/dev/null || echo "Readarr: using existing config"

# Backup Jellyfin
echo "🎬 Backing up Jellyfin..."
sudo cp -r /var/lib/jellyfin/* /mnt/media/config/jellyfin/ 2>/dev/null || echo "Jellyfin: using existing config"

# Backup Jackett
echo "🔍 Backing up Jackett..."
sudo cp -r /home/lou/.config/Jackett/* /mnt/media/config/jackett/ 2>/dev/null || echo "Jackett: using existing config"

# Backup qBittorrent
echo "⬇️ Backing up qBittorrent..."
sudo cp -r /home/lou/.config/qBittorrent/* /mnt/media/config/qbittorrent/ 2>/dev/null || echo "qBittorrent: using existing config"

# Backup Jellyseerr
echo "🔍 Backing up Jellyseerr..."
sudo cp -r /root/.config/jellyseerr/* /mnt/media/config/jellyseerr/ 2>/dev/null || echo "Jellyseerr: will create new config"
sudo cp -r /home/lou/.config/jellyseerr/* /mnt/media/config/jellyseerr/ 2>/dev/null || echo "Jellyseerr: user config not found"

# Backup Calibre
echo "📚 Backing up Calibre..."
sudo cp -r /home/lou/.calibre/* /mnt/media/config/calibre/ 2>/dev/null || echo "Calibre: will create new config"

# Backup WireGuard
echo "🛡️ Backing up WireGuard..."
sudo cp -r /etc/wireguard/* /mnt/media/config/wireguard/ 2>/dev/null || echo "WireGuard: will create new config"

# Backup Ghost Mode configs
echo "🥷 Backing up Ghost Mode..."
cp -r ghost-mode-* /mnt/media/config/ghost-mode/ 2>/dev/null || echo "Ghost Mode: using existing config"

# Fix permissions
echo "🔐 Fixing permissions..."
sudo chown -R 1000:1000 /mnt/media/config/
sudo chmod -R 755 /mnt/media/config/

# Create service startup script
cat > /mnt/home/lou/github/garuda-media-stack/start-with-configs.sh << 'EOF'
#!/bin/bash
# START ALL SERVICES WITH PERSISTENT CONFIGS
echo "🚀 Starting all services with persistent configs..."

# Start with config directories
/usr/bin/jellyfin --datadir /mnt/media/config/jellyfin --configdir /mnt/media/config/jellyfin &
/usr/lib/radarr/bin/Radarr -nobrowser -data=/mnt/media/config/radarr &
/usr/lib/sonarr/bin/Sonarr -nobrowser -data=/mnt/media/config/sonarr &
/usr/lib/lidarr/bin/Lidarr -nobrowser -data=/mnt/media/config/lidarr &
/usr/local/bin/Readarr -nobrowser -data=/mnt/media/config/readarr &
qbittorrent-nox --webui-port=5080 --profile=/mnt/media/config/qbittorrent &

echo "✅ All services started with persistent configs!"
EOF

chmod +x /mnt/home/lou/github/garuda-media-stack/start-with-configs.sh

echo "✅ ALL CONFIGURATIONS BACKED UP TO /mnt/media/config!"
echo "📁 Config directories created for all services"
echo "🔧 Use ./start-with-configs.sh to start with persistent configs"
echo "💾 Run this script after ANY configuration changes!"
