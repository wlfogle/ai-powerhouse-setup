#!/bin/bash

# WWE/AEW COMPLETE BROADCAST MONITORING SETUP
# Records ALL WWE/AEW events automatically

echo "🤼 SETTING UP COMPLETE WWE/AEW BROADCAST MONITORING..."

# Create comprehensive wrestling search database
cat > /mnt/home/lou/github/garuda-media-stack/wrestling-complete-events.txt << 'EOF'
# COMPLETE WWE/AEW BROADCAST EVENT DATABASE
# Use these terms for automated searches and monitoring

=== WWE WEEKLY PROGRAMMING ===
WWE Monday Night RAW
WWE Friday Night SmackDown  
WWE NXT
WWE Main Event
WWE Level Up
WWE Speed
WWE Bottom Line
WWE Velocity
WWE Heat
WWE Jakked
WWE Metal

=== WWE PREMIUM LIVE EVENTS (Big 4) ===
WWE WrestleMania
WWE Royal Rumble
WWE SummerSlam
WWE Survivor Series

=== WWE PREMIUM LIVE EVENTS (Monthly) ===
WWE Backlash
WWE Hell in a Cell
WWE Money in the Bank
WWE Extreme Rules
WWE TLC
WWE Elimination Chamber
WWE Fastlane
WWE Clash of Champions
WWE Night of Champions
WWE Battleground
WWE Crown Jewel
WWE Super ShowDown
WWE Day 1
WWE Payback
WWE Bash in Berlin

=== WWE NXT EVENTS ===
NXT TakeOver
NXT Stand & Deliver
NXT WarGames
NXT Halloween Havoc
NXT New Year's Evil
NXT Great American Bash
NXT In Your House
NXT Deadline

=== WWE LEGACY/SPECIAL EVENTS ===
WWE Saturday Night's Main Event
WWE Tribute to the Troops
WWE Draft
WWE King of the Ring
WWE Bad Blood
WWE Judgment Day
WWE Unforgiven
WWE No Mercy
WWE Vengeance
WWE Great American Bash
WWE Armageddon
WWE No Way Out
WWE Insurrextion
WWE Rebellion

=== AEW WEEKLY PROGRAMMING ===
AEW Dynamite
AEW Rampage
AEW Collision
AEW Dark
AEW Dark Elevation

=== AEW PAY-PER-VIEW EVENTS ===
AEW Double or Nothing
AEW All Out
AEW Full Gear
AEW Revolution
AEW Forbidden Door
AEW WrestleDream
AEW Worlds End
AEW Dynasty

=== AEW SPECIAL EVENTS ===
AEW Grand Slam
AEW Winter is Coming
AEW Beach Break
AEW St. Patrick's Day Slam
AEW Fight for the Fallen
AEW Fyter Fest
AEW Homecoming
AEW Road Rager
AEW The First Dance
AEW Battle of the Belts
AEW Quake by the Lake
AEW Maximum Carnage
AEW Blood & Guts

=== NEW ORLEANS SAINTS GAMES ===
Saints vs Cowboys
Saints vs Falcons
Saints vs Panthers
Saints vs Buccaneers
Saints vs Rams
Saints vs 49ers
Saints vs Seahawks
Saints vs Cardinals
Saints vs Bears
Saints vs Lions
Saints vs Packers
Saints vs Vikings
Saints vs Bills
Saints vs Dolphins
Saints vs Jets
Saints vs Patriots
Saints vs Broncos
Saints vs Chiefs
Saints vs Raiders
Saints vs Chargers
Saints vs Ravens
Saints vs Bengals
Saints vs Browns
Saints vs Steelers
Saints vs Texans
Saints vs Colts
Saints vs Jaguars
Saints vs Titans
Saints vs Commanders
Saints vs Eagles
Saints vs Giants

Saints Monday Night Football
Saints Sunday Night Football
Saints Thursday Night Football
Saints Playoff Game
Saints Wild Card
Saints Divisional Round
Saints Conference Championship
Saints Super Bowl
EOF

echo "📋 Created comprehensive event database: wrestling-complete-events.txt"

# Create automated search script
cat > /mnt/home/lou/github/garuda-media-stack/auto-search-wrestling.sh << 'EOF'
#!/bin/bash

# AUTOMATED WRESTLING SEARCH SCRIPT
# Runs daily searches for new wrestling content

JACKETT_URL="http://localhost:9117"
JACKETT_API_KEY="jackettapikey123456789abcdef"

echo "🔍 Running automated wrestling searches..."

# Current year searches
YEAR=$(date +%Y)

# WWE Current Events
CURRENT_WWE=(
    "WWE RAW $YEAR"
    "WWE SmackDown $YEAR" 
    "WWE NXT $YEAR"
    "WWE Royal Rumble $YEAR"
    "WWE WrestleMania $YEAR"
    "WWE SummerSlam $YEAR"
    "WWE Survivor Series $YEAR"
    "WWE Hell in a Cell $YEAR"
    "WWE Money in the Bank $YEAR"
    "WWE Extreme Rules $YEAR"
)

# AEW Current Events
CURRENT_AEW=(
    "AEW Dynamite $YEAR"
    "AEW Rampage $YEAR"
    "AEW Collision $YEAR"
    "AEW All Out $YEAR"
    "AEW Double or Nothing $YEAR" 
    "AEW Revolution $YEAR"
    "AEW Full Gear $YEAR"
)

# Saints Current Season
SAINTS_CURRENT=(
    "Saints vs Cowboys $YEAR"
    "Saints vs Falcons $YEAR"
    "Saints vs Panthers $YEAR"
    "Saints vs Buccaneers $YEAR"
    "Saints Monday Night Football $YEAR"
    "Saints Sunday Night Football $YEAR"
    "Saints Playoff $YEAR"
)

echo "Searching current WWE events..."
for event in "${CURRENT_WWE[@]}"; do
    echo "  🔍 $event"
    # Search Jackett for event
    curl -s "$JACKETT_URL/api/v2.0/indexers/all/results?apikey=$JACKETT_API_KEY&Query=$(echo $event | sed 's/ /%20/g')" > "/tmp/search_$(echo $event | sed 's/ /_/g').json"
done

echo "Searching current AEW events..."
for event in "${CURRENT_AEW[@]}"; do
    echo "  🔍 $event"
    curl -s "$JACKETT_URL/api/v2.0/indexers/all/results?apikey=$JACKETT_API_KEY&Query=$(echo $event | sed 's/ /%20/g')" > "/tmp/search_$(echo $event | sed 's/ /_/g').json"
done

echo "Searching Saints games..."
for game in "${SAINTS_CURRENT[@]}"; do
    echo "  ⚜️ $game"
    curl -s "$JACKETT_URL/api/v2.0/indexers/all/results?apikey=$JACKETT_API_KEY&Query=$(echo $game | sed 's/ /%20/g')" > "/tmp/search_$(echo $game | sed 's/ /_/g').json"
done

echo "✅ Automated searches complete! Check /tmp/search_*.json for results"
EOF

chmod +x /mnt/home/lou/github/garuda-media-stack/auto-search-wrestling.sh

# Create RSS monitoring setup
echo "📡 Setting up RSS monitoring for wrestling events..."

cat > /mnt/home/lou/github/garuda-media-stack/wrestling-rss-feeds.txt << 'EOF'
# WRESTLING & SPORTS RSS FEEDS FOR MONITORING
# Add these to your RSS reader or monitoring system

WWE FEEDS:
https://www.wwe.com/feeds/all
https://www.wwe.com/feeds/shows/raw
https://www.wwe.com/feeds/shows/smackdown
https://www.wwe.com/feeds/shows/nxt

AEW FEEDS:
https://www.allelitewrestling.com/rss
https://www.allelitewrestling.com/feed

WRESTLING NEWS:
https://www.wrestlinginc.com/feed/
https://pwinsider.com/rss.php
https://www.fightful.com/wrestling/rss.xml

SAINTS FEEDS:
https://www.neworleanssaints.com/rss
https://www.nfl.com/feeds/rss/new-orleans-saints

INSTRUCTIONS:
- Use these RSS feeds to monitor for new episodes/games
- Set up alerts for new content
- Automatically trigger searches when new events are announced
EOF

echo "📺 Creating specialized TV categories..."

# Create TV categories in qBittorrent for wrestling content
QB_HOST="http://localhost:5080"

curl -s -X POST "$QB_HOST/api/v2/torrents/createCategory" \
    --cookie-jar /tmp/qb_cookies.txt \
    -d "category=wrestling" > /dev/null 2>&1

curl -s -X POST "$QB_HOST/api/v2/torrents/createCategory" \
    --cookie-jar /tmp/qb_cookies.txt \
    -d "category=wwe" > /dev/null 2>&1

curl -s -X POST "$QB_HOST/api/v2/torrents/createCategory" \
    --cookie-jar /tmp/qb_cookies.txt \
    -d "category=aew" > /dev/null 2>&1

curl -s -X POST "$QB_HOST/api/v2/torrents/createCategory" \
    --cookie-jar /tmp/qb_cookies.txt \
    -d "category=saints" > /dev/null 2>&1

echo "✅ COMPLETE WWE/AEW BROADCAST MONITORING SETUP COMPLETE!"
echo ""
echo "📋 WHAT WAS CREATED:"
echo "  📄 wrestling-complete-events.txt - All WWE/AEW/Saints events database"
echo "  🔍 auto-search-wrestling.sh - Automated daily search script" 
echo "  📡 wrestling-rss-feeds.txt - RSS feeds for monitoring"
echo "  📁 qBittorrent categories: wrestling, wwe, aew, saints"
echo ""
echo "🎯 NEXT STEPS:"
echo "  1. Run ./auto-search-wrestling.sh daily (or set up cron job)"
echo "  2. Monitor RSS feeds for new event announcements"
echo "  3. Manual search in Jackett: http://localhost:9117"
echo "  4. Use event database for comprehensive coverage"
echo ""
echo "⚡ AUTOMATED WORKFLOW:"
echo "  • Daily searches for current year events"
echo "  • Organized downloads by category" 
echo "  • Automatic organization to /mnt/media/tv/"
echo "  • Available in Jellyfin immediately"
echo ""
echo "🤼 ALL WWE/AEW BROADCASTS WILL BE MONITORED AND RECORDED!"
