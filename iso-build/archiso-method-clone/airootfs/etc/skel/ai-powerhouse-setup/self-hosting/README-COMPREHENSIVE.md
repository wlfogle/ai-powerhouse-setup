# 🏠 Garuda Comprehensive Media Stack - Ultimate Edition

A complete, grandmother-friendly media center solution designed for **native Garuda Linux installations** with **Ghost Mode anonymity** and **WireGuard VPN integration**. This stack provides all your media services without Docker complexity - everything runs directly on your system with systemd services.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Garuda Linux](https://img.shields.io/badge/Garuda-Linux-blue.svg)](https://garudalinux.org/)
[![Native Install](https://img.shields.io/badge/Native-Installation-green.svg)](https://wiki.archlinux.org/title/systemd)
[![Ghost Mode](https://img.shields.io/badge/Ghost-Mode-red.svg)](https://github.com/wlfogle/awesome-stack)

## 🎯 Overview

This is the **ultimate media center solution** that combines:
- **Complete Media Management** (Movies, TV, Music, Books, Audiobooks)
- **Dual Media Servers** (Jellyfin + Plex)
- **Advanced Search & Automation** (AI-powered with Pulsarr integration)
- **Ghost Mode Anonymity** (Complete online invisibility)
- **WireGuard VPN** (6-hour key rotation, device-specific configs)
- **Grandmother-Friendly Interface** (Large buttons, simple navigation)

**🎉 Based on [awesome-stack](https://github.com/wlfogle/awesome-stack) patterns with native Garuda Linux optimizations!**

## ✨ Ultimate Features

### 🎬 Complete Media Management Suite
- **Movie Management**: Radarr with enhanced automation and quality upgrading
- **TV Show Management**: Sonarr with series tracking and advanced processing
- **Music Management**: Lidarr with lossless audio support and metadata enhancement
- **Book Management**: Readarr with automated ebook downloads and organization
- **Audiobook Server**: Audiobookshelf with podcast support and streaming
- **Ebook Server**: Calibre-web with beautiful reading interface and format conversion

### 🎥 Dual Media Server Architecture
- **Jellyfin**: Open-source media server with native transcoding
- **Plex**: Premium media server with Lifetime Pass features
- **Unified Dashboard**: Single interface accessing both servers seamlessly
- **Smart Routing**: Automatic failover between servers
- **Transcoding Optimization**: Hardware acceleration for both servers

### 🔍 Advanced Search & AI Automation
- **Pulsarr**: Real-time Plex watchlist monitoring with instant automation
- **Jellyseerr**: Beautiful request management system for Jellyfin users
- **AI-Powered Search**: Natural language content discovery (OpenAI integration)
- **Smart Content Discovery**: Trending monitoring and automated recommendations
- **Jackett**: Advanced torrent indexer proxy with multiple site support
- **qBittorrent**: Professional torrent client with web interface

### 🥷 Ghost Mode Anonymity Suite (from awesome-stack)
- **Complete Online Invisibility**: One-click digital anonymity
- **Network Level Protection**: VPN with IPv6 disabled, DNS-over-TLS
- **Browser Fingerprinting Protection**: Canvas, WebGL, audio fingerprint blocking
- **Hardware Spoofing**: CPU, RAM, GPU identification masked
- **Time Masking**: Timezone randomization and timing attack prevention
- **API Request Masking**: Proxy service to prevent AI service tracking
- **System Tray Widget**: Visual status with one-click controls

### 🛡️ Advanced WireGuard VPN Integration
- **Dual-Role Configuration**: Server and client capabilities
- **Automatic Key Rotation**: 6-hour rotation for enhanced security
- **Device-Specific Configs**: Individual VPN IPs and configurations
- **QR Code Generation**: Mobile device setup automation
- **Ghost Mode Integration**: Complete anonymity when connected
- **DNS-over-TLS**: Secure DNS resolution through VPN

### 🏠 Grandmother-Friendly Interface
- **Large Button Dashboard**: Easy navigation for elderly users
- **Unified Service Access**: Single interface for all media services
- **Auto-refresh**: Real-time status updates and health monitoring
- **Weather Integration**: Local weather display with forecasts
- **Mobile Responsive**: Perfect on tablets, phones, and computers
- **Voice Control Ready**: Prepared for future voice integration

## 🚀 Quick Start Installation

### 1. Prerequisites
- **Garuda Linux** system (running natively, not in container)
- **Minimum 8GB RAM** and 100GB storage space
- **Internet connection** for packages and media data
- **sudo privileges** for system-level installation

### 2. One-Click Complete Installation
```bash
# Clone the repository
git clone https://github.com/USERNAME/garuda-media-stack.git
cd garuda-media-stack

# Run the comprehensive installation (includes Ghost Mode + WireGuard)
sudo ./install-native-media-stack.sh

# Start all services
media-stack start

# Activate Ghost Mode (optional but recommended)
ghost-mode start
```

### 3. Access Your Complete Media Center
- **🏠 Main Dashboard**: http://localhost:8600 (Grandmother interface)
- **🎬 Jellyfin**: http://localhost:8096 (Open-source media server)
- **📺 Plex**: http://localhost:32400/web (Premium media server)
- **🔍 Search & Requests**: http://localhost:5055 (Jellyseerr)
- **⬇️ Downloads**: http://localhost:5080 (qBittorrent)
- **📚 Books**: http://localhost:8083 (Calibre-web)
- **🎧 Audiobooks**: http://localhost:13378 (Audiobookshelf)

## 📊 Complete Service Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│              🏠 Garuda Native Media Stack Ultimate Edition          │
├─────────────────────────────────────────────────────────────────────┤
│                          🥷 Ghost Mode Layer                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │ Anonymity   │ │ VPN Server  │ │ API Masking │ │System Tray  │   │
│  │ Controller  │ │ WireGuard   │ │   Proxy     │ │   Widget    │   │
│  │   :ghost    │ │   :51820    │ │   :8080     │ │  (PyQt5)    │   │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │
├─────────────────────────────────────────────────────────────────────┤
│                        🏠 Grandmother Dashboard                     │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │  Main UI    │ │ Weather     │ │ Service     │ │ API Server  │   │
│  │   :8600     │ │ Widget      │ │ Status      │ │   :8601     │   │
│  │ (Nginx)     │ │ (OpenAPI)   │ │ Monitor     │ │ (Python)    │   │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │
├─────────────────────────────────────────────────────────────────────┤
│                       🎥 Media Server Layer                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │  Jellyfin   │ │    Plex     │ │ Jellyseerr  │ │  Pulsarr    │   │
│  │   :8096     │ │   :32400    │ │   :5055     │ │   :3030     │   │
│  │ (Native)    │ │ (Native)    │ │ (Native)    │ │ (Native)    │   │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │
├─────────────────────────────────────────────────────────────────────┤
│                     📋 Content Management Layer                    │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │   Radarr    │ │   Sonarr    │ │   Lidarr    │ │  Readarr    │   │
│  │   :7878     │ │   :8989     │ │   :8686     │ │   :8787     │   │
│  │ (Movies)    │ │ (TV Shows)  │ │  (Music)    │ │  (Books)    │   │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │
├─────────────────────────────────────────────────────────────────────┤
│                    ⬇️ Download & Library Layer                     │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │qBittorrent  │ │   Jackett   │ │ Calibre-web │ │Audiobookshelf│  │
│  │   :5080     │ │   :9117     │ │   :8083     │ │   :13378    │   │
│  │(Downloads)  │ │ (Indexers)  │ │  (eBooks)   │ │(Audiobooks) │   │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │
├─────────────────────────────────────────────────────────────────────┤
│                        🔧 System Services Layer                    │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │  Systemd    │ │  Firewall   │ │ Health      │ │ Backup      │   │
│  │ Management  │ │   (UFW)     │ │ Monitor     │ │ System      │   │
│  │(All Services)│ │ (Security)  │ │ (Auto)      │ │ (Cron)      │   │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## 🛠️ Complete Installation Details

### What Gets Installed

#### 🎯 Core Native Packages (via pacman)
- **qBittorrent-nox**: Headless torrent client with web interface
- **Calibre**: Complete ebook management suite
- **WireGuard-tools**: VPN client and server utilities
- **Nginx**: Reverse proxy for unified dashboard
- **Python ecosystem**: For API services and automation
- **UFW**: Uncomplicated Firewall for security

#### 🔧 Enhanced *arr Services (Manual Installation)
- **Radarr**: Latest binary with native systemd integration
- **Sonarr**: Latest binary with TV series management
- **Lidarr**: Latest binary with music collection automation  
- **Readarr**: Latest binary with ebook management
- **Jackett**: Indexer proxy from AUR or manual installation

#### 🚀 Advanced Services (Built from Source)
- **Pulsarr**: Real-time Plex watchlist automation (from GitHub)
- **Jellyseerr**: Beautiful Jellyfin request management (from GitHub)
- **Audiobookshelf**: Audiobook and podcast server (NPM global)
- **Calibre-web**: Web interface for ebook reading (Python pip)

#### 🥷 Ghost Mode Components (from awesome-stack)
- **Ghost-mode suite**: Complete anonymity control system
- **API masking proxy**: Prevents AI service tracking
- **Hardware spoofing**: CPU, RAM, GPU identification masking
- **Browser protection**: Fingerprint blocking and hardening
- **System tray widget**: PyQt5 visual control interface

#### 🛡️ WireGuard VPN System
- **Server configuration**: Multi-device VPN with key rotation
- **Client management**: Device-specific configurations and QR codes
- **DNS-over-TLS**: Secure DNS resolution through unbound
- **Automatic rotation**: 6-hour key rotation for enhanced security

### 📁 Complete Directory Structure

```
/home/lou/garuda-media-stack/
├── install-native-media-stack.sh      # Master installation script
├── README-COMPREHENSIVE.md             # This comprehensive guide
├── README.md                          # Basic getting started guide
│
├── 📂 scripts/                        # Installation and management
│   ├── setup-wireguard-ghost-mode.sh  # VPN + anonymity setup
│   ├── setup-wireguard-dual-role.sh   # Advanced VPN configuration
│   ├── health-check-enhanced.sh       # System monitoring
│   └── wireguard-client-manager.sh    # Device management
│
├── 📂 dashboard/                       # Grandmother interface
│   ├── grandma-dashboard.html         # Main dashboard HTML
│   ├── api-server.py                  # Backend API service
│   └── assets/                        # CSS, JS, images
│
├── 📂 config/                         # Service configurations
│   ├── systemd/                       # Service files
│   ├── nginx/                         # Reverse proxy configs
│   └── ghost-mode/                    # Anonymity configurations
│
├── 📂 docs/                           # Documentation
│   ├── GRANDMOTHER_GUIDE.md           # Simple user guide
│   ├── ADVANCED_CONFIGURATION.md     # Power user guide
│   ├── GHOST_MODE_GUIDE.md           # Anonymity manual
│   ├── WIREGUARD_SETUP.md            # VPN configuration
│   └── TROUBLESHOOTING.md            # Problem solutions
│
└── 📂 tools/                          # Management utilities
    ├── media-stack                    # Main control script
    ├── backup-system.sh              # Configuration backup
    └── update-all-services.sh        # Bulk updates
```

## 🎮 Complete Service Reference

### 🏠 Main Dashboard & Control
| Service | URL | Purpose | Status |
|---------|-----|---------|--------|
| **🏠 Grandma Dashboard** | http://localhost:8600 | Main unified interface | ✅ Custom |
| **⚙️ API Server** | http://localhost:8601 | Backend API for dashboard | ✅ Python |
| **🛡️ Ghost Mode Widget** | System Tray | One-click anonymity control | ✅ PyQt5 |

### 🎥 Media Servers & Discovery
| Service | URL | Purpose | Status |
|---------|-----|---------|--------|
| **🎬 Jellyfin** | http://localhost:8096 | Open-source media server | ✅ Pre-installed |
| **📺 Plex** | http://localhost:32400/web | Premium media server | ✅ Pre-installed |
| **🔍 Jellyseerr** | http://localhost:5055 | Content request management | ✅ From source |
| **⚡ Pulsarr** | http://localhost:3030 | Plex watchlist automation | ✅ From GitHub |

### 📋 Content Management (*arr Services)
| Service | URL | Purpose | Status |
|---------|-----|---------|--------|
| **🎬 Radarr** | http://localhost:7878 | Movie collection manager | ✅ Manual install |
| **📺 Sonarr** | http://localhost:8989 | TV series manager | ✅ Manual install |
| **🎵 Lidarr** | http://localhost:8686 | Music collection manager | ✅ Manual install |
| **📚 Readarr** | http://localhost:8787 | Ebook collection manager | ✅ Manual install |

### ⬇️ Download & Library Services
| Service | URL | Purpose | Status |
|---------|-----|---------|--------|
| **⬇️ qBittorrent** | http://localhost:5080 | Torrent download client | ✅ Native package |
| **🔍 Jackett** | http://localhost:9117 | Torrent indexer proxy | ✅ AUR/Manual |
| **📖 Calibre-web** | http://localhost:8083 | Ebook reading interface | ✅ Python pip |
| **🎧 Audiobookshelf** | http://localhost:13378 | Audiobook & podcast server | ✅ NPM global |

### 🥷 Ghost Mode & Security
| Service | URL | Purpose | Status |
|---------|-----|---------|--------|
| **🥷 Ghost Mode** | Command Line | Complete online anonymity | ✅ awesome-stack |
| **🛡️ WireGuard Server** | UDP :51820 | VPN server with key rotation | ✅ Native + custom |
| **🎭 API Masking Proxy** | http://localhost:8080 | AI service request masking | ✅ Python custom |
| **🕰️ System Tray Widget** | Desktop Tray | Visual anonymity control | ✅ PyQt5 |

## 🔧 Advanced Configuration

### 🌤️ Weather Integration
```bash
# Get free API key from OpenWeatherMap
export WEATHER_API_KEY="your_openweathermap_api_key"
export WEATHER_LOCATION="New Albany, IN"
```

### 🤖 AI Search Enhancement  
```bash
# Optional: Add OpenAI for enhanced search
export OPENAI_API_KEY="your_openai_api_key"
```

### 🛡️ Ghost Mode Configuration
```bash
# Activate complete invisibility
ghost-mode start

# System tray widget status:
# 🟢 Green = Completely invisible online
# 🟡 Yellow = Partially protected  
# 🔴 Red = Visible online (not protected)
```

### 🔌 WireGuard Device Management
```bash
# List all configured devices
wg-device-manager list

# Show QR code for mobile setup
wg-device-manager qr phone-android3

# Rotate keys for enhanced security
wg-device-manager rotate garuda-host

# Check server status
wg-device-manager status
```

## 🚀 Management Commands

### 🎬 Media Stack Control
```bash
# Master control for all services
media-stack start          # Start all services
media-stack stop           # Stop all services  
media-stack restart        # Restart all services
media-stack status         # Show complete status
media-stack logs sonarr    # Show service logs
```

### 🥷 Ghost Mode Control
```bash
# Anonymity management
ghost-mode start           # Activate complete invisibility
ghost-mode stop            # Deactivate (return to normal)
ghost-mode status          # Check protection status
ghost-mode test            # Run anonymity tests

# Simple toggle
ghost-toggle               # One-click on/off
ghost-browser              # Launch anonymous browser
```

### 🛡️ WireGuard VPN Management
```bash
# VPN server control
sudo systemctl start wg-quick@wg0     # Start VPN server
sudo systemctl stop wg-quick@wg0      # Stop VPN server
sudo wg show                          # Show connected peers

# Device management
wg-device-manager list                # List all devices
wg-device-manager show phone-android3 # Show device config
wg-device-manager qr tablet-jackie    # Display QR code
```

### 📊 System Health & Monitoring
```bash
# Health monitoring
./scripts/health-check-enhanced.sh    # Complete system health
systemctl --failed                    # Show failed services
journalctl -f                        # Real-time system logs

# Service-specific monitoring
sudo journalctl -u radarr -f         # Radarr logs
sudo journalctl -u ghost-mode -f     # Ghost Mode logs
sudo journalctl -u wg-quick@wg0 -f   # WireGuard logs
```

## 🎊 Success Metrics & Verification

When properly installed and configured, you should have:

### 📊 Media Management Success
- ✅ **Unified Dashboard**: Single interface accessing all services
- ✅ **Dual Media Servers**: Jellyfin and Plex both operational
- ✅ **Complete Automation**: Movies, TV, music, books all automated
- ✅ **Smart Discovery**: AI-powered search and recommendations
- ✅ **Professional Downloads**: qBittorrent with advanced management

### 🥷 Anonymity & Security Success
- ✅ **Complete Invisibility**: Ghost Mode providing full anonymity
- ✅ **VPN Protection**: WireGuard with automatic key rotation
- ✅ **API Masking**: AI service requests completely masked
- ✅ **Browser Protection**: All fingerprinting blocked
- ✅ **DNS Security**: DNS-over-TLS through VPN

### 🏠 User Experience Success
- ✅ **Grandmother-Friendly**: Large buttons and simple navigation
- ✅ **Mobile Responsive**: Perfect on all device sizes
- ✅ **Auto-Refresh**: Real-time updates without manual refresh
- ✅ **Weather Integration**: Local weather always displayed
- ✅ **One-Click Control**: All services managed easily

### 🔧 Technical Implementation Success
- ✅ **Native Performance**: No Docker overhead, direct system performance
- ✅ **Systemd Integration**: All services managed by systemd
- ✅ **Security Hardened**: Firewall configured, services secured
- ✅ **Auto-Start**: All services start automatically on boot
- ✅ **Professional Monitoring**: Health checks and auto-recovery

## 🆘 Comprehensive Troubleshooting

### 🚨 Common Issues & Solutions

#### Services Won't Start
```bash
# Check service status
media-stack status

# Check specific service
sudo systemctl status radarr
sudo journalctl -u radarr

# Restart failed services
sudo systemctl restart radarr
```

#### Ghost Mode Issues
```bash
# Check Ghost Mode status
ghost-mode status

# Check VPN connectivity
sudo wg show
ping 10.0.0.1

# Test anonymity
ghost-mode test
dns-leak-test
```

#### Dashboard Not Loading
```bash
# Check nginx and API server
sudo systemctl status nginx
sudo systemctl status media-api

# Check port conflicts
sudo ss -tulpn | grep :8600

# Restart web services
sudo systemctl restart nginx
sudo systemctl restart media-api
```

#### VPN Connection Problems
```bash
# Check WireGuard server
sudo systemctl status wg-quick@wg0
sudo wg show

# Check firewall
sudo ufw status
sudo iptables -L

# Regenerate client configs
wg-device-manager rotate garuda-host
```

### 📞 Advanced Support Resources

#### Log Locations
- **System logs**: `sudo journalctl -f`
- **Service logs**: `sudo journalctl -u [service-name]`
- **Ghost Mode logs**: `~/.config/ghost-mode/ghost-mode.log`
- **WireGuard logs**: `/var/log/wireguard-setup.log`
- **Media stack logs**: `/var/log/media-stack/`

#### Configuration Files
- **WireGuard configs**: `/etc/wireguard/`
- **Service configs**: `/etc/systemd/system/`
- **Nginx configs**: `/etc/nginx/sites-available/`
- **Ghost Mode configs**: `~/.config/ghost-mode/`

## 🔮 Roadmap & Future Enhancements

### 📅 Phase 1: Core Complete ✅
- ✅ Native *arr stack installation
- ✅ Ghost Mode integration  
- ✅ WireGuard dual-role setup
- ✅ Grandmother dashboard
- ✅ Complete systemd integration

### 📅 Phase 2: Enhanced Intelligence 🔄
- 🔄 Advanced AI recommendations
- 🔄 Voice control integration
- 🔄 Mobile app development
- 🔄 Smart home integration
- 🔄 Automated content curation

### 📅 Phase 3: Ultimate Automation 🚀
- 🚀 Machine learning quality prediction
- 🚀 Automated storage optimization
- 🚀 Dynamic VPN routing
- 🚀 Advanced threat detection
- 🚀 Predictive maintenance

## 🎉 Congratulations!

You now have the **ultimate media center** that combines:

### 🎯 **Professional Media Management**
- Complete automation for all content types
- Dual server redundancy with failover
- AI-powered search and discovery
- Professional-grade monitoring and health checks

### 🥷 **Complete Online Anonymity**  
- One-click invisibility with Ghost Mode
- Advanced VPN with automatic key rotation
- API request masking for AI services
- Hardware and browser fingerprint spoofing

### 🏠 **User-Friendly Experience**
- Beautiful dashboard perfect for all users
- Large buttons and clear navigation
- Real-time status monitoring
- Mobile-responsive design

### 🔧 **Enterprise-Grade Infrastructure**
- Native system performance (no containers)
- Systemd service management
- Security hardening with firewall
- Professional backup and monitoring

**Perfect for power users who want maximum capability with grandmother-friendly simplicity!**

---

## 📜 Credits & Acknowledgments

- **🥷 Ghost Mode**: Based on [awesome-stack](https://github.com/wlfogle/awesome-stack) by wlfogle
- **🛡️ WireGuard Integration**: Enhanced from awesome-stack patterns
- **🎬 Media Stack**: Optimized for native Garuda Linux installation
- **🏠 Dashboard**: Inspired by grandmother-friendly design principles

[![GitHub stars](https://img.shields.io/github/stars/USERNAME/garuda-media-stack.svg?style=social&label=Star)](https://github.com/USERNAME/garuda-media-stack)

**🔥 You now have the most advanced, anonymous, and user-friendly media center possible! 🔥**
