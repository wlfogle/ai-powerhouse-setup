#!/bin/bash
# Uninstallation script for MobaLiveCD Linux

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get installation type
INSTALL_TYPE=${1:-user}
if [ "$INSTALL_TYPE" = "system" ]; then
    if [[ $EUID -ne 0 ]]; then
        print_error "System uninstallation requires root privileges"
        echo "Run: sudo ./uninstall.sh system"
        exit 1
    fi
    INSTALL_DIR="/usr/local/bin"
    DESKTOP_DIR="/usr/share/applications"
    MODULE_DIR="/usr/local/lib/mobalivecd"
else
    INSTALL_DIR="$HOME/.local/bin"
    DESKTOP_DIR="$HOME/.local/share/applications"
    MODULE_DIR="$HOME/.local/lib/mobalivecd"
fi

print_status "Uninstalling MobaLiveCD Linux ($INSTALL_TYPE installation)"

# Remove files
remove_files() {
    print_status "Removing application files..."
    
    # Remove main executable
    if [ -f "$INSTALL_DIR/mobalivecd" ]; then
        rm -f "$INSTALL_DIR/mobalivecd"
        print_status "Removed executable"
    fi
    
    # Remove desktop file
    if [ -f "$DESKTOP_DIR/mobalivecd.desktop" ]; then
        rm -f "$DESKTOP_DIR/mobalivecd.desktop"
        print_status "Removed desktop file"
    fi
    
    # Remove Python modules
    if [ -d "$MODULE_DIR" ]; then
        rm -rf "$MODULE_DIR"
        print_status "Removed Python modules"
    fi
    
    print_status "Application files removed"
}

# Update desktop database
update_desktop_db() {
    print_status "Updating desktop database..."
    
    if command -v update-desktop-database &> /dev/null; then
        if [ "$INSTALL_TYPE" = "system" ]; then
            update-desktop-database /usr/share/applications/
        else
            update-desktop-database "$HOME/.local/share/applications/"
        fi
    fi
    
    # Update MIME database
    if command -v update-mime-database &> /dev/null; then
        if [ "$INSTALL_TYPE" = "system" ]; then
            update-mime-database /usr/share/mime/
        else
            if [ -d "$HOME/.local/share/mime" ]; then
                update-mime-database "$HOME/.local/share/mime/"
            fi
        fi
    fi
    
    print_status "Desktop database updated"
}

# Main uninstallation
main() {
    echo "============================================"
    echo "      MobaLiveCD Linux Uninstaller"
    echo "============================================"
    echo
    
    remove_files
    update_desktop_db
    
    echo
    print_status "Uninstallation completed successfully!"
    print_status "MobaLiveCD has been removed from your system"
    echo
}

# Run main function
main
