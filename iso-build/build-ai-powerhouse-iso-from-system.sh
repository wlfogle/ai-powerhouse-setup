#!/bin/bash
# AI Powerhouse ISO Builder - System Clone Version
# Clones the existing system at /mnt to create a bootable ISO

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

# Check if running as regular user (we'll use sudo when needed)
if [[ $EUID -eq 0 ]]; then
    print_error "Please run this script as a regular user (not root). We'll use sudo when needed."
    exit 1
fi

# Configuration
SOURCE_DIR="${SOURCE_DIR:-/mnt}"
WORK_DIR="${WORK_DIR:-/tmp/ai-powerhouse-workdir}"
OUTPUT_DIR="${OUTPUT_DIR:-/tmp/ai-powerhouse-output}"
BUILD_DIR="$(dirname "$(realpath "$0")")/archiso-method-clone"
CLONE_DIR="$WORK_DIR/airootfs"

print_status "AI Powerhouse ISO Builder - System Clone Edition"
print_status "================================================"
echo ""

# Validate source directory
if [[ ! -d "$SOURCE_DIR" ]]; then
    print_error "Source directory not found: $SOURCE_DIR"
    exit 1
fi

if [[ ! -f "$SOURCE_DIR/etc/os-release" ]]; then
    print_error "Source directory doesn't appear to contain a Linux system: $SOURCE_DIR"
    exit 1
fi

# Display source system info
print_status "Source System Information:"
if [[ -f "$SOURCE_DIR/etc/os-release" ]]; then
    . "$SOURCE_DIR/etc/os-release"
    echo "  OS: $NAME $VERSION"
    echo "  ID: $ID"
fi
echo "  Source Path: $SOURCE_DIR"
echo "  Size: $(du -sh "$SOURCE_DIR" 2>/dev/null | cut -f1 || echo "Unknown")"
echo ""

# Check for archiso
if ! command -v mkarchiso &> /dev/null; then
    print_error "archiso not found. Installing..."
    sudo pacman -S --noconfirm archiso
    print_success "archiso installed"
fi

# Check disk space - we need space for the source system + workspace
print_status "Checking disk space..."
SOURCE_SIZE=$(du -s "$SOURCE_DIR" 2>/dev/null | awk '{print int($1/1024/1024)}' || echo "0")
AVAILABLE_SPACE=$(df -BG "$HOME" | awk 'NR==2 {gsub(/G/, "", $4); print $4}')
REQUIRED_SPACE=$((SOURCE_SIZE * 3)) # Source + clone + ISO = ~3x

print_status "Disk space analysis:"
echo "  Source system size: ${SOURCE_SIZE}GB"
echo "  Available space: ${AVAILABLE_SPACE}GB"
echo "  Estimated required: ${REQUIRED_SPACE}GB"
echo ""

if [[ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]]; then
    print_warning "Insufficient disk space for safe operation"
    print_warning "You may experience issues during the build process"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Build cancelled"
        exit 1
    fi
fi

# Create build profile directory
print_status "Setting up build environment..."
mkdir -p "$BUILD_DIR"
sudo rm -rf "$WORK_DIR" 2>/dev/null || true
mkdir -p "$OUTPUT_DIR"

# Create archiso profile for cloned system
print_status "Creating archiso profile for cloned system..."

# Copy original profile as base
cp -r "$(dirname "$0")/archiso-method"/* "$BUILD_DIR/" 2>/dev/null || true

# Create updated profiledef.sh for cloned system
cat > "$BUILD_DIR/profiledef.sh" << 'EOF'
#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="Garuda-AI-Powerhouse-Clone"
iso_label="GARUDA_AI_CLONE_$(date +%Y%m)"
iso_publisher="Garuda Linux AI Powerhouse Clone"
iso_application="Garuda AI Powerhouse System Clone Live/Install CD"
iso_version="$(date +%Y.%m.%d)"
install_dir="garuda"
buildmodes=('iso')
bootmodes=(
  'bios.syslinux.mbr'
  'bios.syslinux.eltorito'
  'uefi-ia32.grub.esp'
  'uefi-ia32.grub.eltorito'
	'uefi-x64.systemd-boot.esp'
	'uefi-x64.systemd-boot.eltorito'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/generate_locale"]="0:0:755"
  ["/etc/default/useradd"]="0:0:600"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/sudoers"]="0:0:400"
  ["/etc/locale.gen"]="0:0:644"
)
EOF

# Create minimal packages file (archiso needs this but we'll use the cloned system)
cat > "$BUILD_DIR/packages.x86_64" << 'EOF'
# Minimal packages for archiso - the actual system comes from the clone
base
linux
linux-firmware
mkinitcpio
mkinitcpio-archiso
squashfs-tools
EOF

print_success "Build profile created: $BUILD_DIR"

# Start the cloning process
print_status "Starting system clone process..."
echo ""

BUILD_LOG="$OUTPUT_DIR/build.log"

# Create the work directory structure
sudo mkdir -p "$WORK_DIR"
sudo mkdir -p "$CLONE_DIR"

print_status "Cloning system from $SOURCE_DIR to $CLONE_DIR..."
print_status "This may take a while depending on system size..."

# Clone the system with rsync, excluding problematic directories
if sudo rsync -aHAXv \
    --exclude='/dev/*' \
    --exclude='/proc/*' \
    --exclude='/sys/*' \
    --exclude='/tmp/*' \
    --exclude='/run/*' \
    --exclude='/mnt/*' \
    --exclude='/media/*' \
    --exclude='/lost+found' \
    --exclude='/var/lib/pacman/sync/*' \
    --exclude='/var/cache/pacman/pkg/*' \
    --exclude='/var/tmp/*' \
    --exclude='/var/log/*' \
    --exclude='/home/*/.cache/*' \
    --exclude='/root/.cache/*' \
    --exclude='/swapfile' \
    --exclude='/.snapshots/*' \
    "$SOURCE_DIR/" "$CLONE_DIR/" 2>&1 | tee "$BUILD_LOG"; then
    
    print_success "System clone completed successfully"
else
    print_error "System clone failed!"
    print_error "Check the build log: $BUILD_LOG"
    exit 1
fi

# Prepare the cloned system for live environment
print_status "Preparing cloned system for live environment..."

# Create necessary directories
sudo mkdir -p "$CLONE_DIR"/{dev,proc,sys,tmp,run,mnt,media}

# Clean up system-specific files
sudo rm -f "$CLONE_DIR"/etc/fstab
sudo rm -f "$CLONE_DIR"/etc/crypttab
sudo rm -f "$CLONE_DIR"/etc/machine-id
sudo rm -f "$CLONE_DIR"/var/lib/dbus/machine-id

# Create live environment fstab
sudo tee "$CLONE_DIR/etc/fstab" << 'EOF' > /dev/null
# Live environment fstab
tmpfs /tmp tmpfs nodev,nosuid 0 0
EOF

# Set up live user if needed
if [[ ! -d "$CLONE_DIR/home/lou" ]]; then
    print_status "Creating live user account..."
    sudo chroot "$CLONE_DIR" useradd -m -G wheel,audio,video,optical,storage -s /bin/bash lou || true
    echo "lou:lou" | sudo chpasswd --root "$CLONE_DIR"
    echo "root:root" | sudo chpasswd --root "$CLONE_DIR"
fi

# Configure XFCE as default desktop environment
print_status "Configuring XFCE as default desktop environment..."

# Set XFCE as default session in SDDM config (no auto-login)
if [[ -f "$CLONE_DIR/etc/sddm.conf" ]]; then
    # Remove any existing autologin configuration
    sudo sed -i '/\[Autologin\]/,/^\[/{ /\[Autologin\]/!{ /^\[/!d; }; }' "$CLONE_DIR/etc/sddm.conf"
    sudo sed -i '/^User=/d' "$CLONE_DIR/etc/sddm.conf"
    sudo sed -i '/^Session=/d' "$CLONE_DIR/etc/sddm.conf"
else
    sudo mkdir -p "$CLONE_DIR/etc"
    sudo tee "$CLONE_DIR/etc/sddm.conf" << 'EOF' > /dev/null
[General]
DisplayServer=x11

[Theme]
Current=breeze
EOF
fi

# Set XFCE as the default session for SDDM
sudo mkdir -p "$CLONE_DIR/etc/sddm.conf.d"
sudo tee "$CLONE_DIR/etc/sddm.conf.d/default-session.conf" << 'EOF' > /dev/null
[General]
DefaultSession=xfce
EOF

# Create user session preference for XFCE
sudo mkdir -p "$CLONE_DIR/home/lou/.config"
sudo tee "$CLONE_DIR/home/lou/.dmrc" << 'EOF' > /dev/null
[Desktop]
Session=xfce
EOF

# Set proper ownership for lou's config files
sudo chown -R 1000:1000 "$CLONE_DIR/home/lou/.dmrc" 2>/dev/null || true
sudo chown -R 1000:1000 "$CLONE_DIR/home/lou/.config" 2>/dev/null || true

print_success "System preparation completed"

# Build the ISO
print_status "Building ISO from cloned system..."
cd "$BUILD_DIR"

if sudo mkarchiso -v -w "$WORK_DIR" -o "$OUTPUT_DIR" . 2>&1 | tee -a "$BUILD_LOG"; then
    print_success "ISO build completed successfully!"
    echo ""
    
    # Find the created ISO
    ISO_FILE=$(find "$OUTPUT_DIR" -name "*.iso" -type f | head -n 1)
    if [[ -n "$ISO_FILE" ]]; then
        ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
        print_success "ISO created: $(basename "$ISO_FILE") (${ISO_SIZE})"
        print_status "Location: $ISO_FILE"
        echo ""
        
        # Show verification commands
        print_status "Verification commands:"
        echo "  File info: file '$ISO_FILE'"
        echo "  ISO info: isoinfo -d -i '$ISO_FILE'"
        echo "  Mount test: sudo mkdir -p /mnt/iso && sudo mount -o loop '$ISO_FILE' /mnt/iso"
        echo ""
        
        print_status "Your cloned system ISO is ready!"
        print_status "This ISO contains your complete system from $SOURCE_DIR"
        
    else
        print_error "ISO file not found in output directory"
        exit 1
    fi
else
    print_error "ISO build failed!"
    print_error "Check the build log: $BUILD_LOG"
    exit 1
fi

# Cleanup option
echo ""
read -p "Clean up work directory? (Y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    print_status "Cleaning up work directory..."
    sudo rm -rf "$WORK_DIR"
    print_success "Cleanup completed"
fi

print_success "AI Powerhouse system clone ISO build completed!"
print_status "Your system from $SOURCE_DIR has been packaged into a bootable ISO!"