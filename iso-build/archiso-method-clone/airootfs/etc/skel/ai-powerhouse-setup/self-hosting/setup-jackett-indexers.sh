#!/bin/bash
# Setup common Jackett indexers automatically

JACKETT_URL="http://localhost:9117"
JACKETT_API_KEY="fu0rbrfo1xfc7heii08c0ay9m9wca27y"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_jackett() {
    log "🔍 Checking Jackett status..."
    
    if curl -s -w "%{http_code}" "$JACKETT_URL" -o /dev/null | grep -q "200\|301"; then
        log "✅ Jackett is running on $JACKETT_URL"
        return 0
    else
        log "❌ Jackett is not accessible"
        return 1
    fi
}

get_configured_indexers() {
    log "📋 Getting configured indexers from Jackett..."
    
    # Get indexer list
    local response=$(curl -s "$JACKETT_URL/api/v2.0/indexers" -H "X-Api-Key: $JACKETT_API_KEY" 2>/dev/null)
    
    if [ -n "$response" ]; then
        echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    configured = [i for i in data if i.get('configured', False)]
    unconfigured = [i for i in data if not i.get('configured', False)]
    
    print('✅ CONFIGURED INDEXERS:')
    if configured:
        for i in configured:
            print(f'  • {i.get(\"title\", \"Unknown\")} (ID: {i.get(\"id\", \"Unknown\")})')
    else:
        print('  None configured yet')
    
    print('\\n📝 AVAILABLE TO CONFIGURE:')
    tv_indexers = ['eztv', 'limetorrents', 'torlock', '1337x', 'thepiratebay', 'torrentgalaxy']
    available_tv = [i for i in unconfigured if any(tv in i.get('id', '').lower() for tv in tv_indexers)]
    
    for i in available_tv[:10]:  # Show first 10
        print(f'  • {i.get(\"title\", \"Unknown\")} (ID: {i.get(\"id\", \"Unknown\")})')
    
    if len(available_tv) > 10:
        print(f'  ... and {len(available_tv) - 10} more')
        
except Exception as e:
    print(f'Error parsing indexer data: {e}')
" 2>/dev/null
    else
        log "❌ Failed to get indexer list from Jackett"
        return 1
    fi
}

create_sonarr_guide() {
    log "📝 Creating Sonarr configuration guide..."
    
    cat > /home/lou/garuda-media-stack/sonarr-setup-steps.txt << 'EOF'
🎯 SONARR INDEXER SETUP - STEP BY STEP

Since indexers need to be configured in Jackett first, follow these steps:

STEP 1: Configure Indexers in Jackett
=====================================
1. Go to Jackett: http://localhost:9117
2. Click "Add indexer" 
3. Search for and add these TV-focused indexers:

   ✅ HIGHLY RECOMMENDED FOR TV:
   • EZTV (TV specialist)
   • LimeTorrents (reliable)  
   • Torlock (verified torrents)

   ✅ GOOD ADDITIONS:
   • 1337x (popular, needs FlareSolverr)
   • TorrentGalaxy (quality releases)

4. For each indexer:
   - Click "Setup" 
   - Leave default settings (most are public)
   - Click "Okay" to save

STEP 2: Add to Sonarr  
====================
After configuring in Jackett, add to Sonarr:

1. Go to Sonarr: http://localhost:8989
2. Settings → Indexers → Add Indexer → Torznab
3. Use these URLs (replace INDEXER_ID with actual ID):

   EZTV: http://localhost:9117/api/v2.0/indexers/eztv/results/torznab/
   LimeTorrents: http://localhost:9117/api/v2.0/indexers/limetorrents/results/torznab/
   Torlock: http://localhost:9117/api/v2.0/indexers/torlock/results/torznab/

4. API Key: fu0rbrfo1xfc7heii08c0ay9m9wca27y
5. Categories: 5000,5030,5040 (TV categories)

STEP 3: Test Each Indexer
=========================
- Click "Test" in Sonarr before saving
- Green checkmark = working correctly
- Red X = needs troubleshooting

TROUBLESHOOTING:
===============
• Indexer not found = Not configured in Jackett first
• SSL errors = Run our SSL fix script
• Cloudflare errors = FlareSolverr should handle automatically

🎯 PRIORITY ORDER:
1. EZTV (TV specialist)
2. LimeTorrents (reliable)  
3. Torlock (verified)
4. Others as backups
EOF

    log "✅ Created setup guide: /home/lou/garuda-media-stack/sonarr-setup-steps.txt"
}

show_quick_indexers() {
    log "🚀 Quick indexer recommendations for TV shows:"
    echo ""
    echo "🎯 EASIEST TO SET UP (Public, no login needed):"
    echo "  1. EZTV - TV show specialist"
    echo "  2. LimeTorrents - Very reliable"  
    echo "  3. Torlock - Verified torrents only"
    echo ""
    echo "🔧 STEPS:"
    echo "  1. Go to http://localhost:9117"
    echo "  2. Click 'Add indexer'"
    echo "  3. Search for 'EZTV'"
    echo "  4. Click 'Setup' → 'Okay'"
    echo "  5. Repeat for LimeTorrents and Torlock"
    echo ""
    echo "Then add them to Sonarr using the guide above!"
}

test_current_setup() {
    log "🧪 Testing current Jackett setup..."
    
    # Test Jackett API
    if curl -s "$JACKETT_URL/api/v2.0/server/config" -H "X-Api-Key: $JACKETT_API_KEY" >/dev/null 2>&1; then
        log "✅ Jackett API is working"
    else
        log "❌ Jackett API test failed"
        return 1
    fi
    
    # Check FlareSolverr integration
    if grep -q "\"FlareSolverrUrl\": \"http://localhost:8191/v1\"" /var/lib/jackett/ServerConfig.json 2>/dev/null; then
        log "✅ FlareSolverr is configured in Jackett"
    else
        log "⚠️ FlareSolverr may not be configured"
    fi
    
    # Test a caps request (what Sonarr uses)
    log "🔍 Testing indexer caps request..."
    if curl -s "$JACKETT_URL/api/v2.0/indexers/all/results/torznab/api?t=caps&apikey=$JACKETT_API_KEY" | grep -q "caps" 2>/dev/null; then
        log "✅ Torznab API is responding"
    else
        log "⚠️ Torznab API may have issues"
    fi
}

case "$1" in
    "check")
        check_jackett
        get_configured_indexers
        ;;
    "guide")
        create_sonarr_guide
        cat /home/lou/garuda-media-stack/sonarr-setup-steps.txt
        ;;
    "quick")
        show_quick_indexers
        ;;
    "test")
        test_current_setup
        ;;
    *)
        echo "Usage: $0 {check|guide|quick|test}"
        echo ""
        echo "🔧 Jackett Indexer Setup Helper"
        echo "  check - Check current indexer status"
        echo "  guide - Create detailed setup guide"
        echo "  quick - Show quick setup steps"
        echo "  test  - Test current configuration"
        echo ""
        log "❌ Issue: TorrentGalaxy not configured in Jackett yet"
        log "💡 Solution: Configure indexers in Jackett first, then add to Sonarr"
        echo ""
        show_quick_indexers
        ;;
esac
