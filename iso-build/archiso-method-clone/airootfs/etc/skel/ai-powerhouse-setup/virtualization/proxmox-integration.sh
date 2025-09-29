#!/bin/bash

# Proxmox VM Integration Script
# Integrates existing 502GB Proxmox VM into new AI Powerhouse setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Existing Proxmox VM path
EXISTING_VM="/run/media/garuda/Data/vms/production/proxmox-ve.qcow2"
VM_DIR="/var/lib/libvirt/images"
VM_NAME="proxmox-production"

log "🖥️  Integrating existing Proxmox VM into AI Powerhouse virtualization stack"

# Check if existing VM exists
if [ ! -f "$EXISTING_VM" ]; then
    error "Existing Proxmox VM not found: $EXISTING_VM"
    log "Please ensure the external drive is mounted properly"
    exit 1
fi

# Get VM size and info
VM_SIZE=$(du -h "$EXISTING_VM" | cut -f1)
log "Found Proxmox VM: $VM_SIZE"

# Check available space
AVAILABLE_SPACE=$(df -h /var/lib/libvirt/images | awk 'NR==2 {print $4}')
log "Available space in VM directory: $AVAILABLE_SPACE"

# Create VM directory if it doesn't exist
log "Setting up virtualization environment..."
sudo mkdir -p "$VM_DIR"
sudo mkdir -p /var/lib/libvirt/images/backups

# Install virtualization packages if not already installed
log "Installing virtualization packages..."
if ! command -v virt-manager &> /dev/null; then
    sudo pacman -S --noconfirm qemu-full virt-manager libvirt bridge-utils dnsmasq ebtables
fi

# Enable and start libvirt service
log "Starting virtualization services..."
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
sudo systemctl enable virtlogd
sudo systemctl start virtlogd

# Add user to libvirt group
sudo usermod -aG libvirt "$USER"
sudo usermod -aG kvm "$USER"

# Copy the Proxmox VM to the proper location
log "Copying Proxmox VM to libvirt directory (this may take a while for 502GB)..."
read -p "This will copy 502GB of data. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Skipping VM copy. You can copy it manually later."
    PROXMOX_VM_PATH="$EXISTING_VM"
else
    log "Copying VM file... This will take some time..."
    sudo cp "$EXISTING_VM" "$VM_DIR/$VM_NAME.qcow2"
    PROXMOX_VM_PATH="$VM_DIR/$VM_NAME.qcow2"
    log "✅ VM copied successfully to $PROXMOX_VM_PATH"
fi

# Create VM configuration
log "Creating Proxmox VM configuration for libvirt..."

# Generate UUID for VM
VM_UUID=$(uuidgen)

# Create VM XML configuration
cat > /tmp/proxmox-vm.xml << EOF
<domain type='kvm'>
  <name>$VM_NAME</name>
  <uuid>$VM_UUID</uuid>
  <memory unit='KiB'>8388608</memory>
  <currentMemory unit='KiB'>8388608</currentMemory>
  <vcpu placement='static'>4</vcpu>
  <features>
    <acpi/>
    <apic/>
    <vmport state='off'/>
  </features>
  <cpu mode='host-model' check='partial'/>
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='$PROXMOX_VM_PATH'/>
      <target dev='vda' bus='virtio'/>
      <boot order='1'/>
    </disk>
    <controller type='usb' index='0' model='ich9-ehci1'/>
    <controller type='usb' index='0' model='ich9-uhci1'>
      <master startport='0'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci2'>
      <master startport='2'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci3'>
      <master startport='4'/>
    </controller>
    <controller type='pci' index='0' model='pci-root'/>
    <controller type='ide' index='0'/>
    <controller type='virtio-serial' index='0'/>
    <interface type='network'>
      <mac address='52:54:00:$(openssl rand -hex 3 | sed "s/\(..\)\(..\)\(..\)/\1:\2:\3/")'/>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <serial type='pty'>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <channel type='spicevmc'>
      <target type='virtio' name='com.redhat.spice.0'/>
    </channel>
    <input type='tablet' bus='usb'/>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='spice' autoport='yes'>
      <listen type='address'/>
      <image compression='off'/>
    </graphics>
    <sound model='ich6'>
      <codec type='duplex'/>
    </sound>
    <video>
      <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
    </video>
    <redirdev bus='usb' type='spicevmc'/>
    <redirdev bus='usb' type='spicevmc'/>
    <memballoon model='virtio'/>
  </devices>
</domain>
EOF

# Define the VM in libvirt
log "Registering Proxmox VM with libvirt..."
sudo virsh define /tmp/proxmox-vm.xml
rm /tmp/proxmox-vm.xml

# Set proper permissions
sudo chown qemu:qemu "$PROXMOX_VM_PATH" 2>/dev/null || true

# Create management scripts
log "Creating VM management scripts..."

# Start Proxmox script
cat > /usr/local/bin/start-proxmox << EOF
#!/bin/bash
echo "🖥️  Starting Proxmox VM..."
sudo virsh start $VM_NAME
echo "✅ Proxmox VM started!"
echo "🌐 Access via virt-manager or VNC"
echo "💡 Default Proxmox web interface: https://VM_IP:8006"
EOF

# Stop Proxmox script
cat > /usr/local/bin/stop-proxmox << EOF
#!/bin/bash
echo "🛑 Stopping Proxmox VM..."
sudo virsh shutdown $VM_NAME
echo "✅ Proxmox VM stopped!"
EOF

# Proxmox console script
cat > /usr/local/bin/proxmox-console << EOF
#!/bin/bash
echo "🖥️  Connecting to Proxmox VM console..."
sudo virsh console $VM_NAME
EOF

# VM status script
cat > /usr/local/bin/proxmox-status << EOF
#!/bin/bash
echo "🖥️  Proxmox VM Status:"
sudo virsh dominfo $VM_NAME
echo ""
echo "Network interfaces:"
sudo virsh domifaddr $VM_NAME
EOF

# Make scripts executable
sudo chmod +x /usr/local/bin/*proxmox*

# Create desktop entry for easy VM management
mkdir -p ~/.local/share/applications/
cat > ~/.local/share/applications/proxmox-manager.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Proxmox VM Manager
Comment=Manage Proxmox virtualization environment
Exec=virt-manager
Icon=applications-system
Terminal=false
Categories=System;Virtualization;
EOF

# Configure libvirt networking for better integration
log "Configuring virtualization networking..."

# Create a dedicated bridge for AI Powerhouse VMs
cat > /tmp/ai-powerhouse-network.xml << 'EOF'
<network>
  <name>ai-powerhouse</name>
  <forward mode='nat'/>
  <bridge name='virbr-ai' stp='on' delay='0'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.100' end='192.168.100.200'/>
    </dhcp>
  </ip>
</network>
EOF

sudo virsh net-define /tmp/ai-powerhouse-network.xml
sudo virsh net-autostart ai-powerhouse
sudo virsh net-start ai-powerhouse
rm /tmp/ai-powerhouse-network.xml

# Integration with MobaLiveCD for ISO testing
log "Integrating with MobaLiveCD for ISO testing..."
if [ -f "/home/garuda/ai-powerhouse-setup/virtualization/mobalivecd.py" ]; then
    log "✅ MobaLiveCD found - perfect for testing custom ISOs!"
    
    # Create symlink for easy access
    sudo ln -sf /home/garuda/ai-powerhouse-setup/virtualization/mobalivecd.py /usr/local/bin/mobalivecd
    
    # Install GUI dependencies
    sudo pacman -S --noconfirm python-gobject gtk4 libadwaita
fi

log "🎉 Proxmox VM integration completed successfully!"
echo ""
echo "✅ Proxmox VM registered with libvirt"
echo "✅ VM management scripts created"
echo "✅ Virtualization networking configured" 
echo "✅ MobaLiveCD integrated for ISO testing"
echo ""
echo "🚀 VM Management Commands:"
echo "  start-proxmox        - Start the Proxmox VM"
echo "  stop-proxmox         - Stop the Proxmox VM"
echo "  proxmox-console      - Connect to VM console"
echo "  proxmox-status       - Check VM status"
echo "  virt-manager         - GUI VM manager"
echo ""
echo "🌐 Networking:"
echo "  Main network: default (192.168.122.x)"
echo "  AI Powerhouse network: ai-powerhouse (192.168.100.x)"
echo ""
echo "🔧 Proxmox VM Details:"
echo "  Name: $VM_NAME"
echo "  Memory: 8GB (adjustable)"
echo "  CPU: 4 cores (adjustable)"
echo "  Disk: $VM_SIZE"
echo "  Network: Virtio with NAT"
echo ""
echo "💡 Next Steps:"
echo "1. Run 'start-proxmox' to start the VM"
echo "2. Use 'virt-manager' for GUI management"
echo "3. Access Proxmox web interface at https://VM_IP:8006"
echo "4. Configure Proxmox for your containerized services"
echo ""
echo "Your virtualization powerhouse is ready! 🚀"