# 🏠 Garuda Media Stack - Native Installation

A complete, grandmother-friendly media center solution designed for **native Garuda Linux installations**. This stack provides all your media services without Docker complexity - everything runs directly on your system with systemd services.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Garuda Linux](https://img.shields.io/badge/Garuda-Linux-blue.svg)](https://garudalinux.org/)
[![Native Install](https://img.shields.io/badge/Native-Installation-green.svg)](https://wiki.archlinux.org/title/systemd)

## 🎯 Overview

This is a complete, grandmother-friendly media center solution that combines all your media services into one simple, beautiful interface. Perfect for non-technical users who want access to movies, TV shows, music, books, and audiobooks - all with large, easy-to-use interfaces.

**🎉 Adapted from the [awesome-stack](https://github.com/wlfogle/awesome-stack) for native Garuda Linux installations!**

## ✨ Features

### 🎬 Complete Media Management
- **Movie Management**: Radarr for automatic movie downloads and organization
- **TV Show Management**: Sonarr for series tracking and downloads
- **Music Management**: Lidarr for music collection automation
- **Book Management**: Readarr for ebook downloads and organization
- **Audiobook Server**: Audiobookshelf for audiobook and podcast management
- **Ebook Server**: Calibre-web for beautiful ebook reading experience

### 🎥 Dual Media Servers
- **Jellyfin**: Open-source media server (already installed)
- **Plex**: Premium media server (already installed) 
- **Unified Experience**: Both servers working together

### 🔍 Advanced Search & Automation
- **Pulsarr**: Real-time Plex watchlist monitoring and automation
- **Jellyseerr**: Beautiful request system for Jellyfin users
- **Jackett**: Torrent indexer proxy for finding content
- **qBittorrent**: Advanced torrent client with web interface

### 🏠 Grandmother-Friendly Interface
- **Large Button Interface**: Easy navigation for elderly users
- **Unified Dashboard**: Single interface for all services
- **Auto-refresh**: Always up-to-date information
- **Mobile Responsive**: Works on tablets, phones, and computers

## 🚀 Quick Start

### 1. Prerequisites
- Garuda Linux system (running natively)
- At least 8GB RAM and 100GB storage
- Internet connection

### 2. One-Click Installation
```bash
# Clone the repository
git clone https://github.com/USERNAME/garuda-media-stack.git
cd garuda-media-stack

# Run the complete installation
sudo ./install-media-stack.sh

# Start all services
./start-all-services.sh
```

### 3. Access Your Services
- **Main Dashboard**: http://localhost:8600 (Coming soon)
- **Jellyfin**: http://localhost:8096
- **Plex**: http://localhost:32400/web
- **Radarr**: http://localhost:7878
- **Sonarr**: http://localhost:8989

## 📊 Service Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Garuda Linux Native Stack                 │
├─────────────────────────────────────────────────────────────┤
│                     Media Servers                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐   │
│  │  Jellyfin   │ │    Plex     │ │   Grandma Dashboard │   │
│  │   :8096     │ │   :32400    │ │      :8600          │   │
│  └─────────────┘ └─────────────┘ └─────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                   Content Management                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐   │
│  │   Radarr    │ │   Sonarr    │ │      Lidarr         │   │
│  │   :7878     │ │   :8989     │ │      :8686          │   │
│  └─────────────┘ └─────────────┘ └─────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                  Download & Indexing                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐   │
│  │ qBittorrent │ │   Jackett   │ │     Pulsarr         │   │
│  │   :5080     │ │   :9117     │ │     :3030           │   │
│  └─────────────┘ └─────────────┘ └─────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                     Systemd Services                       │
│        All services managed by systemd for reliability     │
└─────────────────────────────────────────────────────────────┘
```

## 🛠️ Installation Details

### What Gets Installed

#### Native System Services
- **qBittorrent**: Native package via pacman
- **Radarr**: Native package from chaotic-aur
- **Sonarr**: Native package from chaotic-aur  
- **Jackett**: Native package from chaotic-aur
- **Calibre**: Native package for ebook management

#### Manual Binary Installations
- **Lidarr**: Latest binary with systemd service
- **Readarr**: Latest binary with systemd service
- **Audiobookshelf**: Latest binary with systemd service
- **Pulsarr**: Latest binary with systemd service
- **Jellyseerr**: Latest binary with systemd service
- **Calibre-web**: Python package with systemd service

### Service Management
All services are properly configured with:
- ✅ Systemd service files
- ✅ Auto-start on boot
- ✅ Proper user permissions
- ✅ Log rotation
- ✅ Health monitoring
- ✅ Restart policies

## 📁 Directory Structure

```
/home/lou/garuda-media-stack/
├── install-media-stack.sh          # Main installation script
├── start-all-services.sh           # Service startup script
├── stop-all-services.sh            # Service shutdown script
├── config/                         # Configuration files
│   ├── radarr.service              # Systemd service files
│   ├── sonarr.service              
│   ├── lidarr.service              
│   └── ...                        
├── scripts/                        # Utility scripts
│   ├── install-lidarr.sh           # Individual installation scripts
│   ├── install-readarr.sh          
│   ├── install-pulsarr.sh          
│   └── ...                        
├── services/                       # Service management
│   ├── health-check.sh             # Health monitoring
│   ├── update-all.sh               # Update services
│   └── backup-configs.sh           # Backup configurations
└── docs/                           # Documentation
    ├── GRANDMOTHER_GUIDE.md        # Simple user guide
    ├── CONFIGURATION.md            # Advanced setup
    └── TROUBLESHOOTING.md          # Problem solutions
```

## 🎮 Service URLs & Ports

| Service | URL | Purpose | Status |
|---------|-----|---------|--------|
| **Jellyfin** | http://localhost:8096 | Media server | ✅ Pre-installed |
| **Plex** | http://localhost:32400/web | Media server | ✅ Pre-installed |
| **Radarr** | http://localhost:7878 | Movie management | ✅ Installed |
| **Sonarr** | http://localhost:8989 | TV management | ✅ Installed |
| **Jackett** | http://localhost:9117 | Indexer proxy | ✅ Installed |
| **qBittorrent** | http://localhost:5080 | Downloads | ✅ Installed |
| **Lidarr** | http://localhost:8686 | Music management | 🔄 Via script |
| **Readarr** | http://localhost:8787 | Book management | 🔄 Via script |
| **Calibre-web** | http://localhost:8083 | Ebook server | 🔄 Via script |
| **Audiobookshelf** | http://localhost:13378 | Audiobook server | 🔄 Via script |
| **Pulsarr** | http://localhost:3030 | Plex automation | 🔄 Via script |
| **Jellyseerr** | http://localhost:5055 | Jellyfin requests | 🔄 Via script |

## 🔧 Configuration

### Environment Variables
```bash
# Media storage paths
export MEDIA_ROOT="/media"
export DOWNLOADS_PATH="/media/downloads"
export MOVIES_PATH="/media/movies"
export TV_PATH="/media/tv"
export MUSIC_PATH="/media/music"
export BOOKS_PATH="/media/books"
export AUDIOBOOKS_PATH="/media/audiobooks"

# Service configuration
export PLEX_CLAIM_TOKEN="claim-xxxxxxxxxxxx"
export JELLYFIN_API_KEY="your-jellyfin-api-key"
```

### Directory Setup
```bash
# Create media directories
sudo mkdir -p /media/{movies,tv,music,books,audiobooks,podcasts,downloads}
sudo chown -R lou:lou /media
```

## 🎊 Success Metrics

When properly configured, you should have:
- ✅ **Native Performance**: No Docker overhead, direct system performance
- ✅ **Systemd Integration**: Proper service management and auto-restart
- ✅ **Unified Media**: Both Plex and Jellyfin working together
- ✅ **Complete Automation**: Movies, TV, music, books all automated
- ✅ **Simple Interface**: Grandmother-friendly large buttons
- ✅ **Professional Setup**: Enterprise-grade reliability

## 🆘 Support & Troubleshooting

### Service Management
```bash
# Check all service status
./scripts/health-check.sh

# Restart a specific service
sudo systemctl restart radarr

# View service logs
sudo journalctl -u sonarr -f

# Update all services
./scripts/update-all.sh
```

### Common Issues
1. **Service won't start**: Check logs with `sudo journalctl -u servicename`
2. **Permission issues**: Run `./scripts/fix-permissions.sh`
3. **Missing dependencies**: Run `./scripts/install-dependencies.sh`

## 🔮 Roadmap

### Phase 1: Core Installation ✅
- Native *arr stack installation
- Systemd service configuration
- Basic automation scripts

### Phase 2: Enhanced Features 🔄
- Grandmother Dashboard web interface
- Service health monitoring
- Automatic updates and backups

### Phase 3: Advanced Features 🚀
- AI-powered search and recommendations
- Voice control integration
- Mobile app development
- Advanced automation

---

## 🎉 Congratulations!

You now have a complete, production-ready media center that's specifically designed for **native Garuda Linux installations**. This system provides professional-grade media management without the complexity of containerization.

**Perfect for users who want maximum performance and simplicity!**

[![GitHub stars](https://img.shields.io/github/stars/USERNAME/garuda-media-stack.svg?style=social&label=Star)](https://github.com/USERNAME/garuda-media-stack)
