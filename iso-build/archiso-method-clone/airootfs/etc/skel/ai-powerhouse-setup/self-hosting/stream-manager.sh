#!/bin/bash
# Garuda Media Stack - Live Stream Manager
# Handles WWE/AEW and New Orleans Saints live streams

SCRIPT_DIR="/home/lou/garuda-media-stack"
CONFIG_DIR="$SCRIPT_DIR/config"
STREAMS_DIR="$SCRIPT_DIR/streams" 
RECORDINGS_DIR="$SCRIPT_DIR/recordings"
LOG_FILE="$SCRIPT_DIR/stream-manager.log"

# Create directories if they don't exist
mkdir -p "$STREAMS_DIR" "$RECORDINGS_DIR/wrestling" "$RECORDINGS_DIR/saints"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to start WWE/AEW stream
start_wrestling_stream() {
    local event_type="$1"
    local quality="${2:-720p}"
    
    log_message "Starting $event_type wrestling stream at $quality quality"
    
    case "$event_type" in
        "raw"|"smackdown"|"nxt")
            # WWE programming - Use Peacock subscription (user has active subscription)
            log_message "Using Peacock subscription for WWE $event_type"
            stream_url=$(streamlink --json https://www.peacocktv.com/sports/wwe 2>/dev/null | jq -r '.streams.best.url // empty')
            
            # If Peacock fails, try WWE Network international
            if [[ -z "$stream_url" ]]; then
                stream_url=$(streamlink --json https://watch.wwe.com 2>/dev/null | jq -r '.streams.best.url // empty')
            fi
            ;;
        "dynamite"|"rampage"|"collision")
            # AEW programming - TNT/TBS official streams
            if [[ "$event_type" == "rampage" ]]; then
                stream_url=$(streamlink --json https://www.tntdrama.com/watchtnt/east 2>/dev/null | jq -r '.streams.best.url // empty')
            else
                stream_url=$(streamlink --json https://www.tbs.com/watchtbs/east 2>/dev/null | jq -r '.streams.best.url // empty')
            fi
            ;;
        *)
            log_message "Unknown wrestling event type: $event_type"
            return 1
            ;;
    esac
    
    if [[ -z "$stream_url" ]]; then
        log_message "No stream URL found for $event_type"
        return 1
    fi
    
    # Start recording
    local output_file="$RECORDINGS_DIR/wrestling/${event_type}_$(date +%Y%m%d_%H%M).mkv"
    
    nohup ffmpeg -i "$stream_url" \
        -c:v libx264 -preset medium -crf 23 \
        -c:a aac -b:a 128k \
        -f segment -segment_time 3600 -segment_format mkv \
        -strftime 1 "$output_file" \
        > "$SCRIPT_DIR/ffmpeg_${event_type}.log" 2>&1 &
    
    local ffmpeg_pid=$!
    echo "$ffmpeg_pid" > "$SCRIPT_DIR/pids/${event_type}.pid"
    
    log_message "Started $event_type stream recording (PID: $ffmpeg_pid)"
    
    # Start HLS stream for web viewing
    nohup ffmpeg -i "$stream_url" \
        -c:v libx264 -preset veryfast -tune zerolatency \
        -s 1280x720 -r 30 \
        -c:a aac -b:a 128k \
        -f hls -hls_time 6 -hls_list_size 10 -hls_flags delete_segments \
        "$STREAMS_DIR/${event_type}.m3u8" \
        > "$SCRIPT_DIR/hls_${event_type}.log" 2>&1 &
        
    local hls_pid=$!
    echo "$hls_pid" > "$SCRIPT_DIR/pids/${event_type}_hls.pid"
    
    log_message "Started $event_type HLS stream (PID: $hls_pid)"
}

# Function to start Saints stream
start_saints_stream() {
    local game_type="${1:-regular}"  # regular, preseason, playoff
    local quality="${2:-1080p}"
    
    log_message "Starting Saints $game_type game stream at $quality quality"
    
    # PRIORITY 1: Check HDHomeRun for local OTA broadcast (best quality, no buffering)
    log_message "Checking HDHomeRun for local Saints broadcast..."
    if [[ -x "$SCRIPT_DIR/hdhomerun-manager.sh" ]]; then
        "$SCRIPT_DIR/hdhomerun-manager.sh" saints-fallback "$game_type"
        if [[ $? -eq 0 ]]; then
            log_message "Saints stream started via HDHomeRun OTA"
            return 0
        fi
    fi
    
    # PRIORITY 2: Check if it's Thursday Night Football (Prime Video exclusive)
    local current_day=$(date +%A | tr '[:upper:]' '[:lower:]')
    if [[ "$current_day" == "thursday" ]]; then
        log_message "Thursday Night Football - Using Prime Video subscription"
        stream_url=$(streamlink --json https://www.amazon.com/gp/video/sports/nfl 2>/dev/null | jq -r '.streams.best.url // empty')
    fi
    
    # If not TNF or Prime failed, try other NFL sources
    if [[ -z "$stream_url" ]]; then
        local sources=(
            "https://plus.nfl.com"
            "https://www.nfl.com/network/"
            "https://www.wwltv.com/watch"  # Local New Orleans
            "https://www.fox8live.com/live"
            "https://www.amazon.com/gp/video/sports/nfl"  # Prime backup
        )
    fi
    
    local stream_url=""
    for source in "${sources[@]}"; do
        stream_url=$(streamlink --json "$source" 2>/dev/null | jq -r '.streams.best.url // empty')
        if [[ -n "$stream_url" ]]; then
            log_message "Found Saints stream source: $source"
            break
        fi
    done
    
    if [[ -z "$stream_url" ]]; then
        log_message "No Saints stream URL found"
        return 1
    fi
    
    # Start recording
    local output_file="$RECORDINGS_DIR/saints/saints_${game_type}_$(date +%Y%m%d_%H%M).mp4"
    
    nohup ffmpeg -i "$stream_url" \
        -c:v libx264 -preset medium -crf 21 \
        -c:a aac -b:a 192k \
        -f segment -segment_time 3600 -segment_format mp4 \
        -strftime 1 "$output_file" \
        > "$SCRIPT_DIR/ffmpeg_saints.log" 2>&1 &
    
    local ffmpeg_pid=$!
    echo "$ffmpeg_pid" > "$SCRIPT_DIR/pids/saints.pid"
    
    log_message "Started Saints game recording (PID: $ffmpeg_pid)"
    
    # Start HLS stream
    nohup ffmpeg -i "$stream_url" \
        -c:v libx264 -preset veryfast -tune zerolatency \
        -s 1920x1080 -r 30 \
        -c:a aac -b:a 192k \
        -f hls -hls_time 6 -hls_list_size 10 -hls_flags delete_segments \
        "$STREAMS_DIR/saints_live.m3u8" \
        > "$SCRIPT_DIR/hls_saints.log" 2>&1 &
        
    local hls_pid=$!
    echo "$hls_pid" > "$SCRIPT_DIR/pids/saints_hls.pid"
    
    log_message "Started Saints HLS stream (PID: $hls_pid)"
}

# Function to stop all streams
stop_all_streams() {
    log_message "Stopping all active streams..."
    
    if [[ -d "$SCRIPT_DIR/pids" ]]; then
        for pid_file in "$SCRIPT_DIR/pids"/*.pid; do
            if [[ -f "$pid_file" ]]; then
                local pid=$(cat "$pid_file")
                if kill -0 "$pid" 2>/dev/null; then
                    kill "$pid"
                    log_message "Stopped process $pid"
                fi
                rm "$pid_file"
            fi
        done
    fi
}

# Function to list active streams
list_active_streams() {
    echo "Active Streams:"
    if [[ -d "$SCRIPT_DIR/pids" ]]; then
        for pid_file in "$SCRIPT_DIR/pids"/*.pid; do
            if [[ -f "$pid_file" ]]; then
                local pid=$(cat "$pid_file")
                local stream_name=$(basename "$pid_file" .pid)
                if kill -0 "$pid" 2>/dev/null; then
                    echo "  $stream_name (PID: $pid)"
                else
                    rm "$pid_file"
                fi
            fi
        done
    else
        echo "  No active streams"
    fi
}

# Function to get stream status for web interface
get_stream_status_json() {
    echo "{"
    echo '  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
    echo '  "active_streams": ['
    
    local first=true
    if [[ -d "$SCRIPT_DIR/pids" ]]; then
        for pid_file in "$SCRIPT_DIR/pids"/*.pid; do
            if [[ -f "$pid_file" ]]; then
                local pid=$(cat "$pid_file")
                local stream_name=$(basename "$pid_file" .pid)
                if kill -0 "$pid" 2>/dev/null; then
                    [[ "$first" == false ]] && echo ","
                    echo -n '    {"name": "'$stream_name'", "pid": '$pid', "status": "active"}'
                    first=false
                fi
            fi
        done
    fi
    
    echo ""
    echo "  ]"
    echo "}"
}

# Create PID directory
mkdir -p "$SCRIPT_DIR/pids"

# Main command processing
case "$1" in
    "start-wrestling")
        start_wrestling_stream "$2" "$3"
        ;;
    "start-saints")
        start_saints_stream "$2" "$3"
        ;;
    "stop")
        stop_all_streams
        ;;
    "status")
        list_active_streams
        ;;
    "status-json")
        get_stream_status_json
        ;;
    "auto-record")
        # Auto-recording based on schedule (would be called by cron)
        current_time=$(date +%H:%M)
        current_day=$(date +%A | tr '[:upper:]' '[:lower:]')
        
        # Check wrestling schedule
        if [[ "$current_day" == "monday" && "$current_time" == "20:00" ]]; then
            start_wrestling_stream "raw" "1080p"
        elif [[ "$current_day" == "wednesday" && "$current_time" == "20:00" ]]; then
            start_wrestling_stream "dynamite" "1080p"  
        elif [[ "$current_day" == "friday" && "$current_time" == "20:00" ]]; then
            start_wrestling_stream "smackdown" "1080p"
        elif [[ "$current_day" == "friday" && "$current_time" == "22:00" ]]; then
            start_wrestling_stream "rampage" "1080p"
        fi
        ;;
    *)
        echo "Garuda Media Stack - Stream Manager"
        echo "Usage: $0 {start-wrestling|start-saints|stop|status|status-json|auto-record}"
        echo ""
        echo "Examples:"
        echo "  $0 start-wrestling raw 1080p"
        echo "  $0 start-wrestling dynamite 720p"
        echo "  $0 start-saints regular 1080p"
        echo "  $0 status"
        echo "  $0 stop"
        ;;
esac
