#!/bin/bash

echo "🔨 Building Garuda Media Stack Android App..."

# Check for Android SDK
if [ -z "$ANDROID_HOME" ]; then
    echo "⚠️ ANDROID_HOME not set. Please set your Android SDK path."
    echo "Example: export ANDROID_HOME=/path/to/android-sdk"
    exit 1
fi

# Clean and build
echo "🧹 Cleaning project..."
./gradlew clean

echo "🔨 Building debug APK..."
./gradlew assembleDebug

echo "📦 Building release APK..."
./gradlew assembleRelease

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📱 APK Files created:"
    echo "  Debug: app/build/outputs/apk/debug/app-debug.apk"
    echo "  Release: app/build/outputs/apk/release/app-release-unsigned.apk"
    echo ""
    echo "🔧 To install debug APK:"
    echo "  adb install app/build/outputs/apk/debug/app-debug.apk"
    echo ""
    echo "📺 For Android TV/Fire TV:"
    echo "  adb connect [DEVICE_IP]:5555"
    echo "  adb install app/build/outputs/apk/debug/app-debug.apk"
else
    echo "❌ Build failed!"
    exit 1
fi
