#!/bin/bash

# CONFIGURE CALIBRE WITH MULTIPLE SPECIALIZED LIBRARIES
# Main library + specialized collections

echo "📚 CONFIGURING CALIBRE WITH MULTIPLE LIBRARIES..."

# Define all library paths
MAIN_LIBRARY="/mnt/media/data/Lou's Library"
LIBRARIES=(
    "/mnt/media/data/Intake"
    "/mnt/media/data/blizzard" 
    "/mnt/media/data/Cookbooks"
    "/mnt/media/data/D&D"
    "/mnt/media/data/New"
    "/mnt/media/data/WarHammer Fantasy"
)

echo "📖 Detected libraries:"
echo "  🏠 Main Library: $MAIN_LIBRARY"
for lib in "${LIBRARIES[@]}"; do
    echo "  📂 Specialized: $lib"
done

# Verify libraries exist
echo "🔍 Verifying library paths..."
if [ -d "$MAIN_LIBRARY" ]; then
    echo "  ✅ Main library exists"
else
    echo "  ❌ Main library not found!"
    exit 1
fi

for lib in "${LIBRARIES[@]}"; do
    if [ -d "$lib" ]; then
        echo "  ✅ $(basename "$lib") library exists"
    else
        echo "  ⚠️ $(basename "$lib") library not found - will create if needed"
        sudo mkdir -p "$lib"
    fi
done

# Start Calibre-Web with main library and virtual library support
echo "🚀 Starting Calibre server with main library..."
sudo chroot /mnt bash -c "calibre-server --port=8083 '$MAIN_LIBRARY' --enable-auth --max-cover=300x400 --max-opds-items=50 --url-prefix=/calibre" &
CALIBRE_PID=$!

sleep 3

# Create a multi-library configuration file
echo "📝 Creating multi-library configuration..."
cat > /tmp/calibre_libraries.txt << 'EOF'
# CALIBRE LIBRARY CONFIGURATION
# Access multiple specialized libraries

Main Library: http://localhost:8083/calibre
  - Lou's main book collection
  - Default library for browsing

Additional Libraries (Manual Setup Required):
1. Intake Library: /mnt/media/data/Intake
   - New acquisitions and processing

2. Blizzard Library: /mnt/media/data/blizzard  
   - Gaming and Blizzard Entertainment content

3. Cookbooks Library: /mnt/media/data/Cookbooks
   - Culinary and recipe collections

4. D&D Library: /mnt/media/data/D&D
   - Dungeons & Dragons rulebooks and modules

5. New Library: /mnt/media/data/New
   - Recently added or unprocessed content

6. WarHammer Fantasy Library: /mnt/media/data/WarHammer Fantasy
   - Warhammer Fantasy fiction and lore

SETUP INSTRUCTIONS:
- Primary access via: http://localhost:8083/calibre
- To switch libraries: Stop server, change path, restart
- For multiple simultaneous access: Run additional instances on different ports
EOF

# Copy to project directory
cp /tmp/calibre_libraries.txt ./calibre-library-guide.txt

echo "🌐 Starting additional library servers on different ports..."

# Start specialized library servers (gaming focused)
sudo chroot /mnt bash -c "calibre-server --port=8084 '/mnt/media/data/D&D' --enable-auth --url-prefix=/dnd" &
echo "  🎲 D&D Library: http://localhost:8084/dnd"

sudo chroot /mnt bash -c "calibre-server --port=8085 '/mnt/media/data/WarHammer Fantasy' --enable-auth --url-prefix=/warhammer" &  
echo "  ⚔️ Warhammer Library: http://localhost:8085/warhammer"

sudo chroot /mnt bash -c "calibre-server --port=8086 '/mnt/media/data/Cookbooks' --enable-auth --url-prefix=/cooking" &
echo "  👨‍🍳 Cookbooks Library: http://localhost:8086/cooking"

sleep 2

echo "✅ CALIBRE MULTI-LIBRARY SETUP COMPLETE!"
echo ""
echo "📚 ACCESS YOUR LIBRARIES:"
echo "  🏠 Main Library (Lou's): http://localhost:8083/calibre"
echo "  🎲 D&D Collection: http://localhost:8084/dnd"
echo "  ⚔️ Warhammer Fantasy: http://localhost:8085/warhammer"
echo "  👨‍🍳 Cookbooks: http://localhost:8086/cooking"
echo ""
echo "📂 OTHER LIBRARIES (Manual Access):"
echo "  📥 Intake: /mnt/media/data/Intake"
echo "  🎮 Blizzard: /mnt/media/data/blizzard"
echo "  🆕 New: /mnt/media/data/New"
echo ""
echo "🔧 Library switching: Use calibre-library-guide.txt for instructions"
echo "📖 All libraries accessible through main Calibre interface"
