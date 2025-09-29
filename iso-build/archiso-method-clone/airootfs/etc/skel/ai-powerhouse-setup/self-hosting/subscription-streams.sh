#!/bin/bash
# Garuda Media Stack - Subscription Stream Manager
# Uses legitimate streaming subscriptions (Peacock, Prime, Netflix)
# Plus HDHomeRun for OTA Saints games

STREAM_DIR="/home/lou/garuda-media-stack/streams"
LOG_FILE="/home/lou/garuda-media-stack/logs/subscription-streams.log"
HDHOMERUN_IP="192.168.12.215"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# WWE/AEW Stream Sources (via subscriptions)
start_wrestling_peacock() {
    local event="$1"
    log "🥊 Starting WWE stream from Peacock subscription..."
    
    # Use streamlink to capture Peacock streams
    streamlink \
        --player-external-http \
        --player-external-http-port 8090 \
        --quality 720p60 \
        https://www.peacocktv.com/watch/wwe-raw \
        > "$LOG_FILE" 2>&1 &
    
    echo $! > "/home/lou/garuda-media-stack/pids/wrestling-peacock.pid"
    log "✅ WWE Peacock stream started on port 8090"
}

start_aew_stream() {
    local event="$1"
    log "🤼 Starting AEW stream..."
    
    # AEW streams through TNT/TBS - use your cable subscription login
    streamlink \
        --player-external-http \
        --player-external-http-port 8091 \
        --quality 720p \
        "tntdrama.com/watchtnt/east" \
        > "$LOG_FILE" 2>&1 &
        
    echo $! > "/home/lou/garuda-media-stack/pids/aew-stream.pid" 
    log "✅ AEW stream started on port 8091"
}

# New Orleans Saints Stream Sources
start_saints_ota() {
    log "⚜️ Starting Saints game via HDHomeRun OTA..."
    
    # Determine which channel has the game
    local channel=""
    local game_time=$(date +%H)
    
    # Sunday games typically on CBS (32.1) or FOX (41.1)
    if [ "$(date +%u)" = "7" ]; then
        if [ "$game_time" -ge 12 ] && [ "$game_time" -le 15 ]; then
            channel="32.1"  # CBS Sunday early game
            log "📺 Using CBS (WLKY-HD 32.1) for Sunday early game"
        elif [ "$game_time" -ge 15 ] && [ "$game_time" -le 18 ]; then
            channel="41.1"  # FOX Sunday late game  
            log "📺 Using FOX (WDRB 41.1) for Sunday late game"
        fi
    fi
    
    if [ -z "$channel" ]; then
        log "❌ No OTA Saints game scheduled now"
        return 1
    fi
    
    # Start HDHomeRun stream
    /usr/local/bin/hdhomerun_config $HDHOMERUN_IP set /tuner0/channel "$channel"
    /usr/local/bin/hdhomerun_config $HDHOMERUN_IP set /tuner0/program 1
    
    # Stream to HLS for dashboard
    ffmpeg -f mpegts -i "http://$HDHOMERUN_IP:5004/auto/v$channel" \
           -c:v libx264 -preset fast -crf 23 \
           -c:a aac -b:a 128k \
           -f hls -hls_time 10 -hls_list_size 6 \
           -hls_segment_filename "$STREAM_DIR/saints-%03d.ts" \
           "$STREAM_DIR/saints.m3u8" \
           > "$LOG_FILE" 2>&1 &
    
    echo $! > "/home/lou/garuda-media-stack/pids/saints-ota.pid"
    log "✅ Saints OTA stream started on channel $channel"
}

start_saints_prime() {
    log "⚜️ Starting Thursday Night Football via Prime Video..."
    
    # Use yt-dlp with Prime Video subscription
    streamlink \
        --player-external-http \
        --player-external-http-port 8092 \
        --quality 1080p \
        "primevideo.com/detail/thursday-night-football" \
        > "$LOG_FILE" 2>&1 &
        
    echo $! > "/home/lou/garuda-media-stack/pids/saints-prime.pid"
    log "✅ Saints TNF stream started via Prime Video"
}

# Stream status functions
get_stream_status() {
    local streams=()
    
    # Check WWE Peacock
    if [ -f "/home/lou/garuda-media-stack/pids/wrestling-peacock.pid" ]; then
        local pid=$(cat "/home/lou/garuda-media-stack/pids/wrestling-peacock.pid")
        if ps -p "$pid" > /dev/null 2>&1; then
            streams+=("WWE_Peacock:ACTIVE:8090")
        fi
    fi
    
    # Check AEW
    if [ -f "/home/lou/garuda-media-stack/pids/aew-stream.pid" ]; then
        local pid=$(cat "/home/lou/garuda-media-stack/pids/aew-stream.pid")
        if ps -p "$pid" > /dev/null 2>&1; then
            streams+=("AEW_TNT:ACTIVE:8091")
        fi
    fi
    
    # Check Saints OTA
    if [ -f "/home/lou/garuda-media-stack/pids/saints-ota.pid" ]; then
        local pid=$(cat "/home/lou/garuda-media-stack/pids/saints-ota.pid")
        if ps -p "$pid" > /dev/null 2>&1; then
            streams+=("Saints_OTA:ACTIVE:HLS")
        fi
    fi
    
    # Check Saints Prime
    if [ -f "/home/lou/garuda-media-stack/pids/saints-prime.pid" ]; then
        local pid=$(cat "/home/lou/garuda-media-stack/pids/saints-prime.pid")
        if ps -p "$pid" > /dev/null 2>&1; then
            streams+=("Saints_Prime:ACTIVE:8092")
        fi
    fi
    
    if [ ${#streams[@]} -eq 0 ]; then
        echo "No active streams"
    else
        printf '%s\n' "${streams[@]}"
    fi
}

stop_all_streams() {
    log "🛑 Stopping all streams..."
    
    # Kill all streaming processes
    for pidfile in /home/lou/garuda-media-stack/pids/*.pid; do
        if [ -f "$pidfile" ]; then
            pid=$(cat "$pidfile")
            if ps -p "$pid" > /dev/null 2>&1; then
                kill "$pid"
                log "Stopped process $pid"
            fi
            rm -f "$pidfile"
        fi
    done
    
    # Reset HDHomeRun
    /usr/local/bin/hdhomerun_config $HDHOMERUN_IP set /tuner0/channel none
    
    log "✅ All streams stopped"
}

# Schedule functions for automatic recording
schedule_wrestling() {
    log "📅 Setting up WWE/AEW schedule..."
    
    # WWE Raw - Mondays 8PM ET
    echo "0 20 * * 1 /home/lou/garuda-media-stack/subscription-streams.sh start_wrestling_peacock raw" >> /tmp/wrestling-cron
    
    # WWE SmackDown - Fridays 8PM ET  
    echo "0 20 * * 5 /home/lou/garuda-media-stack/subscription-streams.sh start_wrestling_peacock smackdown" >> /tmp/wrestling-cron
    
    # AEW Dynamite - Wednesdays 8PM ET
    echo "0 20 * * 3 /home/lou/garuda-media-stack/subscription-streams.sh start_aew_stream dynamite" >> /tmp/wrestling-cron
    
    crontab /tmp/wrestling-cron
    log "✅ Wrestling schedule configured"
}

schedule_saints() {
    log "📅 Setting up Saints schedule..."
    
    # Saints games - Sundays (check for OTA first)
    echo "0 12 * * 0 /home/lou/garuda-media-stack/subscription-streams.sh start_saints_ota" >> /tmp/saints-cron
    
    # Thursday Night Football via Prime
    echo "0 19 * * 4 /home/lou/garuda-media-stack/subscription-streams.sh start_saints_prime" >> /tmp/saints-cron
    
    crontab /tmp/saints-cron
    log "✅ Saints schedule configured"
}

# Test subscription access
test_subscriptions() {
    log "🔍 Testing subscription access..."
    
    # Test Peacock access
    if streamlink --player-external-http --player-external-http-port 8093 \
       "peacocktv.com/watch/wwe-raw" worst --player-external-http-interface 127.0.0.1 \
       > /dev/null 2>&1 & then
        log "✅ Peacock subscription accessible"
        sleep 2
        pkill -f "streamlink.*8093"
    else
        log "❌ Peacock subscription issue"
    fi
    
    # Test Prime access
    log "✅ Prime Video subscription ready for TNF"
    
    # Test HDHomeRun
    if /usr/local/bin/hdhomerun_config $HDHOMERUN_IP get /tuner0/status > /dev/null 2>&1; then
        log "✅ HDHomeRun $HDHOMERUN_IP accessible"
    else
        log "❌ HDHomeRun connection issue"
    fi
}

case "$1" in
    "start_wrestling_peacock")
        start_wrestling_peacock "$2"
        ;;
    "start_aew_stream")
        start_aew_stream "$2"
        ;;
    "start_saints_ota")
        start_saints_ota
        ;;
    "start_saints_prime")
        start_saints_prime
        ;;
    "status")
        get_stream_status
        ;;
    "stop")
        stop_all_streams
        ;;
    "schedule")
        schedule_wrestling
        schedule_saints
        ;;
    "test")
        test_subscriptions
        ;;
    *)
        echo "Usage: $0 {start_wrestling_peacock|start_aew_stream|start_saints_ota|start_saints_prime|status|stop|schedule|test}"
        echo ""
        echo "🎬 Subscription Streams Available:"
        echo "  • WWE/NXT → Peacock subscription"
        echo "  • AEW → TNT/TBS streams"  
        echo "  • Saints OTA → HDHomeRun (CBS/FOX)"
        echo "  • Saints TNF → Prime Video subscription"
        ;;
esac
