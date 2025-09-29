#!/bin/bash
# AI Powerhouse ISO Builder - Clean Package-Based Approach
# Builds a proper bootable ISO with your packages but clean base system

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
WORK_DIR="${WORK_DIR:-/tmp/ai-powerhouse-clean-workdir}"
OUTPUT_DIR="${OUTPUT_DIR:-/tmp/ai-powerhouse-clean-output}"
BUILD_DIR="$(dirname "$(realpath "$0")")/archiso-clean"

print_status "AI Powerhouse ISO Builder - Clean Package-Based Build"
print_status "====================================================="
echo ""

# Check for archiso
if ! command -v mkarchiso &> /dev/null; then
    print_error "archiso not found. Installing..."
    sudo pacman -S --noconfirm archiso
    print_success "archiso installed"
fi

# Clean up previous builds
print_status "Cleaning up previous builds..."
sudo rm -rf "$WORK_DIR" "$BUILD_DIR" 2>/dev/null || true
mkdir -p "$OUTPUT_DIR"

# Create clean archiso profile
print_status "Creating clean archiso profile..."
mkdir -p "$BUILD_DIR"

# Create clean profiledef.sh
cat > "$BUILD_DIR/profiledef.sh" << 'EOF'
#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="Garuda-AI-Powerhouse"
iso_label="GARUDA_AI_$(date +%Y%m)"
iso_publisher="Garuda Linux AI Powerhouse"
iso_application="Garuda AI Powerhouse Live/Install CD"
iso_version="$(date +%Y.%m.%d)"
install_dir="garuda"
buildmodes=('iso')
bootmodes=(
  'bios.syslinux'
  'uefi.grub'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/etc/sudoers"]="0:0:400"
  ["/etc/sudoers.d"]="0:0:750"
  ["/etc/polkit-1/rules.d"]="0:0:750"
  ["/etc/default/useradd"]="0:0:600"
  ["/etc/locale.gen"]="0:0:644"
)
EOF

# Create clean pacman.conf (no blendOS!)
cat > "$BUILD_DIR/pacman.conf" << 'EOF'
#
# /etc/pacman.conf
#
[options]
HoldPkg     = pacman glibc
Architecture = auto
Color
CheckSpace
VerbosePkgLists
ILoveCandy
ParallelDownloads = 5
DownloadUser = alpm

SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional

[garuda]
SigLevel = Optional TrustAll
Include = /etc/pacman.d/chaotic-mirrorlist

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist

[chaotic-aur]
SigLevel = Optional TrustAll
Include = /etc/pacman.d/chaotic-mirrorlist
EOF

# Create comprehensive package list
cat > "$BUILD_DIR/packages.x86_64" << 'EOF'
# Base System & Bootloader
base
bash
bash-completion
linux-zen
linux-firmware
mkinitcpio
mkinitcpio-archiso
squashfs-tools
syslinux
grub
efibootmgr
edk2-shell
memtest86+
memtest86+-efi

# Garuda Specific
chaotic-keyring
chaotic-mirrorlist
garuda-hooks
garuda-hotfixes
garuda-libs

# Display & Graphics
nvidia-dkms
xorg-server
xorg-xwayland
xorg-xhost
xorg-xinit
xorg-xinput

# Audio
pipewire
pipewire-pulse
pipewire-jack
pipewire-alsa
wireplumber
lib32-pipewire-jack

# Desktop Environment - XFCE
xfce4
xfce4-goodies
lightdm
lightdm-gtk-greeter
lightdm-gtk-greeter-settings

# Essential Applications
firefox
alacritty
thunar
mousepad
file-manager
nano
neovim

# Development Tools
git
code
python
python-pip
nodejs
npm

# AI & Machine Learning (Essential)
python-pytorch
python-tensorflow
python-numpy
python-pandas
python-matplotlib
python-scikit-learn
ollama
jupyter-console

# Networking
networkmanager
firewalld
nm-connection-editor

# Media
vlc
mpv
ffmpeg

# Utilities
htop
btop
tree
curl
wget
unzip
p7zip

# Gaming (Optional)
steam

# System Tools
gparted
timeshift
EOF

print_success "Clean archiso profile created"

# Build the ISO
print_status "Building clean AI Powerhouse ISO..."
BUILD_LOG="$OUTPUT_DIR/build.log"

if sudo mkarchiso -v -w "$WORK_DIR" -o "$OUTPUT_DIR" "$BUILD_DIR" 2>&1 | tee "$BUILD_LOG"; then
    print_success "ISO build completed successfully!"
    echo ""
    
    # Find the created ISO
    ISO_FILE=$(find "$OUTPUT_DIR" -name "*.iso" -type f | head -n 1)
    if [[ -n "$ISO_FILE" ]]; then
        ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
        print_success "Clean ISO created: $(basename "$ISO_FILE") (${ISO_SIZE})"
        print_status "Location: $ISO_FILE"
        echo ""
        
        print_status "This ISO includes:"
        echo "  ✓ Clean Garuda Linux base system"
        echo "  ✓ XFCE desktop environment"
        echo "  ✓ AI/ML tools (PyTorch, TensorFlow, Ollama)"
        echo "  ✓ Development environment"
        echo "  ✓ Gaming support"
        echo "  ✓ No blendOS branding or repositories"
        echo "  ✓ Proper archiso boot system"
        
    else
        print_error "ISO file not found in output directory"
        exit 1
    fi
else
    print_error "ISO build failed!"
    print_error "Check the build log: $BUILD_LOG"
    exit 1
fi

print_success "Clean AI Powerhouse ISO build completed!"
EOF