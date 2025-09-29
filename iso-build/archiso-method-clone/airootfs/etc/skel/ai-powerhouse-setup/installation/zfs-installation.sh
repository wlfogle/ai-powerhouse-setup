#!/bin/bash

# ZFS Root Installation Script for Garuda Linux
# Superior snapshots and rollback capabilities - better than btrfs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running from live ISO
if ! grep -q "archiso" /proc/cmdline; then
    error "This script must be run from a live ISO environment!"
    exit 1
fi

log "🚀 Starting ZFS root installation for AI Powerhouse setup"

# Install ZFS utilities on live system
log "Installing ZFS utilities on live system..."
pacman -Sy --noconfirm zfs-dkms zfs-utils

# Detect target disk
log "Detecting available disks:"
lsblk -d -o NAME,SIZE,MODEL | grep -E "(nvme|sda|sdb)"

echo -e "\n${YELLOW}Available disks:${NC}"
lsblk -d -o NAME,SIZE,MODEL | grep -E "(nvme|sda|sdb)" | nl

read -p "Enter the disk number to use for installation (e.g., 1 for first disk): " DISK_NUM
DISK_NAME=$(lsblk -d -o NAME | grep -E "(nvme|sda|sdb)" | sed -n "${DISK_NUM}p")

if [ -z "$DISK_NAME" ]; then
    error "Invalid disk selection!"
    exit 1
fi

DISK="/dev/$DISK_NAME"
log "Selected disk: $DISK"

# Confirm disk selection
read -p "⚠️  WARNING: This will DESTROY all data on $DISK. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    error "Installation cancelled"
    exit 1
fi

# Partition the disk
log "Partitioning $DISK..."
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart primary fat32 1MiB 1GiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart primary 1GiB 100%

# Set partition names based on disk type
if [[ "$DISK" =~ nvme ]]; then
    EFI_PART="${DISK}p1"
    ZFS_PART="${DISK}p2"
else
    EFI_PART="${DISK}1"
    ZFS_PART="${DISK}2"
fi

log "EFI partition: $EFI_PART"
log "ZFS partition: $ZFS_PART"

# Format EFI partition
log "Formatting EFI partition..."
mkfs.fat -F32 "$EFI_PART"

# Create ZFS root pool with optimizations
log "Creating ZFS root pool with compression and optimizations..."
zpool create -f \
    -o ashift=12 \
    -O compression=zstd \
    -O atime=off \
    -O xattr=sa \
    -O relatime=on \
    -O normalization=formD \
    -O mountpoint=none \
    -O canmount=off \
    -O devices=off \
    -R /mnt \
    rpool "$ZFS_PART"

# Create ZFS datasets
log "Creating ZFS datasets..."
zfs create -o mountpoint=/ -o canmount=noauto rpool/root
zfs create -o mountpoint=/home rpool/home
zfs create -o mountpoint=/var/cache rpool/cache
zfs create -o mountpoint=/var/log rpool/log
zfs create -o mountpoint=/var/lib/libvirt rpool/libvirt
zfs create -o mountpoint=/opt/ollama rpool/ollama

# Export and re-import pool to set cachefile
log "Configuring ZFS pool..."
zpool export rpool
zpool import -d /dev/disk/by-id -R /mnt rpool -N
zfs mount rpool/root
zfs mount -a

# Mount EFI partition
log "Mounting EFI partition..."
mkdir -p /mnt/boot/efi
mount "$EFI_PART" /mnt/boot/efi

# Install base system
log "Installing base Garuda Linux system..."
pacstrap /mnt base base-devel linux linux-headers linux-firmware \
    zfs-dkms zfs-utils \
    grub efibootmgr \
    networkmanager openssh \
    git curl wget \
    nvidia nvidia-utils cuda \
    docker docker-compose \
    qemu-full virt-manager libvirt

# Generate fstab (ZFS datasets don't need fstab entries)
log "Generating fstab..."
genfstab -U /mnt | grep -v "rpool" > /mnt/etc/fstab

# Configure chroot environment
log "Configuring system in chroot..."
cat << 'EOF' > /mnt/setup-chroot.sh
#!/bin/bash

# Set timezone and locale
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "ai-powerhouse" > /etc/hostname

# Configure hosts file
cat << 'HOSTS' > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ai-powerhouse.localdomain ai-powerhouse
HOSTS

# Enable services
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable docker
systemctl enable libvirtd
systemctl enable zfs-import-cache
systemctl enable zfs-mount
systemctl enable zfs.target

# Configure ZFS in initramfs
echo "zfs" >> /etc/mkinitcpio.conf.d/zfs.conf
echo 'HOOKS=(base udev autodetect modconf block keyboard zfs filesystems)' >> /etc/mkinitcpio.conf.d/zfs.conf

# Regenerate initramfs
mkinitcpio -P

# Install GRUB with ZFS support
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GARUDA --recheck
echo 'GRUB_CMDLINE_LINUX="root=ZFS=rpool/root"' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Set root password
echo "Setting root password..."
passwd

echo "🎉 ZFS root installation completed!"
echo "Next steps after reboot:"
echo "1. Install development tools (Rust, Node.js, etc.)"
echo "2. Configure AI environment (CUDA, PyTorch, Ollama)"
echo "3. Set up media stack and virtualization"
echo "4. Configure ZFS auto-snapshots"

EOF

chmod +x /mnt/setup-chroot.sh
arch-chroot /mnt ./setup-chroot.sh
rm /mnt/setup-chroot.sh

log "🎉 ZFS root installation completed!"
log "Unmounting and preparing for reboot..."

umount -R /mnt
zpool export rpool

echo ""
echo "==============================================="
echo "🚀 INSTALLATION COMPLETE!"
echo "==============================================="
echo ""
echo "Your AI Powerhouse is ready with:"
echo "✅ ZFS root filesystem with compression"
echo "✅ NVIDIA drivers and CUDA ready"
echo "✅ Docker and virtualization support"
echo "✅ Network and SSH configured"
echo ""
echo "After reboot:"
echo "1. Run post-installation scripts"
echo "2. Configure ZFS auto-snapshots"
echo "3. Install AI development tools"
echo "4. Deploy media stack and self-hosting services"
echo ""
echo "Reboot now to start your new system!"