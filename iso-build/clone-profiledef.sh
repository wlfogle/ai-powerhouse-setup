#!/usr/bin/env bash
# shellcheck disable=SC2034

# Enhanced archiso profile for cloned Garuda AI Powerhouse system
iso_name="Garuda-AI-Powerhouse-Clone"
iso_label="GARUDA_AI_CLONE_$(date +%Y%m)"
iso_publisher="Garuda Linux AI Powerhouse Clone"
iso_application="Garuda AI Powerhouse System Clone Live/Install CD"
iso_version="$(date +%Y.%m.%d)"
install_dir="garuda"
buildmodes=('iso')

# Support both UEFI and BIOS boot
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

# High compression for smaller ISO size
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '22' '-b' '1M')

# File permissions for live environment
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/etc/sudoers"]="0:0:400"
  ["/etc/sudoers.d"]="0:0:750"
  ["/etc/polkit-1/rules.d"]="0:0:750"
  ["/etc/default/useradd"]="0:0:600"
  ["/etc/locale.gen"]="0:0:644"
  
  # Live environment scripts
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/generate_locale"]="0:0:755"
  
  # System configuration files
  ["/etc/sddm.conf.d/default-session.conf"]="0:0:644"
  
  # Network configuration for live environment
  ["/etc/NetworkManager/NetworkManager.conf"]="0:0:644"
  
  # Desktop environment permissions
  ["/etc/sddm.conf"]="0:0:644"
  ["/etc/sddm.conf.d"]="0:0:755"
  
  # Garuda-specific files
  ["/etc/garuda"]="0:0:755"
  ["/usr/share/garuda"]="0:0:755"
)