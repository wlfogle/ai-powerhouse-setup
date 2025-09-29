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
  'bios.syslinux'
  'uefi.grub'
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
