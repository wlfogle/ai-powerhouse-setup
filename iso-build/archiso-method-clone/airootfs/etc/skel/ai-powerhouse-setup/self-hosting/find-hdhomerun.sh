#!/bin/bash
# Simple HDHomeRun IP Discovery
# Device ID: 1048EEE4

echo "Scanning for HDHomeRun Connect (1048EEE4)..."

# Quick scan common router IP ranges
for subnet in 192.168.1 192.168.0 10.0.0 10.0.1; do
    echo "Checking $subnet.0/24..."
    for i in {1..254}; do
        ip="$subnet.$i"
        # Quick port check for HDHomeRun control port
        if timeout 0.2 nc -z "$ip" 65001 2>/dev/null; then
            echo "Found device at $ip - checking if it's our HDHomeRun..."
            device_info=$(timeout 2 curl -s "http://$ip/discover.json" 2>/dev/null)
            if [[ "$device_info" == *"1048EEE4"* ]]; then
                echo "✅ Found HDHomeRun 1048EEE4 at: $ip"
                echo "$ip" > /home/lou/garuda-media-stack/hdhomerun_ip.txt
                echo "Device details:"
                echo "$device_info" | jq . 2>/dev/null || echo "$device_info"
                exit 0
            fi
        fi
    done
done

echo "❌ HDHomeRun 1048EEE4 not found. Make sure it's powered on and connected to network."
echo "You can manually set the IP by running:"
echo "echo 'YOUR_HDHOMERUN_IP' > /home/lou/garuda-media-stack/hdhomerun_ip.txt"
