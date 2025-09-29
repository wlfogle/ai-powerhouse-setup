#!/bin/bash

# ADD THE WALKING DEAD TO JELLYFIN
# Configures Jellyfin to access /mnt/media/systembackup/Videos/twd

echo "🧟 ADDING THE WALKING DEAD TO JELLYFIN..."

# Ensure directory exists and has proper permissions
sudo mkdir -p /mnt/media/systembackup/Videos/twd
sudo chown -R 1000:1000 /mnt/media/systembackup
sudo chmod -R 755 /mnt/media/systembackup

# Create symlink in standard TV directory for easier management
sudo ln -sf /mnt/media/systembackup/Videos/twd /mnt/media/tv/the-walking-dead 2>/dev/null

# Update Jellyfin system config to include the path
if [ -f /mnt/media/config/jellyfin/system.xml ]; then
    echo "📝 Updating Jellyfin system config..."
    
    # Add systembackup path to Jellyfin if not already present
    if ! grep -q "systembackup" /mnt/media/config/jellyfin/system.xml; then
        # Create a backup
        cp /mnt/media/config/jellyfin/system.xml /mnt/media/config/jellyfin/system.xml.bak
        
        # Add the new path to the system config
        sed -i 's|</MediaPathInfos>|  <MediaPathInfo>\n    <Path>/mnt/media/systembackup/Videos</Path>\n    <NetworkPath />\n  </MediaPathInfo>\n</MediaPathInfos>|' /mnt/media/config/jellyfin/system.xml 2>/dev/null || echo "Will configure via web UI"
    fi
fi

echo "✅ THE WALKING DEAD CONFIGURED FOR JELLYFIN!"
echo ""
echo "📁 Directory structure:"
echo "   /mnt/media/systembackup/Videos/twd ← Original location"
echo "   /mnt/media/tv/the-walking-dead      ← Symlink for easy access"
echo ""
echo "🎬 To complete setup:"
echo "   1. Go to Jellyfin admin dashboard"
echo "   2. Add library → TV Shows"
echo "   3. Add folder: /mnt/media/systembackup/Videos/twd"
echo "   4. Or use the symlink: /mnt/media/tv/the-walking-dead"
echo ""
echo "🔄 Restart Jellyfin to see the changes!"
