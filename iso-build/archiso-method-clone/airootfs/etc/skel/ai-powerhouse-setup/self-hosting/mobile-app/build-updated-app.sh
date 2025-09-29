#!/bin/bash

# Garuda Media Stack - Build Updated Android App
# This script builds the streamlined version with only working services

set -e

# Change to the Android project directory
cd "$(dirname "$0")/GarudaMediaStack"

echo "🏗️ Building Garuda Media Stack Android App (Streamlined Version)..."
echo "Services included: Radarr, Sonarr, Lidarr, qBittorrent, Jackett"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
./gradlew clean

# Build debug APK
echo "🔨 Building debug APK..."
./gradlew assembleDebug

# Check if build was successful
if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    echo "✅ Build successful!"
    echo "📱 APK location: app/build/outputs/apk/debug/app-debug.apk"
    
    # Copy APK to root directory for easy access
    cp app/build/outputs/apk/debug/app-debug.apk ../garuda-media-stack-streamlined.apk
    echo "📋 APK copied to: ../garuda-media-stack-streamlined.apk"
    
    # Display APK info
    echo ""
    echo "📊 APK Information:"
    ls -lh ../garuda-media-stack-streamlined.apk
else
    echo "❌ Build failed - APK not found"
    exit 1
fi

echo ""
echo "🎉 Streamlined Garuda Media Stack app built successfully!"
echo "Features:"
echo "  • Movie management (Radarr)"
echo "  • TV show management (Sonarr)" 
echo "  • Music management (Lidarr)"
echo "  • Download client (qBittorrent)"
echo "  • Torrent search (Jackett)"
echo ""
echo "To install: adb install ../garuda-media-stack-streamlined.apk"
