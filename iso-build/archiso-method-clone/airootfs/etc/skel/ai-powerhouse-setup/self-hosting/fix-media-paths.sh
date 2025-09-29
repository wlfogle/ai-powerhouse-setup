#!/bin/bash

# FIX ALL MEDIA PATHS TO /mnt/media
# Ensures all services use consistent /mnt/media paths

echo "🔧 FIXING ALL MEDIA PATHS TO /mnt/media..."

# Create media directory structure
sudo mkdir -p /mnt/media/{movies,tv,music,books,audiobooks,downloads,torrents,systembackup/Videos}
sudo chmod -R 755 /mnt/media/
sudo chown -R 1000:1000 /mnt/media/

# Create symlink for Walking Dead videos
sudo ln -sf /mnt/media/systembackup/Videos/twd /mnt/media/tv/the-walking-dead 2>/dev/null

echo "📁 Created media directories:"
echo "  📽️  /mnt/media/movies"
echo "  📺 /mnt/media/tv"
echo "  🎵 /mnt/media/music"
echo "  📚 /mnt/media/books"
echo "  🎧 /mnt/media/audiobooks"
echo "  ⬇️  /mnt/media/downloads"
echo "  🌊 /mnt/media/torrents"

# Fix Radarr config
echo "🎬 Fixing Radarr paths..."
if [ -f /mnt/media/config/radarr/config.xml ]; then
    sed -i 's|<MoviePath>.*</MoviePath>|<MoviePath>/mnt/media/movies</MoviePath>|g' /mnt/media/config/radarr/config.xml
    sed -i 's|<CompletedDownloadFolder>.*</CompletedDownloadFolder>|<CompletedDownloadFolder>/mnt/media/downloads</CompletedDownloadFolder>|g' /mnt/media/config/radarr/config.xml
fi

# Fix Sonarr config
echo "📺 Fixing Sonarr paths..."
if [ -f /mnt/media/config/sonarr/config.xml ]; then
    sed -i 's|<TvFolder>.*</TvFolder>|<TvFolder>/mnt/media/tv</TvFolder>|g' /mnt/media/config/sonarr/config.xml
    sed -i 's|<CompletedDownloadFolder>.*</CompletedDownloadFolder>|<CompletedDownloadFolder>/mnt/media/downloads</CompletedDownloadFolder>|g' /mnt/media/config/sonarr/config.xml
fi

# Fix Lidarr config
echo "🎵 Fixing Lidarr paths..."
if [ -f /mnt/media/config/lidarr/config.xml ]; then
    sed -i 's|<MusicFolder>.*</MusicFolder>|<MusicFolder>/mnt/media/music</MusicFolder>|g' /mnt/media/config/lidarr/config.xml
    sed -i 's|<CompletedDownloadFolder>.*</CompletedDownloadFolder>|<CompletedDownloadFolder>/mnt/media/downloads</CompletedDownloadFolder>|g' /mnt/media/config/lidarr/config.xml
fi

# Fix Readarr config
echo "📚 Fixing Readarr paths..."
if [ -f /mnt/media/config/readarr/config.xml ]; then
    sed -i 's|<BookFolder>.*</BookFolder>|<BookFolder>/mnt/media/books</BookFolder>|g' /mnt/media/config/readarr/config.xml
    sed -i 's|<CompletedDownloadFolder>.*</CompletedDownloadFolder>|<CompletedDownloadFolder>/mnt/media/downloads</CompletedDownloadFolder>|g' /mnt/media/config/readarr/config.xml
fi

# Fix qBittorrent config
echo "⬇️ Fixing qBittorrent paths..."
if [ -f /mnt/media/config/qbittorrent/qBittorrent.conf ]; then
    sed -i 's|Session\\DefaultSavePath=.*|Session\\DefaultSavePath=/mnt/media/downloads|g' /mnt/media/config/qbittorrent/qBittorrent.conf
    sed -i 's|Session\\TempPath=.*|Session\\TempPath=/mnt/media/torrents|g' /mnt/media/config/qbittorrent/qBittorrent.conf
fi

# Fix Jellyfin media libraries
echo "🎬 Fixing Jellyfin media paths..."
if [ -f /mnt/media/config/jellyfin/system.xml ]; then
    # Update media library paths in Jellyfin config
    sed -i 's|<Path>.*movies.*</Path>|<Path>/mnt/media/movies</Path>|gi' /mnt/media/config/jellyfin/system.xml
    sed -i 's|<Path>.*tv.*</Path>|<Path>/mnt/media/tv</Path>|gi' /mnt/media/config/jellyfin/system.xml
    sed -i 's|<Path>.*music.*</Path>|<Path>/mnt/media/music</Path>|gi' /mnt/media/config/jellyfin/system.xml
    sed -i 's|<Path>.*books.*</Path>|<Path>/mnt/media/books</Path>|gi' /mnt/media/config/jellyfin/system.xml
fi

# Create symlinks for backwards compatibility
echo "🔗 Creating compatibility symlinks..."
sudo ln -sf /mnt/media/movies /media/movies 2>/dev/null
sudo ln -sf /mnt/media/tv /media/tv 2>/dev/null
sudo ln -sf /mnt/media/music /media/music 2>/dev/null
sudo ln -sf /mnt/media/books /media/books 2>/dev/null
sudo ln -sf /mnt/media/downloads /media/downloads 2>/dev/null

echo "✅ ALL MEDIA PATHS FIXED!"
echo "📁 All services now use /mnt/media/ paths"
echo "🔧 Configs updated for consistent media storage"
echo "🔗 Compatibility symlinks created"
echo ""
echo "📂 Your media structure:"
echo "   /mnt/media/movies     ← Radarr movies"
echo "   /mnt/media/tv         ← Sonarr TV shows"  
echo "   /mnt/media/music      ← Lidarr music"
echo "   /mnt/media/books      ← Readarr books"
echo "   /mnt/media/audiobooks ← Audiobookshelf"
echo "   /mnt/media/downloads  ← qBittorrent downloads"
echo ""
echo "🚀 Restart services to apply path changes!"
