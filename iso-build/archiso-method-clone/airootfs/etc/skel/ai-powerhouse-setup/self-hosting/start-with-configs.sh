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
