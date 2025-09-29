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
