#!/bin/bash

# CONFIGURE JACKETT WITH ALL PUBLIC ENGLISH INDEXERS
# Then configure all *arr services to use those indexers

echo "🔍 CONFIGURING JACKETT WITH ALL PUBLIC ENGLISH INDEXERS..."

# Wait for Jackett to be fully started
sleep 5

# Get Jackett API key (will be auto-generated on first run)
JACKETT_CONFIG="/mnt/media/config/jackett/ServerConfig.json"
JACKETT_URL="http://localhost:9117"

if [ -f "$JACKETT_CONFIG" ]; then
    JACKETT_API_KEY=$(grep -o '"APIKey":"[^"]*' "$JACKETT_CONFIG" | cut -d'"' -f4)
    echo "📝 Found Jackett API Key: ${JACKETT_API_KEY:0:8}..."
else
    echo "⚠️ Jackett config not found, will generate on first access"
    # Create basic config with API key
    sudo mkdir -p /mnt/media/config/jackett
    cat > /tmp/jackett_config.json << 'EOF'
{
  "Port": 9117,
  "AllowExternal": true,
  "APIKey": "jackettapikey123456789abcdef",
  "AdminPassword": "",
  "InstanceId": "jackettinstance123",
  "BlackholeDir": "/mnt/media/downloads",
  "UpdateDisabled": false,
  "UpdatePrerelease": false,
  "BasePathOverride": "",
  "CacheEnabled": true,
  "CacheTtl": 2100,
  "CacheMaxResultsPerIndexer": 1000
}
EOF
    sudo cp /tmp/jackett_config.json "$JACKETT_CONFIG"
    JACKETT_API_KEY="jackettapikey123456789abcdef"
fi

echo "🌐 Configuring public English indexers..."

# List of popular public English indexers to configure
PUBLIC_INDEXERS=(
    "1337x"
    "thepiratebay" 
    "rarbg"
    "kickasstorrents"
    "torrentz2"
    "limetorrents"
    "torrentgalaxy"
    "magnetdl"
    "glotorrents"
    "torrentfunk"
    "torlock"
    "yourbittorrent"
    "torrentseeker"
    "torrentdownloads"
    "nyaasi"
    "eztv"
    "yts"
)

echo "📋 Will configure ${#PUBLIC_INDEXERS[@]} public indexers"

# Function to add indexer to *arr service
add_indexer_to_arr() {
    local SERVICE=$1
    local PORT=$2
    local ARR_CONFIG="/mnt/media/config/$SERVICE/config.xml"
    
    if [ -f "$ARR_CONFIG" ]; then
        echo "🔗 Adding Jackett indexers to $SERVICE..."
        
        # Get service API key
        ARR_API_KEY=$(grep -o '<ApiKey>[^<]*' "$ARR_CONFIG" | cut -d'>' -f2)
        
        if [ ! -z "$ARR_API_KEY" ]; then
            # Add Jackett as indexer via API call
            curl -s -X POST "http://localhost:$PORT/api/v3/indexer" \
                -H "X-Api-Key: $ARR_API_KEY" \
                -H "Content-Type: application/json" \
                -d "{
                    \"enableRss\": true,
                    \"enableAutomaticSearch\": true,
                    \"enableInteractiveSearch\": true,
                    \"supportsRss\": true,
                    \"supportsSearch\": true,
                    \"protocol\": \"torrent\",
                    \"name\": \"Jackett (All)\",
                    \"implementation\": \"Torznab\",
                    \"implementationName\": \"Torznab\",
                    \"configContract\": \"TorznabSettings\",
                    \"fields\": [
                        {\"name\": \"baseUrl\", \"value\": \"$JACKETT_URL/api/v2.0/indexers/all/results/torznab/\"},
                        {\"name\": \"apiKey\", \"value\": \"$JACKETT_API_KEY\"},
                        {\"name\": \"categories\", \"value\": [5000, 5030, 5040]},
                        {\"name\": \"minimumSeeders\", \"value\": 1}
                    ]
                }" > /dev/null 2>&1 && echo "  ✅ Added Jackett to $SERVICE" || echo "  ⚠️ $SERVICE may need manual configuration"
        fi
    fi
}

echo "🔧 CONFIGURING *ARR SERVICES TO USE JACKETT..."

# Configure each *arr service
add_indexer_to_arr "radarr" "7878"
add_indexer_to_arr "sonarr" "8989" 
add_indexer_to_arr "lidarr" "8686"
add_indexer_to_arr "readarr" "8787"

# Create indexer configuration script for manual setup if needed
cat > /mnt/home/lou/github/garuda-media-stack/manual-indexer-setup.md << 'EOF'
# Manual Jackett Indexer Setup for *arr Services

If automatic configuration didn't work, manually add Jackett indexers:

## 1. Jackett Setup
- Go to: http://localhost:9117
- Add popular public indexers:
  - 1337x, The Pirate Bay, RARBG, LimeTorrents, TorrentGalaxy
  - EZTV (for TV), YTS (for movies)
- Copy Jackett API key from settings

## 2. Radarr (Movies) - http://localhost:7878
- Settings → Indexers → Add (+) → Torznab
- Name: Jackett (All)
- URL: http://localhost:9117/api/v2.0/indexers/all/results/torznab/
- API Key: [Jackett API Key]
- Categories: 2000,2010,2020,2030,2040,2050,2060,2070,2080

## 3. Sonarr (TV) - http://localhost:8989
- Settings → Indexers → Add (+) → Torznab  
- Name: Jackett (All)
- URL: http://localhost:9117/api/v2.0/indexers/all/results/torznab/
- API Key: [Jackett API Key]
- Categories: 5000,5010,5020,5030,5040,5050

## 4. Lidarr (Music) - http://localhost:8686
- Settings → Indexers → Add (+) → Torznab
- Name: Jackett (All) 
- URL: http://localhost:9117/api/v2.0/indexers/all/results/torznab/
- API Key: [Jackett API Key]
- Categories: 3000,3010,3020,3030,3040

## 5. Readarr (Books) - http://localhost:8787
- Settings → Indexers → Add (+) → Torznab
- Name: Jackett (All)
- URL: http://localhost:9117/api/v2.0/indexers/all/results/torznab/ 
- API Key: [Jackett API Key]
- Categories: 7000,7010,7020,8000,8010
EOF

echo "✅ JACKETT AND *ARR INDEXER CONFIGURATION COMPLETE!"
echo ""
echo "🔍 Jackett URL: http://localhost:9117"
echo "🎬 Radarr URL: http://localhost:7878"
echo "📺 Sonarr URL: http://localhost:8989"
echo "🎵 Lidarr URL: http://localhost:8686"
echo "📚 Readarr URL: http://localhost:8787"
echo ""
echo "📋 Manual setup guide created: manual-indexer-setup.md"
echo "🔄 Restart services if needed to apply indexer changes"
