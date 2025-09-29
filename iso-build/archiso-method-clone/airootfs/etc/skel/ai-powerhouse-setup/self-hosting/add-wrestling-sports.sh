#!/bin/bash

# ADD WWE/AEW PPVs AND NEW ORLEANS SAINTS GAMES
# Automates adding wrestling and Saints content to Sonarr

echo "🤼 ADDING WWE/AEW PPVs AND NEW ORLEANS SAINTS GAMES..."

# Get Sonarr API key
SONARR_CONFIG="/mnt/media/config/sonarr/config.xml"
if [ -f "$SONARR_CONFIG" ]; then
    SONARR_API_KEY=$(grep -o '<ApiKey>[^<]*' "$SONARR_CONFIG" | cut -d'>' -f2)
    echo "🔑 Using Sonarr API key: ${SONARR_API_KEY:0:8}..."
else
    echo "❌ Sonarr config not found!"
    exit 1
fi

SONARR_URL="http://localhost:8989"

# Function to add series to Sonarr
add_series() {
    local TITLE="$1"
    local SEARCH_TITLE="$2"
    local YEAR="$3"
    
    echo "🔍 Searching for: $TITLE"
    
    # Search for the series
    SEARCH_RESULT=$(curl -s "$SONARR_URL/api/v3/series/lookup?term=$SEARCH_TITLE" \
        -H "X-Api-Key: $SONARR_API_KEY")
    
    # Get the first result
    TVDB_ID=$(echo "$SEARCH_RESULT" | grep -o '"tvdbId":[0-9]*' | head -1 | cut -d':' -f2)
    
    if [ ! -z "$TVDB_ID" ]; then
        echo "📺 Found TVDB ID: $TVDB_ID for $TITLE"
        
        # Add to Sonarr
        curl -s -X POST "$SONARR_URL/api/v3/series" \
            -H "X-Api-Key: $SONARR_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{
                \"title\": \"$TITLE\",
                \"tvdbId\": $TVDB_ID,
                \"qualityProfileId\": 1,
                \"languageProfileId\": 1,
                \"seasonFolder\": true,
                \"monitored\": true,
                \"rootFolderPath\": \"/mnt/media/tv\",
                \"addOptions\": {
                    \"searchForMissingEpisodes\": true,
                    \"searchForCutoffUnmetEpisodes\": true
                }
            }" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "  ✅ Added $TITLE to Sonarr"
        else
            echo "  ⚠️ May already exist or failed: $TITLE"
        fi
    else
        echo "  ❌ Not found: $TITLE"
    fi
    
    sleep 2
}

echo ""
echo "🤼 ADDING ALL WWE BROADCAST EVENTS..."

# WWE Complete Broadcasting Schedule
WWE_SHOWS=(
    # Weekly Shows
    "WWE Monday Night RAW|wwe raw|1993"
    "WWE Friday Night SmackDown|wwe smackdown|1999"
    "WWE NXT|wwe nxt|2010"
    "WWE Main Event|wwe main event|2012"
    "WWE Level Up|wwe level up|2021"
    "WWE Speed|wwe speed|2024"
    
    # Big 4 PPVs
    "WWE Royal Rumble|wwe royal rumble|1988"
    "WWE WrestleMania|wrestlemania|1985"
    "WWE SummerSlam|summerslam|1988"
    "WWE Survivor Series|survivor series|1987"
    
    # Premium Live Events
    "WWE Hell in a Cell|hell in a cell|2009"
    "WWE TLC|wwe tlc|2009"
    "WWE Extreme Rules|extreme rules|2009"
    "WWE Money in the Bank|money in the bank|2010"
    "WWE Elimination Chamber|elimination chamber|2010"
    "WWE Fastlane|wwe fastlane|2015"
    "WWE Clash of Champions|clash of champions|2016"
    "WWE Backlash|wwe backlash|1999"
    "WWE Night of Champions|night of champions|2007"
    "WWE Battleground|wwe battleground|2013"
    "WWE Crown Jewel|crown jewel|2018"
    "WWE Super ShowDown|super showdown|2018"
    "WWE Day 1|wwe day 1|2022"
    
    # Special Events
    "WWE Saturday Night's Main Event|saturday nights main event|1985"
    "WWE Tribute to the Troops|tribute to the troops|2003"
    "WWE Draft|wwe draft|2002"
    "WWE King of the Ring|king of the ring|1985"
    "WWE Bad Blood|bad blood|1997"
    "WWE Judgment Day|judgment day|1998"
    "WWE Unforgiven|unforgiven|1998"
    "WWE No Mercy|no mercy|1999"
    "WWE Vengeance|wwe vengeance|2001"
    "WWE Great American Bash|great american bash|1985"
    "WWE Armageddon|wwe armageddon|1999"
    "WWE No Way Out|no way out|1998"
    
    # NXT Events
    "WWE NXT TakeOver|nxt takeover|2014"
    "WWE NXT Stand & Deliver|stand deliver|2021"
    "WWE NXT WarGames|nxt wargames|2017"
    "WWE NXT Halloween Havoc|nxt halloween havoc|2020"
    "WWE NXT New Year's Evil|new years evil|2021"
    "WWE NXT The Great American Bash|nxt great american bash|2020"
    
    # UK/International
    "WWE NXT UK|nxt uk|2017"
    "WWE Worlds Collide|worlds collide|2019"
)

for show in "${WWE_SHOWS[@]}"; do
    IFS='|' read -r title search year <<< "$show"
    add_series "$title" "$search" "$year"
done

echo ""
echo "🔥 ADDING ALL AEW BROADCAST EVENTS..."

# AEW Complete Broadcasting Schedule
AEW_SHOWS=(
    # Weekly Shows
    "AEW Dynamite|aew dynamite|2019"
    "AEW Rampage|aew rampage|2021"
    "AEW Collision|aew collision|2023"
    "AEW Dark|aew dark|2019"
    "AEW Dark Elevation|aew dark elevation|2021"
    "AEW Unrestricted|aew unrestricted|2020"
    
    # Pay-Per-View Events
    "AEW Double or Nothing|double or nothing|2019"
    "AEW All Out|aew all out|2019"
    "AEW Full Gear|full gear|2019"
    "AEW Revolution|aew revolution|2020"
    
    # Special Events & TV Specials
    "AEW Winter is Coming|winter is coming|2020"
    "AEW Grand Slam|grand slam|2021"
    "AEW Beach Break|beach break|2021"
    "AEW St. Patrick's Day Slam|st patricks day slam|2021"
    "AEW Fight for the Fallen|fight for the fallen|2019"
    "AEW Fyter Fest|fyter fest|2019"
    "AEW Homecoming|aew homecoming|2021"
    "AEW Road Rager|road rager|2021"
    "AEW The First Dance|first dance|2021"
    "AEW Arthur Ashe Stadium|arthur ashe|2021"
    "AEW Battle of the Belts|battle of the belts|2022"
    "AEW Quake by the Lake|quake by the lake|2022"
    "AEW Maximum Carnage|maximum carnage|2023"
    "AEW WrestleDream|wrestledream|2023"
    "AEW Worlds End|worlds end|2023"
    "AEW Dynasty|aew dynasty|2024"
    "AEW Forbidden Door|forbidden door|2022"
    
    # International/Special Broadcasts
    "AEW All Access|all access|2019"
    "Being The Elite|being the elite|2016"
    "Road to AEW|road to aew|2019"
)

for show in "${AEW_SHOWS[@]}"; do
    IFS='|' read -r title search year <<< "$show"
    add_series "$title" "$search" "$year"
done

echo ""
echo "⚜️ ADDING NEW ORLEANS SAINTS GAMES..."

# Saints Games - These might be harder to find as TV series
SAINTS_SEARCHES=(
    "New Orleans Saints|saints football|1967"
    "NFL New Orleans Saints|new orleans saints nfl|1967"
    "Saints Game Day|saints gameday|2000"
)

for show in "${SAINTS_SEARCHES[@]}"; do
    IFS='|' read -r title search year <<< "$show"
    add_series "$title" "$search" "$year"
done

echo ""
echo "🔧 CREATING CUSTOM SEARCHES..."

# Create custom search terms file for manual searches
cat > /mnt/home/lou/github/garuda-media-stack/wrestling-sports-searches.txt << 'EOF'
# WRESTLING & SPORTS SEARCH TERMS
# Use these in Jackett or manual searches

WWE PPV EVENTS:
- WWE Royal Rumble 2024
- WWE WrestleMania 40
- WWE SummerSlam 2024
- WWE Survivor Series 2024
- WWE Hell in a Cell
- WWE TLC Tables Ladders Chairs
- WWE Extreme Rules
- WWE Money in the Bank

AEW PPV EVENTS:
- AEW All Out
- AEW Double or Nothing
- AEW Revolution
- AEW Full Gear
- AEW Winter is Coming
- AEW Grand Slam

NEW ORLEANS SAINTS:
- Saints vs [Team] 2024
- New Orleans Saints Week [X]
- Saints Monday Night Football
- Saints Sunday Night Football
- Saints Playoff Game
- Saints Superdome

SEARCH TIPS:
- Add year for specific events (e.g., "WWE Royal Rumble 2024")
- Use team names for Saints games (e.g., "Saints vs Falcons")
- Check for different quality versions (1080p, 720p)
- Look for both live and replay versions
EOF

echo "📋 Created search terms guide: wrestling-sports-searches.txt"

echo ""
echo "✅ WRESTLING & SPORTS CONTENT SETUP COMPLETE!"
echo ""
echo "🎯 WHAT WAS ADDED:"
echo "  🤼 WWE Shows: RAW, SmackDown, NXT + PPVs"
echo "  🔥 AEW Shows: Dynamite, Rampage, Collision + PPVs" 
echo "  ⚜️ Saints: Searched for NFL content"
echo ""
echo "📺 CHECK SONARR: http://localhost:8989"
echo "  - Review added series"
echo "  - Set up quality profiles"
echo "  - Monitor upcoming episodes"
echo ""
echo "🔍 MANUAL SEARCH:"
echo "  - Use Jackett: http://localhost:9117"
echo "  - Search terms in: wrestling-sports-searches.txt"
echo "  - Add specific PPVs/games manually"
echo ""
echo "⚡ AUTOMATION ACTIVE:"
echo "  - New episodes will auto-download"
echo "  - Files organized to /mnt/media/tv/"
echo "  - Available in Jellyfin automatically"
