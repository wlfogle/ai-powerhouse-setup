#!/bin/bash
# HDHomeRun Manager for Garuda Media Stack
# Manages OTA TV recording and streaming via HDHomeRun Connect

SCRIPT_DIR="/home/lou/garuda-media-stack"
CONFIG_DIR="$SCRIPT_DIR/config"
RECORDINGS_DIR="$SCRIPT_DIR/recordings/ota"
STREAMS_DIR="$SCRIPT_DIR/streams"
LOG_FILE="$SCRIPT_DIR/hdhomerun.log"

# Create directories
mkdir -p "$RECORDINGS_DIR" "$STREAMS_DIR"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Discover HDHomeRun device on network
discover_hdhomerun() {
    log_message "Discovering HDHomeRun device 1048EEE4..."
    
    local device_ip=""
    local device_id="1048EEE4"
    
    # Method 1: Use HDHomeRun's online discovery service
    device_ip=$(curl -s "http://my.hdhomerun.com/api/discover.php?discover=$device_id" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    
    # Method 2: Scan local network for device responding to device ID query
    if [[ -z "$device_ip" ]]; then
        log_message "Scanning local network for HDHomeRun $device_id..."
        for ip in 192.168.1.{1..254} 192.168.0.{1..254} 10.0.0.{1..254}; do
            # Check if device responds and matches our device ID
            local response=$(timeout 2 curl -s "http://$ip/discover.json" 2>/dev/null | grep -o "$device_id")
            if [[ -n "$response" ]]; then
                device_ip="$ip"
                log_message "Found HDHomeRun $device_id at $device_ip"
                break
            fi
        done
    fi
    
    if [[ -n "$device_ip" ]]; then
        echo "$device_ip" > "$SCRIPT_DIR/hdhomerun_ip.txt"
        echo "$device_id" > "$SCRIPT_DIR/hdhomerun_id.txt"
        log_message "HDHomeRun device $device_id found at: $device_ip"
        
        # Get device info
        curl -s "http://$device_ip/discover.json" > "$SCRIPT_DIR/hdhomerun_info.json"
        return 0
    else
        log_message "HDHomeRun device $device_id not found"
        return 1
    fi
}

# Get device IP
get_device_ip() {
    if [[ -f "$SCRIPT_DIR/hdhomerun_ip.txt" ]]; then
        cat "$SCRIPT_DIR/hdhomerun_ip.txt"
    else
        discover_hdhomerun
        cat "$SCRIPT_DIR/hdhomerun_ip.txt" 2>/dev/null
    fi
}

# Get channel lineup
scan_channels() {
    local device_ip=$(get_device_ip)
    if [[ -z "$device_ip" ]]; then
        log_message "No HDHomeRun device found"
        return 1
    fi
    
    log_message "Scanning channels on HDHomeRun at $device_ip"
    
    # Get channel lineup via HTTP API
    curl -s "http://$device_ip/lineup.json" > "$SCRIPT_DIR/channel_lineup.json"
    
    if [[ -s "$SCRIPT_DIR/channel_lineup.json" ]]; then
        log_message "Channel lineup updated"
        # Parse and display major channels
        echo "Available channels:"
        jq -r '.[] | select(.GuideName | test("CBS|FOX|NBC|ABC|WWL|WDSU|WGNO")) | "\(.GuideNumber) - \(.GuideName)"' "$SCRIPT_DIR/channel_lineup.json"
    else
        log_message "Failed to get channel lineup"
        return 1
    fi
}

# Record from specific channel
record_channel() {
    local channel="$1"
    local duration="${2:-3600}"  # Default 1 hour
    local output_name="${3:-channel_${channel}_$(date +%Y%m%d_%H%M)}"
    
    local device_ip=$(get_device_ip)
    if [[ -z "$device_ip" ]]; then
        log_message "No HDHomeRun device found"
        return 1
    fi
    
    log_message "Recording channel $channel for ${duration}s to $output_name"
    
    # Use ffmpeg to record from HDHomeRun stream
    local stream_url="http://$device_ip:5004/auto/v$channel"
    local output_file="$RECORDINGS_DIR/${output_name}.ts"
    
    nohup timeout "$duration" ffmpeg -i "$stream_url" \
        -c copy \
        -t "$duration" \
        "$output_file" \
        > "$SCRIPT_DIR/ffmpeg_${output_name}.log" 2>&1 &
    
    local ffmpeg_pid=$!
    echo "$ffmpeg_pid" > "$SCRIPT_DIR/pids/record_${channel}.pid"
    
    log_message "Started recording channel $channel (PID: $ffmpeg_pid)"
}

# Record Saints game (auto-detect best local channel)
record_saints_game() {
    local game_type="${1:-regular}"
    local device_ip=$(get_device_ip)
    
    if [[ -z "$device_ip" ]]; then
        log_message "No HDHomeRun device found"
        return 1
    fi
    
    log_message "Recording Saints $game_type game from OTA broadcast"
    
    # Priority order for Saints games (CBS, FOX, ABC for different time slots)
    # Using actual Louisville channels from HDHomeRun lineup
    local channels=("32.1" "41.1" "11.1" "3.1")  # WLKY (CBS), WDRB (FOX), WHAS (ABC), WAVE
    local best_channel=""
    
    # Check which channel currently has the best signal for Saints game
    for channel in "${channels[@]}"; do
        # Test signal strength
        local signal_strength=$(curl -s "http://$device_ip/tuner0/streaminfo" | grep -o 'ss=[0-9]*' | cut -d'=' -f2)
        if [[ "$signal_strength" -gt 70 ]]; then  # Good signal
            best_channel="$channel"
            break
        fi
    done
    
    if [[ -z "$best_channel" ]]; then
        best_channel="4.1"  # Default to CBS (primary Saints broadcaster)
        log_message "Using default channel $best_channel for Saints game"
    else
        log_message "Selected channel $best_channel for Saints game (signal: $signal_strength)"
    fi
    
    # Record for 4 hours (typical game length)
    record_channel "$best_channel" 14400 "saints_${game_type}_$(date +%Y%m%d_%H%M)"
}

# Start live stream from HDHomeRun channel
start_ota_stream() {
    local channel="$1"
    local stream_name="${2:-ota_${channel}}"
    
    local device_ip=$(get_device_ip)
    if [[ -z "$device_ip" ]]; then
        log_message "No HDHomeRun device found"
        return 1
    fi
    
    log_message "Starting OTA stream from channel $channel"
    
    local stream_url="http://$device_ip:5004/auto/v$channel"
    
    # Start HLS stream for web viewing
    nohup ffmpeg -i "$stream_url" \
        -c:v libx264 -preset veryfast -tune zerolatency \
        -s 1920x1080 -r 30 \
        -c:a aac -b:a 192k \
        -f hls -hls_time 6 -hls_list_size 10 -hls_flags delete_segments \
        "$STREAMS_DIR/${stream_name}.m3u8" \
        > "$SCRIPT_DIR/hls_${stream_name}.log" 2>&1 &
        
    local hls_pid=$!
    echo "$hls_pid" > "$SCRIPT_DIR/pids/${stream_name}_hls.pid"
    
    log_message "Started OTA HLS stream for channel $channel (PID: $hls_pid)"
    
    # Also start direct recording
    nohup ffmpeg -i "$stream_url" \
        -c copy \
        "$RECORDINGS_DIR/live_${stream_name}_$(date +%Y%m%d_%H%M).ts" \
        > "$SCRIPT_DIR/record_${stream_name}.log" 2>&1 &
        
    local record_pid=$!
    echo "$record_pid" > "$SCRIPT_DIR/pids/record_${stream_name}.pid"
    
    log_message "Started OTA recording for channel $channel (PID: $record_pid)"
}

# Get tuner status
get_tuner_status() {
    local device_ip=$(get_device_ip)
    if [[ -z "$device_ip" ]]; then
        echo "HDHomeRun device not found"
        return 1
    fi
    
    echo "HDHomeRun Status ($device_ip):"
    echo ""
    
    # Get status for both tuners
    for tuner in 0 1; do
        echo "Tuner $tuner:"
        local status=$(curl -s "http://$device_ip/tuner$tuner/streaminfo")
        if [[ -n "$status" ]]; then
            echo "  $status"
        else
            echo "  Idle"
        fi
        echo ""
    done
    
    # Show current lineup
    echo "Available Channels:"
    if [[ -f "$SCRIPT_DIR/channel_lineup.json" ]]; then
        jq -r '.[] | "\(.GuideNumber) - \(.GuideName)"' "$SCRIPT_DIR/channel_lineup.json" | head -10
    else
        echo "  Run 'scan-channels' first"
    fi
}

# Integration with main stream manager
saints_ota_fallback() {
    local game_type="${1:-regular}"
    
    log_message "Starting Saints OTA fallback recording"
    
    # Use CBS as primary Saints channel (most Saints games)
    start_ota_stream "4.1" "saints_cbs"
    
    # If 2 tuners available, also record FOX as backup
    local device_ip=$(get_device_ip)
    local tuner1_status=$(curl -s "http://$device_ip/tuner1/streaminfo")
    
    if [[ -z "$tuner1_status" ]]; then
        log_message "Tuner 1 available, starting FOX backup"
        start_ota_stream "8.1" "saints_fox"
    fi
}

# Create PID directory
mkdir -p "$SCRIPT_DIR/pids"

# Main command processing
case "$1" in
    "discover")
        discover_hdhomerun
        ;;
    "scan-channels")
        scan_channels
        ;;
    "record-channel")
        record_channel "$2" "$3" "$4"
        ;;
    "record-saints")
        record_saints_game "$2"
        ;;
    "start-ota-stream")
        start_ota_stream "$2" "$3"
        ;;
    "saints-fallback")
        saints_ota_fallback "$2"
        ;;
    "status")
        get_tuner_status
        ;;
    "stop")
        # Stop all HDHomeRun related processes
        if [[ -d "$SCRIPT_DIR/pids" ]]; then
            for pid_file in "$SCRIPT_DIR/pids"/record_*.pid "$SCRIPT_DIR/pids"/*_hls.pid; do
                if [[ -f "$pid_file" ]]; then
                    pid=$(cat "$pid_file")
                    if kill -0 "$pid" 2>/dev/null; then
                        kill "$pid"
                        log_message "Stopped HDHomeRun process $pid"
                    fi
                    rm "$pid_file"
                fi
            done
        fi
        ;;
    *)
        echo "HDHomeRun Manager - Garuda Media Stack"
        echo "Usage: $0 {discover|scan-channels|record-channel|record-saints|start-ota-stream|saints-fallback|status|stop}"
        echo ""
        echo "Examples:"
        echo "  $0 discover"
        echo "  $0 scan-channels"
        echo "  $0 record-saints regular"
        echo "  $0 record-channel 4.1 3600 saints_cbs"
        echo "  $0 start-ota-stream 8.1 fox_live"
        echo "  $0 status"
        ;;
esac
