#!/bin/bash
# System Preparation Script for ISO Cloning
# Cleans up the system to prepare for ISO creation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
TARGET_DIR="${TARGET_DIR:-/mnt}"

print_status "System Preparation for ISO Cloning"
print_status "==================================="
echo ""

# Validate target directory
if [[ ! -d "$TARGET_DIR" ]]; then
    print_error "Target directory not found: $TARGET_DIR"
    exit 1
fi

if [[ ! -f "$TARGET_DIR/etc/os-release" ]]; then
    print_error "Target directory doesn't appear to contain a Linux system: $TARGET_DIR"
    exit 1
fi

print_status "Preparing system at: $TARGET_DIR"
echo ""

print_warning "This script will clean up temporary files and caches in the target system."
print_warning "This is recommended before creating an ISO to reduce size and remove"
print_warning "system-specific data that shouldn't be in a live environment."
echo ""
read -p "Continue with system cleanup? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Operation cancelled"
    exit 1
fi

# Function to safely remove files/directories
safe_remove() {
    local path="$1"
    local description="$2"
    
    if [[ -e "$TARGET_DIR$path" ]]; then
        print_status "Cleaning: $description ($path)"
        sudo rm -rf "$TARGET_DIR$path" 2>/dev/null || print_warning "Could not remove: $path"
    fi
}

# Function to safely clean directories (remove contents but keep directory)
safe_clean() {
    local path="$1"
    local description="$2"
    
    if [[ -d "$TARGET_DIR$path" ]]; then
        print_status "Cleaning: $description ($path/*)"
        sudo find "$TARGET_DIR$path" -mindepth 1 -delete 2>/dev/null || print_warning "Could not clean: $path"
    fi
}

print_status "Starting system cleanup..."
echo ""

# Clean package manager caches
print_status "Cleaning package manager caches..."
safe_clean "/var/cache/pacman/pkg" "Pacman package cache"
safe_clean "/var/lib/pacman/sync" "Pacman sync databases"

# Clean temporary directories
print_status "Cleaning temporary directories..."
safe_clean "/tmp" "System temporary files"
safe_clean "/var/tmp" "Variable temporary files"
safe_remove "/var/log/journal" "System journal logs"
safe_clean "/var/log" "System logs"

# Clean user caches
print_status "Cleaning user caches..."
if [[ -d "$TARGET_DIR/home" ]]; then
    for user_dir in "$TARGET_DIR"/home/*; do
        if [[ -d "$user_dir" ]]; then
            user=$(basename "$user_dir")
            print_status "Cleaning cache for user: $user"
            safe_clean "/home/$user/.cache" "User cache for $user"
            safe_clean "/home/$user/.local/share/Trash" "Trash for $user"
            safe_remove "/home/$user/.bash_history" "Bash history for $user"
            safe_remove "/home/$user/.python_history" "Python history for $user"
            safe_remove "/home/$user/.lesshst" "Less history for $user"
        fi
    done
fi

# Clean root cache
print_status "Cleaning root cache..."
safe_clean "/root/.cache" "Root user cache"
safe_remove "/root/.bash_history" "Root bash history"
safe_remove "/root/.python_history" "Root python history"
safe_remove "/root/.lesshst" "Root less history"

# Clean network configurations that shouldn't be in live environment
print_status "Cleaning network configurations..."
safe_remove "/etc/NetworkManager/system-connections" "NetworkManager connections"

# Clean system-specific files
print_status "Cleaning system-specific files..."
safe_remove "/etc/machine-id" "Machine ID"
safe_remove "/var/lib/dbus/machine-id" "D-Bus machine ID"
safe_remove "/etc/ssh/ssh_host_*" "SSH host keys"

# Clean swap files
print_status "Cleaning swap files..."
safe_remove "/swapfile" "System swap file"

# Clean thumbnail caches
print_status "Cleaning thumbnail caches..."
if [[ -d "$TARGET_DIR/home" ]]; then
    for user_dir in "$TARGET_DIR"/home/*; do
        if [[ -d "$user_dir" ]]; then
            user=$(basename "$user_dir")
            safe_clean "/home/$user/.thumbnails" "Thumbnails for $user"
            safe_clean "/home/$user/.cache/thumbnails" "Thumbnail cache for $user"
        fi
    done
fi

# Clean browser caches and data
print_status "Cleaning browser data..."
if [[ -d "$TARGET_DIR/home" ]]; then
    for user_dir in "$TARGET_DIR"/home/*; do
        if [[ -d "$user_dir" ]]; then
            user=$(basename "$user_dir")
            safe_clean "/home/$user/.mozilla/firefox/*/Cache*" "Firefox cache for $user"
            safe_clean "/home/$user/.cache/mozilla" "Mozilla cache for $user"
            safe_clean "/home/$user/.config/google-chrome/Default/Cache*" "Chrome cache for $user"
        fi
    done
fi

# Clean recent files and activities
print_status "Cleaning recent files and activities..."
if [[ -d "$TARGET_DIR/home" ]]; then
    for user_dir in "$TARGET_DIR"/home/*; do
        if [[ -d "$user_dir" ]]; then
            user=$(basename "$user_dir")
            safe_remove "/home/$user/.local/share/recently-used.xbel" "Recent files for $user"
            safe_clean "/home/$user/.local/share/RecentDocuments" "Recent documents for $user"
        fi
    done
fi

# Clean systemd journal
print_status "Cleaning systemd journal..."
if [[ -d "$TARGET_DIR/var/log/journal" ]]; then
    sudo chroot "$TARGET_DIR" journalctl --vacuum-time=1d 2>/dev/null || true
fi

# Update locate database
print_status "Updating locate database..."
if [[ -f "$TARGET_DIR/usr/bin/updatedb" ]]; then
    sudo chroot "$TARGET_DIR" updatedb 2>/dev/null || print_warning "Could not update locate database"
fi

print_success "System cleanup completed!"
echo ""

# Show cleanup summary
print_status "Cleanup Summary:"
CLEANED_SIZE=$(du -sh "$TARGET_DIR" 2>/dev/null | cut -f1 || echo "Unknown")
echo "  Current system size: $CLEANED_SIZE"
echo "  Temporary files: Cleaned"
echo "  Package caches: Cleaned"
echo "  User caches: Cleaned"
echo "  System logs: Cleaned"
echo "  Network configs: Cleaned"
echo "  System-specific IDs: Removed"
echo ""

print_status "System is now prepared for ISO creation!"
print_status "You can now run the build-ai-powerhouse-iso-from-system.sh script"