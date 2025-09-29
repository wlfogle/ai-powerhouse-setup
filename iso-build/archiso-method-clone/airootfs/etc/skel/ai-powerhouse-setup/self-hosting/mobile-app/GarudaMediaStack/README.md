# Garuda Media Stack Android App (Streamlined)

A streamlined Android application providing access to the core working services of your Garuda Media Stack.

## Features

📱 **Focused Experience**: Clean interface with only working services
📋 **Content Management**: Automated media acquisition and management
⬇️ **Download Management**: Complete torrent workflow from search to download
🎯 **Reliability**: Only includes services confirmed to be working
🎮 **Remote Control**: Full D-pad and remote control support

## Services Included

This streamlined version includes only the core services that are currently working reliably:

### Content Management  
- **🎬 Radarr** (Port 7878) - Movie automation
- **📺 Sonarr** (Port 8989) - TV show automation
- **🎵 Lidarr** (Port 8686) - Music automation

### Downloads & Search
- **⬇️ qBittorrent** (Port 5080) - Download client
- **🔍 Jackett** (Port 9117) - Torrent indexer search

## Version Notes

**What's different in the streamlined version:**
- Removed services with startup issues or missing dependencies
- Cleaner, more focused user interface
- Better reliability and user experience
- Faster app startup and navigation

**Removed services:** Jellyfin, Jellyseerr, Readarr, Calibre-Web, Audiobookshelf, Pulsarr

## Installation

### Prerequisites
- Android SDK
- Android Studio (optional)
- Device with Android 5.0+ (API 21+)

### Building the App

```bash
# Set Android SDK path
export ANDROID_HOME=/path/to/android-sdk

# Build the streamlined app
./build-updated-app.sh
```

### Installing on Device

```bash
# Install debug version
adb install app/build/outputs/apk/debug/app-debug.apk

# For Android TV/Fire TV
adb connect [DEVICE_IP]:5555
adb install app/build/outputs/apk/debug/app-debug.apk
```

## Configuration

The app is pre-configured to connect to:
- **Server IP**: 192.168.12.172
- **All service ports**: As defined in your media stack

To change the server IP, edit `app/src/main/res/values/strings.xml`

## Usage

1. **Launch App**: Open "Garuda Media Stack" on your device
2. **Select Service**: Tap any service card to open it
3. **Navigate**: Use touch or D-pad to navigate web interfaces
4. **Go Back**: Use back button or remote to return to main menu

### Android TV/Fire TV

- Use D-pad to navigate service cards
- Press OK/Select to open services
- Use back button to return to main menu
- All services optimized for TV viewing

## Development

### Project Structure
```
app/
├── src/main/
│   ├── java/com/garuda/mediastack/
│   │   ├── MainActivity.kt          # Main service launcher
│   │   └── WebViewActivity.kt       # Service web interface
│   ├── res/
│   │   ├── layout/                  # UI layouts
│   │   ├── values/                  # Strings, colors, styles
│   │   └── drawable/                # Icons and graphics
│   └── AndroidManifest.xml
├── build.gradle                     # App dependencies
└── proguard-rules.pro
```

### Adding New Services

1. Add service URL to `strings.xml`
2. Add service card to `activity_main.xml`  
3. Add click listener in `MainActivity.kt`
4. Build and test

## Troubleshooting

### Connection Issues
- Verify device is on same network as media stack
- Check firewall settings on server
- Ensure all services are running

### Android TV Issues
- Enable "Apps from unknown sources" 
- Use adb to install if Google Play unavailable
- Ensure TV is in developer mode for debugging

### Build Issues
- Verify ANDROID_HOME is set correctly
- Check Android SDK tools are installed
- Use Android Studio for detailed error logs

## Support

For issues with:
- **Media Stack Setup**: Check main repository documentation
- **Android App**: Create issue with device/Android version details
- **Service Configuration**: Verify service URLs and ports

---

🚀 **Your complete media stack now available on any Android device!**
