#!/bin/bash

# CONFIGURE CALIBRE WITH LOU'S LIBRARY AS MAIN
# Other directories are staging areas for books to be added

echo "📚 CONFIGURING LOU'S MAIN LIBRARY..."

# Main library path
MAIN_LIBRARY="/mnt/media/data/Lou's Library"

# Staging/intake directories (books waiting to be added)
STAGING_DIRS=(
    "/mnt/media/data/Intake"
    "/mnt/media/data/blizzard" 
    "/mnt/media/data/Cookbooks"
    "/mnt/media/data/D&D"
    "/mnt/media/data/New"
    "/mnt/media/data/WarHammer Fantasy"
)

echo "🏠 Main Library: $MAIN_LIBRARY"
echo "📥 Staging directories (books waiting to be added):"
for dir in "${STAGING_DIRS[@]}"; do
    echo "  - $(basename "$dir"): $dir"
done

# Verify main library exists
if [ ! -d "$MAIN_LIBRARY" ]; then
    echo "❌ Main library not found at $MAIN_LIBRARY"
    exit 1
fi

echo "✅ Main library verified"

# Start Calibre server with Lou's Library only
echo "🚀 Starting Calibre server with Lou's Library..."
sudo chroot /mnt bash -c "calibre-server --port=8083 '$MAIN_LIBRARY' --enable-auth --manage-users --max-cover=400x600" &
CALIBRE_PID=$!

sleep 5

# Test if server is running
if curl -s http://localhost:8083 > /dev/null; then
    echo "✅ Calibre server is running"
else
    echo "⚠️ Calibre server may still be starting..."
fi

# Create library management guide
cat > ./lous-library-guide.txt << 'EOF'
# LOU'S LIBRARY CONFIGURATION

## Main Library
- Path: /mnt/media/data/Lou's Library
- Access: http://localhost:8083
- Purpose: Consolidated main book collection

## Staging Directories (Books waiting to be added)
These directories contain books that need to be processed and added to Lou's Library:

1. Intake: /mnt/media/data/Intake
   - General intake queue

2. Blizzard: /mnt/media/data/blizzard
   - Gaming-related books to be catalogued

3. Cookbooks: /mnt/media/data/Cookbooks
   - Culinary books to be added

4. D&D: /mnt/media/data/D&D
   - Tabletop gaming books to be processed

5. New: /mnt/media/data/New
   - Recently acquired books

6. WarHammer Fantasy: /mnt/media/data/WarHammer Fantasy
   - Warhammer fiction and lore books

## Library Management Workflow
1. Books arrive in staging directories
2. Use Calibre desktop app to add books from staging dirs to Lou's Library
3. After adding, books can be moved/deleted from staging directories
4. Lou's Library serves as the single source of truth

## Adding Books from Staging
- Use Calibre desktop: Add Books → Browse to staging directory
- Select books to import into Lou's Library
- Set metadata and organize as needed
- Clean up staging directory after import
EOF

echo "📖 Created library management guide: lous-library-guide.txt"

echo ""
echo "✅ LOU'S LIBRARY SETUP COMPLETE!"
echo ""
echo "📚 ACCESS YOUR LIBRARY:"
echo "  🏠 Lou's Library: http://localhost:8083"
echo ""
echo "📥 STAGING DIRECTORIES FOR PROCESSING:"
for dir in "${STAGING_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        book_count=$(find "$dir" -name "*.epub" -o -name "*.pdf" -o -name "*.mobi" 2>/dev/null | wc -l)
        echo "  📂 $(basename "$dir"): $book_count books waiting"
    fi
done
echo ""
echo "📋 See lous-library-guide.txt for library management workflow"
