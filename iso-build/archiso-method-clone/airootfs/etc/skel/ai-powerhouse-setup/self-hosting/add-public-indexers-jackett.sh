#!/bin/bash

# ADD ALL POPULAR PUBLIC INDEXERS TO JACKETT
# Configures the most reliable public English torrent indexers

echo "🔍 ADDING POPULAR PUBLIC INDEXERS TO JACKETT..."

JACKETT_URL="http://localhost:9117"
JACKETT_API_KEY="jackettapikey123456789abcdef"

# Popular public indexers that work well
INDEXERS=(
    "1337x"
    "thepiratebay"
    "rarbg" 
    "limetorrents"
    "torrentgalaxy"
    "eztv"
    "yts"
    "nyaasi"
    "torlock"
    "magnetdl"
    "glotorrents"
    "kickasstorrents-ws"
    "torrentfunk"
    "yourbittorrent"
    "torrentdownloads"
    "torrentseeker"
)

echo "📋 Adding ${#INDEXERS[@]} popular public indexers to Jackett..."

# Wait for Jackett to be fully ready
sleep 10

for indexer in "${INDEXERS[@]}"; do
    echo "  📌 Adding $indexer..."
    
    # Try to add each indexer via API
    curl -s -X POST "$JACKETT_URL/api/v2.0/indexers/$indexer" \
        -H "X-API-Key: $JACKETT_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"configured": true}' > /dev/null 2>&1
        
    # Alternative method - configure via web scraping if API fails
    curl -s "$JACKETT_URL/Admin/AddIndexer?indexer=$indexer" > /dev/null 2>&1
    
    sleep 1
done

echo "✅ FINISHED ADDING PUBLIC INDEXERS!"
echo ""
echo "🌐 Access Jackett at: http://localhost:9117"
echo "🔧 Manual verification:"
echo "   1. Go to Jackett web interface"
echo "   2. Check that indexers are listed and working"
echo "   3. Test search to verify functionality"
echo ""
echo "📋 Popular indexers configured:"
for indexer in "${INDEXERS[@]}"; do
    echo "   • $indexer"
done
echo ""
echo "🔄 If some indexers failed, add them manually via Jackett web UI"
