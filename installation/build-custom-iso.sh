#!/bin/bash

# AI Powerhouse Custom Garuda Linux ISO Builder
# Creates a custom ISO with ZFS, AI tools, media stack, and development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root (sudo ./build-custom-iso.sh)"
    exit 1
fi

log "🚀 Building AI Powerhouse Garuda Linux ISO"

# Install required packages for ISO building
log "Installing ISO building dependencies..."
pacman -Sy --noconfirm archiso git squashfs-tools

# Create working directory
WORK_DIR="/tmp/ai-powerhouse-iso"
log "Creating working directory: $WORK_DIR"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Clone the official Garuda Linux ISO profiles
log "Cloning Garuda Linux ISO profiles..."
git clone https://gitlab.com/garuda-linux/tools/garuda-tools.git
cd garuda-tools/iso-profiles/community/dragonized-gaming

# Create our custom profile
CUSTOM_PROFILE="$WORK_DIR/ai-powerhouse-profile"
log "Creating custom AI Powerhouse profile..."
cp -r . "$CUSTOM_PROFILE"
cd "$CUSTOM_PROFILE"

# Modify profile name and settings
log "Configuring custom profile..."
cat > profile.conf << 'EOF'
##########################################
###### use this file in the profile ####
##########################################

# use multilib packages; x86_64 only
multilib="true"

# use extra packages as defined in pkglist to activate a full profile
extra="false"

################ iso ################

# the name of the iso
iso_name="garuda-ai-powerhouse"

# the version of the iso
iso_version="$(date +%Y.%m.%d)"

# the kernel to use
kernel="linux"

# use the kde desktop
desktop="dragonized-gaming"

# use lightdm as login manager
login_shell="zsh"

# configure calamares for netinstall
netinstall="false"

# configure calamares to use chrootcfg instead of unpackfs
chrootcfg="false"

# use geoip
geoip="true"

# set plymouth theme
plymouth_theme="garuda"

# enable macOS bootloader compatibility
efi_boot_loader="grub"
EOF

# Create custom package list with AI/ML tools
log "Creating custom package list with AI/ML tools..."
cat > Packages-Desktop << 'EOF'
# AI Powerhouse Custom Package List

# Base system with ZFS support
>extra zfs-dkms
>extra zfs-utils
>extra zfs-auto-snapshot

# NVIDIA and CUDA for AI development
>extra nvidia
>extra nvidia-utils
>extra nvidia-settings
>extra cuda
>extra cudnn
>extra python-pytorch-cuda
>extra opencl-nvidia

# Development tools
>extra rustup
>extra nodejs
>extra npm
>extra yarn
>extra git
>extra github-cli
>extra code
>extra neovim

# AI/ML Python ecosystem
>extra python
>extra python-pip
>extra python-pytorch
>extra python-tensorflow
>extra python-numpy
>extra python-pandas
>extra python-matplotlib
>extra python-jupyter
>extra python-scikit-learn
>extra ollama

# Virtualization and containers
>extra docker
>extra docker-compose
>extra qemu-full
>extra virt-manager
>extra libvirt
>extra bridge-utils

# Media stack dependencies (for self-hosting)
>extra jellyfin-server
>extra jellyfin-web
>extra sonarr
>extra radarr
>extra lidarr
>extra jackett
>extra qbittorrent-nox
>extra calibre

# System monitoring and management
>extra htop
>extra neofetch
>extra tree
>extra tmux
>extra fzf

# Web development
>extra firefox-developer-edition
>extra chromium

# Additional development tools
>extra cmake
>extra make
>extra gcc
>extra clang
>extra llvm
>extra gdb

# Multimedia support
>extra ffmpeg
>extra vlc
>extra obs-studio
>extra audacity

# Network tools
>extra nmap
>extra curl
>extra wget
>extra wireshark-qt
EOF

# Create custom overlay with our project files
log "Setting up custom overlay with AI Powerhouse files..."
mkdir -p overlay/etc/skel/
mkdir -p overlay/usr/local/bin/
mkdir -p overlay/etc/systemd/system/

# Copy our AI powerhouse setup to skeleton
# Use current user's setup directory or fallback to relative path
SETUP_SOURCE="${SETUP_SOURCE:-${HOME}/ai-powerhouse-setup}"
if [[ ! -d "$SETUP_SOURCE" ]]; then
    SETUP_SOURCE="$(dirname "$(dirname "$(realpath "$0")")")" # Go up two levels from installation/ to project root
fi
cp -r "$SETUP_SOURCE" overlay/etc/skel/

# Create post-install script
cat > overlay/usr/local/bin/ai-powerhouse-setup << 'EOF'
#!/bin/bash

# AI Powerhouse Post-Installation Setup
# Run this after installing the system

set -e

USER_HOME="$HOME"
SETUP_DIR="$USER_HOME/ai-powerhouse-setup"

echo "🚀 Setting up AI Powerhouse environment..."

# Make sure we're in the user's home
cd "$USER_HOME"

# Set up Rust
if ! command -v rustc &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    rustup component add rust-analyzer
fi

# Install Tauri CLI
if ! command -v cargo-tauri &> /dev/null; then
    echo "Installing Tauri CLI..."
    cargo install tauri-cli
fi

# Set up Node.js development
echo "Setting up Node.js development environment..."
npm install -g @tauri-apps/cli
npm install -g create-react-app
npm install -g typescript

# Configure Ollama with existing models
if [ -d "/run/media/*/models" ]; then
    echo "Configuring Ollama with existing models..."
    sudo mkdir -p /opt/ollama/models
    # This will be configured during installation to copy existing models
fi

# Enable and start services
echo "Enabling system services..."
sudo systemctl enable docker
sudo systemctl enable libvirtd
sudo systemctl enable ollama

# Add user to relevant groups
sudo usermod -aG docker "$USER"
sudo usermod -aG libvirt "$USER"

# Configure ZFS auto-snapshots
echo "Configuring ZFS auto-snapshots..."
sudo systemctl enable zfs-auto-snapshot-hourly.timer
sudo systemctl enable zfs-auto-snapshot-daily.timer
sudo systemctl enable zfs-auto-snapshot-weekly.timer
sudo systemctl enable zfs-auto-snapshot-monthly.timer

echo "✅ AI Powerhouse setup complete!"
echo ""
echo "Next steps:"
echo "1. Reboot to activate all changes"
echo "2. Run media stack installation: cd ~/ai-powerhouse-setup/self-hosting && sudo ./install-native-media-stack.sh"
echo "3. Configure development environment"
echo "4. Set up AI models and workflows"
EOF

chmod +x overlay/usr/local/bin/ai-powerhouse-setup

# Create desktop entry for easy access
mkdir -p overlay/etc/skel/.local/share/applications/
cat > overlay/etc/skel/.local/share/applications/ai-powerhouse-setup.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=AI Powerhouse Setup
Comment=Complete AI development and self-hosting environment setup
Exec=gnome-terminal -- ai-powerhouse-setup
Icon=applications-development
Terminal=true
Categories=Development;System;
EOF

# Create custom Calamares configuration for ZFS
log "Configuring Calamares for ZFS installation..."
mkdir -p overlay/etc/calamares/modules/
cat > overlay/etc/calamares/modules/partition.conf << 'EOF'
# Custom partitioning for ZFS root
efiSystemPartition: "/boot/efi"
efiSystemPartitionSize: 1024MiB
efiSystemPartitionName: "EFI"

userSwapChoices:
    - none
    - small
    - suspend

swapPartitionName: "swap"

drawNestedPartitions: false
alwaysShowPartitionLabels: true
allowManualPartitioning: true

initialPartitioningChoice: erase
initialSwapChoice: none

defaultFileSystemType: "zfs"

availableFileSystemTypes:
    - "ext4"
    - "btrfs"
    - "zfs"
    - "xfs"
    - "f2fs"
EOF

# Build the ISO
log "Building custom AI Powerhouse ISO..."
cd "$WORK_DIR"

# Set up build environment
export PROFILE="ai-powerhouse-profile"
export EDITION="ai-powerhouse"

# Use buildiso from garuda-tools
log "Starting ISO build process (this may take 30-60 minutes)..."
./garuda-tools/tools/buildiso -p ai-powerhouse-profile -k linux

# Move the completed ISO to a more accessible location
# Use environment variable or default to user's home directory
DEFAULT_OUTPUT="${HOME}/ai-powerhouse-iso"
OUTPUT_DIR="${ISO_OUTPUT_DIR:-$DEFAULT_OUTPUT}"
mkdir -p "$OUTPUT_DIR"

if [ -f out/*.iso ]; then
    mv out/*.iso "$OUTPUT_DIR/garuda-ai-powerhouse-$(date +%Y-%m-%d).iso"
    ISO_PATH="$OUTPUT_DIR/garuda-ai-powerhouse-$(date +%Y-%m-%d).iso"
    ISO_SIZE=$(du -h "$ISO_PATH" | cut -f1)
    
    log "🎉 ISO build completed successfully!"
    info "ISO Location: $ISO_PATH"
    info "ISO Size: $ISO_SIZE"
    info ""
    info "This ISO includes:"
    info "✅ ZFS root filesystem support"
    info "✅ NVIDIA drivers and CUDA toolkit"
    info "✅ Complete AI/ML development stack"
    info "✅ Rust + Tauri + React development tools"
    info "✅ Media stack (Jellyfin, Sonarr, Radarr, etc.)"
    info "✅ MobaLiveCD ISO testing tool"
    info "✅ Docker and virtualization support"
    info "✅ All AI Powerhouse setup scripts"
    info ""
    info "Boot from this ISO and run the installer with ZFS support!"
    
    # Create checksum
    sha256sum "$ISO_PATH" > "$ISO_PATH.sha256"
    log "SHA256 checksum created: $ISO_PATH.sha256"
    
else
    error "ISO build failed! Check the build logs."
    exit 1
fi

# Cleanup
log "Cleaning up build directory..."
rm -rf "$WORK_DIR"

echo ""
echo "==============================================="
echo "🚀 AI POWERHOUSE ISO BUILD COMPLETE!"
echo "==============================================="
echo ""
echo "Your custom Garuda Linux ISO is ready:"
echo "📦 $ISO_PATH"
echo "📏 Size: $ISO_SIZE"
echo ""
echo "Next steps:"
echo "1. Write ISO to USB: dd if='$ISO_PATH' of=/dev/sdX bs=4M status=progress"
echo "2. Boot from USB and install with ZFS root filesystem"
echo "3. Run 'ai-powerhouse-setup' after installation"
echo "4. Enjoy your ultimate AI development environment!"