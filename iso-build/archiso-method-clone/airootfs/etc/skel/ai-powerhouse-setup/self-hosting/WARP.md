# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview

This repository contains the Garuda Media Stack, a comprehensive media center solution designed for native Garuda Linux installations, with additional support for universal deployment using container technology.

The stack provides a complete grandmother-friendly media center that combines media services into a simple, beautiful interface - ideal for non-technical users who want access to movies, TV shows, music, books, and audiobooks.

## Core Components

The Garuda Media Stack consists of several key components:

1. **Media Servers**
   - Jellyfin (Open-source media server)
   - Plex (Premium media server)

2. **Content Management**
   - Radarr (Movie management)
   - Sonarr (TV show management)
   - Lidarr (Music management)
   - Readarr (Book management)

3. **Download & Search**
   - qBittorrent (Torrent client)
   - Jackett (Indexer proxy)

4. **Additional Services**
   - Audiobookshelf (Audiobook and podcast server)
   - Calibre-web (Ebook server)
   - Jellyseerr (Request system for Jellyfin)
   - Pulsarr (Plex watchlist monitoring)

5. **Privacy & Security**
   - Ghost Mode (Anonymity features)
   - WireGuard VPN integration

## Common Development Commands

### Installation Commands

To install the media stack on a native Garuda Linux system:

```bash
# Complete native installation with all services
sudo ./install-native-media-stack.sh

# Basic installation without Ghost Mode and WireGuard
sudo ./install-media-stack.sh

# Universal installation using containers (works on any Linux system)
./universal-media-stack.sh
```

### Service Management

```bash
# Start all services
./start-all-services.sh

# Stop all services
./stop-all-services.sh

# Check service health
./scripts/health-check-enhanced.sh

# Restart a specific service
sudo systemctl restart radarr

# View service logs
sudo journalctl -u sonarr -f
```

### WireGuard and Ghost Mode

```bash
# Setup WireGuard with Ghost Mode
./scripts/setup-wireguard-dual-role.sh

# Control Ghost Mode
./ghost-control.sh {enable|disable|toggle|status}

# Setup Ghost Mode
./ghost-mode-setup.sh

# WireGuard client manager
./scripts/wireguard-client-manager.sh
```

### Fix Common Issues

```bash
# Fix Jackett SSL issues
./fix-jackett-ssl.sh

# Fix Arr download connections
./fix-arr-download-connection.sh
```

## Code Architecture

The Garuda Media Stack follows a modular architecture:

1. **Main Installation Scripts**
   - `install-native-media-stack.sh` - Core script for native installation
   - `install-media-stack.sh` - Basic installation script
   - `universal-media-stack.sh` - Container-based universal installation

2. **Configuration Files**
   - Located in the `config/` directory
   - Include configuration for APIs, HDHomeRun, streaming services

3. **Service Scripts**
   - `scripts/` directory contains utility scripts
   - Handle WireGuard setup, health checks, etc.

4. **Dashboard**
   - `dashboard/` directory includes various UI interfaces
   - Admin dashboard, grandmother-friendly interface

5. **API Server**
   - `api-server.py` provides backend services for the dashboard
   - Handles service status, stream control

### Installation Process Pattern

The installation scripts follow a specific pattern:

1. Check if a service is already installed and configured correctly
2. If installed, skip to the next service
3. If not installed, proceed with installation
4. Create required directories
5. Download/install service
6. Configure systemd service (for native installation)
7. Set proper permissions
8. Verify service is running correctly

### Service Management Pattern

Service management uses both systemd (for native installations) and direct process management. Each service has:

1. Dedicated systemd service file
2. Health check capability
3. Logging configuration
4. Auto-restart policy

## Development Best Practices

1. **Always check if a program is installed and properly configured before installation**
   - Example: 
     ```bash
     if systemctl is-active --quiet radarr; then
         log "✅ Radarr is already running - skipping installation"
     else
         install_radarr
     fi
     ```

2. **Use proper logging for all operations**
   - The codebase uses consistent log, warn, error, and info functions

3. **Handle errors gracefully**
   - Check return codes
   - Provide clear error messages
   - Fall back to manual installation when automated methods fail

4. **Maintain proper service isolation**
   - Each service has its own configuration directory
   - Use correct user/group permissions

5. **Follow the installation patterns in the scripts**
   - Check → Skip if installed → Install → Configure → Verify

## Testing Workflow

1. Test installation on a fresh system
2. Verify all services are running with `scripts/health-check-enhanced.sh`
3. Test access to all web interfaces
4. Verify correct permissions on data directories
5. Test WireGuard and Ghost Mode if applicable

## Deployment Workflow

1. Clone the repository
2. Run the appropriate installation script
3. Configure each service through its web interface
4. Set up media libraries and indexers
5. Configure automatic start on boot for all services

## Troubleshooting Common Issues

1. **Service won't start**
   - Check logs: `sudo journalctl -u servicename`
   - Verify permissions: Check ownership of config directories
   - Check network: Ensure required ports are available

2. **Ghost Mode issues**
   - Check WireGuard status: `sudo wg show`
   - Verify VPN configuration: Check `/etc/wireguard/` files
   - Test connectivity: `ping 10.0.0.1`

3. **Web interface not accessible**
   - Check if service is running: `systemctl status servicename`
   - Verify port is not in use: `sudo ss -tulpn | grep port`
   - Check firewall: `sudo ufw status`
