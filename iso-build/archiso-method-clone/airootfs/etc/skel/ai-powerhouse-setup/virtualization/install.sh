#!/bin/bash
# Installation script for MobaLiveCD Linux

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for user installation"
   echo "Run without sudo for user installation, or use system installation option"
   exit 1
fi

# Get installation directory
INSTALL_TYPE=${1:-user}
if [ "$INSTALL_TYPE" = "system" ]; then
    if [[ $EUID -ne 0 ]]; then
        print_error "System installation requires root privileges"
        echo "Run: sudo ./install.sh system"
        exit 1
    fi
    INSTALL_DIR="/usr/local/bin"
    DESKTOP_DIR="/usr/share/applications"
    ICON_DIR="/usr/share/pixmaps"
else
    INSTALL_DIR="$HOME/.local/bin"
    DESKTOP_DIR="$HOME/.local/share/applications"
    ICON_DIR="$HOME/.local/share/icons"
fi

print_status "Installing MobaLiveCD Linux ($INSTALL_TYPE installation)"

# Check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed"
        exit 1
    fi
    
    # Check QEMU
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        print_warning "QEMU is not installed"
        echo "Install with: sudo dnf install qemu-system-x86  # Fedora/RHEL"
        echo "           or: sudo apt install qemu-system-x86  # Ubuntu/Debian"
    fi
    
    # Check PyGObject
    if ! python3 -c "import gi; gi.require_version('Gtk', '4.0'); from gi.repository import Gtk" 2>/dev/null; then
        print_warning "PyGObject/GTK4 not available"
        echo "Install with: sudo dnf install python3-gobject gtk4  # Fedora/RHEL"
        echo "           or: sudo apt install python3-gi gir1.2-gtk-4.0  # Ubuntu/Debian"
    fi
    
    print_status "Dependency check completed"
}

# Install application
install_app() {
    print_status "Installing application files..."
    
    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DESKTOP_DIR"
    mkdir -p "$ICON_DIR"
    
    # Install main script
    cp mobalivecd.py "$INSTALL_DIR/mobalivecd"
    chmod +x "$INSTALL_DIR/mobalivecd"
    
    # Install Python modules
    if [ "$INSTALL_TYPE" = "system" ]; then
        MODULE_DIR="/usr/local/lib/mobalivecd"
    else
        MODULE_DIR="$HOME/.local/lib/mobalivecd"
    fi
    
    mkdir -p "$MODULE_DIR"
    cp -r ui core i18n "$MODULE_DIR/"
    
    # Update the main script to use the correct module path
    sed -i "1a import sys; sys.path.insert(0, '$MODULE_DIR')" "$INSTALL_DIR/mobalivecd"
    
    # Install desktop file
    desktop_file="$DESKTOP_DIR/mobalivecd.desktop"
    cp mobalivecd.desktop "$desktop_file"
    
    # Update Exec path in desktop file
    sed -i "s|Exec=mobalivecd|Exec=$INSTALL_DIR/mobalivecd|g" "$desktop_file"
    
    # Make desktop file executable
    chmod +x "$desktop_file"
    
    print_status "Application files installed"
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

# Main installation
main() {
    echo "============================================"
    echo "       MobaLiveCD Linux Installer"
    echo "============================================"
    echo
    
    check_dependencies
    install_app
    update_desktop_db
    
    echo
    print_status "Installation completed successfully!"
    print_status "You can now:"
    echo "  - Run 'mobalivecd' from the command line"
    echo "  - Find 'MobaLiveCD' in your applications menu"
    echo "  - Right-click on ISO files to open with MobaLiveCD"
    echo
    
    if [ "$INSTALL_TYPE" = "user" ]; then
        print_warning "Make sure $INSTALL_DIR is in your PATH"
        if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
            echo "Add this line to your ~/.bashrc or ~/.profile:"
            echo "export PATH=\"\$PATH:$INSTALL_DIR\""
        fi
    fi
}

# Run main function
main
