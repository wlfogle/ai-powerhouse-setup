#!/bin/bash
# FlareSolverr Startup Script for Garuda Media Stack

FLARESOLVERR_DIR="/opt/FlareSolverr"
LOG_FILE="/home/lou/garuda-media-stack/logs/flaresolverr.log"
PID_FILE="/home/lou/garuda-media-stack/pids/flaresolverr.pid"

# Create directories if they don't exist
mkdir -p /home/lou/garuda-media-stack/logs
mkdir -p /home/lou/garuda-media-stack/pids

# Set environment variables for FlareSolverr
export LOG_LEVEL=info
export LOG_HTML=false
export CAPTCHA_SOLVER=none
export TZ=America/Kentucky/Louisville
export HOST=0.0.0.0
export PORT=8191
export HEADLESS=true

# Set Chrome/Chromium path
export BROWSER_PATH="/usr/bin/chromium"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

start_flaresolverr() {
    if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null 2>&1; then
        log "🔥 FlareSolverr is already running (PID: $(cat $PID_FILE))"
        return 0
    fi

    log "🚀 Starting FlareSolverr on port $PORT..."
    
    # Start Xvfb for headless browser operation
    export DISPLAY=:99
    Xvfb :99 -screen 0 1920x1080x24 > /dev/null 2>&1 &
    XVFB_PID=$!
    echo $XVFB_PID > "/tmp/xvfb.pid"
    
    sleep 2
    
    # Start FlareSolverr
    cd "$FLARESOLVERR_DIR"
    python3 src/flaresolverr.py > "$LOG_FILE" 2>&1 &
    FLARE_PID=$!
    
    echo $FLARE_PID > "$PID_FILE"
    log "✅ FlareSolverr started successfully (PID: $FLARE_PID)"
    log "📡 FlareSolverr available at http://localhost:$PORT/v1"
    
    return 0
}

stop_flaresolverr() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            log "🛑 Stopping FlareSolverr (PID: $PID)..."
            kill "$PID"
            rm -f "$PID_FILE"
            log "✅ FlareSolverr stopped"
        else
            log "⚠️ FlareSolverr process not found, removing stale PID file"
            rm -f "$PID_FILE"
        fi
    else
        log "⚠️ FlareSolverr is not running"
    fi
    
    # Stop Xvfb if running
    if [ -f "/tmp/xvfb.pid" ]; then
        XVFB_PID=$(cat "/tmp/xvfb.pid")
        if ps -p "$XVFB_PID" > /dev/null 2>&1; then
            kill "$XVFB_PID"
            rm -f "/tmp/xvfb.pid"
            log "🖥️ Xvfb display server stopped"
        fi
    fi
}

status_flaresolverr() {
    if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null 2>&1; then
        PID=$(cat "$PID_FILE")
        log "✅ FlareSolverr is running (PID: $PID) on http://localhost:$PORT/v1"
        return 0
    else
        log "❌ FlareSolverr is not running"
        return 1
    fi
}

test_flaresolverr() {
    log "🧪 Testing FlareSolverr functionality..."
    
    # Test basic API endpoint
    RESPONSE=$(curl -s -w "%{http_code}" "http://localhost:$PORT/v1" -o /dev/null)
    
    if [ "$RESPONSE" = "405" ] || [ "$RESPONSE" = "200" ]; then
        log "✅ FlareSolverr API is responding"
        
        # Test with a simple request
        TEST_RESPONSE=$(curl -s -X POST "http://localhost:$PORT/v1" \
            -H "Content-Type: application/json" \
            -d '{
                "cmd": "request.get",
                "url": "http://httpbin.org/ip",
                "maxTimeout": 60000
            }' | head -c 100)
        
        if echo "$TEST_RESPONSE" | grep -q "solution"; then
            log "✅ FlareSolverr test request successful"
        else
            log "⚠️ FlareSolverr API responded but test request may have failed"
        fi
    else
        log "❌ FlareSolverr API not responding (HTTP: $RESPONSE)"
        return 1
    fi
}

case "$1" in
    start)
        start_flaresolverr
        ;;
    stop)
        stop_flaresolverr
        ;;
    restart)
        stop_flaresolverr
        sleep 2
        start_flaresolverr
        ;;
    status)
        status_flaresolverr
        ;;
    test)
        test_flaresolverr
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|test}"
        echo ""
        echo "🔥 FlareSolverr Management Script"
        echo "  start   - Start FlareSolverr service"
        echo "  stop    - Stop FlareSolverr service"  
        echo "  restart - Restart FlareSolverr service"
        echo "  status  - Check FlareSolverr status"
        echo "  test    - Test FlareSolverr functionality"
        echo ""
        status_flaresolverr
        exit 1
        ;;
esac
