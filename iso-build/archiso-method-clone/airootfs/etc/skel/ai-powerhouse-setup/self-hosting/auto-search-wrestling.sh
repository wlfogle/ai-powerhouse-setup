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
