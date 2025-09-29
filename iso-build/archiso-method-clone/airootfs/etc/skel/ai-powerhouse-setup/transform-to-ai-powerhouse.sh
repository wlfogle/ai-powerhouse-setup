#!/bin/bash

# AI Powerhouse Complete Transformation Script
# Converts any Garuda Linux installation into the ultimate AI development environment
# Run this after installing Garuda Linux normally

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${PURPLE}[SUCCESS]${NC} $1"; }

# Progress tracking
TOTAL_STEPS=15
CURRENT_STEP=0

show_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((percentage / 2))
    local empty=$((50 - filled))
    
    printf "\r${CYAN}Progress: ["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "] %d%% (%d/%d)${NC}" "$percentage" "$CURRENT_STEP" "$TOTAL_STEPS"
    echo ""
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root! Run as your regular user."
    exit 1
fi

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       🚀 GARUDA LINUX → AI POWERHOUSE TRANSFORMATION        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This script will transform your Garuda Linux installation into:${NC}"
echo -e "  ✨ AI Development Environment (CUDA, PyTorch, Ollama)"
echo -e "  🦀 Rust + Tauri + React Development Stack"
echo -e "  🖥️  Complete Media Center (Jellyfin, Sonarr, Radarr, etc.)"
echo -e "  💻 Virtualization Platform (KVM, Docker, Proxmox integration)"
echo -e "  📸 ZFS Snapshots (better than btrfs timeshift)"
echo -e "  🔧 Self-Hosting Services"
echo ""

read -p "Continue with transformation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    warn "Transformation cancelled"
    exit 0
fi

log "🚀 Starting AI Powerhouse transformation..."
show_progress

# Step 1: Update system
log "📦 Updating system packages..."
sudo pacman -Syu --noconfirm
show_progress

# Step 2: Install development tools
log "🔧 Installing development environment..."
sudo pacman -S --noconfirm --needed \
    rustup nodejs npm yarn git github-cli \
    code neovim vim cmake make gcc clang gdb \
    python python-pip python-numpy python-pandas \
    python-matplotlib python-scikit-learn \
    base-devel curl wget htop tree tmux \
    firefox-developer-edition chromium || true
show_progress

# Step 3: Install NVIDIA and CUDA (if NVIDIA GPU detected)
log "🎮 Installing NVIDIA drivers and CUDA support..."
if lspci | grep -i nvidia > /dev/null; then
    sudo pacman -S --noconfirm --needed \
        nvidia nvidia-utils nvidia-settings \
        lib32-nvidia-utils cuda opencl-nvidia || true
    success "NVIDIA CUDA support installed!"
else
    warn "No NVIDIA GPU detected, skipping CUDA installation"
fi
show_progress

# Step 4: Install virtualization
log "🖥️  Installing virtualization stack..."
sudo pacman -S --noconfirm --needed \
    docker docker-compose qemu-full virt-manager \
    libvirt bridge-utils dnsmasq ebtables || true

sudo systemctl enable docker libvirtd
sudo usermod -aG docker,libvirt "$USER"
show_progress

# Step 5: Install media stack dependencies
log "📺 Installing media center components..."
if command -v yay >/dev/null 2>&1; then
    yay -S --noconfirm --needed \
        jellyfin-server jellyfin-web \
        sonarr radarr lidarr jackett \
        qbittorrent-nox calibre \
        ffmpeg vlc obs-studio audacity || true
else
    sudo pacman -S --noconfirm --needed \
        ffmpeg vlc obs-studio audacity || true
    warn "Some media packages might not be available without AUR helper"
fi
show_progress

# Step 6: Set up Rust development
log "🦀 Configuring Rust development environment..."
if ! command -v rustc >/dev/null 2>&1; then
    runuser -u "$USER" -- rustup default stable
    runuser -u "$USER" -- rustup component add rust-analyzer clippy rustfmt
fi

# Install Tauri CLI
if ! command -v cargo-tauri >/dev/null 2>&1; then
    runuser -u "$USER" -- cargo install tauri-cli
fi

# Install Node.js tools
sudo -u "$USER" npm install -g @tauri-apps/cli create-react-app typescript
show_progress

# Step 7: Install ZFS (if not already present)
log "💾 Installing ZFS for superior snapshots..."
if ! command -v zfs >/dev/null 2>&1; then
    sudo pacman -S --noconfirm zfs-dkms zfs-utils || true
    
    # Note: Converting to ZFS root requires reinstallation
    warn "ZFS is now installed but converting to ZFS root requires reinstallation"
    warn "For now, you can use ZFS on additional datasets"
fi
show_progress

# Step 8: Install Ollama for local AI
log "🤖 Installing Ollama for local AI models..."
if ! command -v ollama >/dev/null 2>&1; then
    curl -fsSL https://ollama.ai/install.sh | sh
fi

# Configure Ollama service
sudo tee /etc/systemd/system/ollama.service > /dev/null << 'EOF'
[Unit]
Description=Ollama Local AI Service
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
User=ollama
Group=ollama
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_MODELS=/opt/ollama/models"
Environment="OLLAMA_KEEP_ALIVE=24h"
ExecStart=/usr/local/bin/ollama serve
KillMode=process
Restart=always
RestartSec=3
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create ollama user
if ! id ollama >/dev/null 2>&1; then
    sudo useradd -r -s /bin/false -d /opt/ollama ollama
    sudo mkdir -p /opt/ollama/models
    sudo chown -R ollama:ollama /opt/ollama
fi

sudo systemctl daemon-reload
sudo systemctl enable ollama
show_progress

# Step 9: Integrate existing Ollama models if available
log "🧠 Integrating existing Ollama models..."
EXISTING_MODELS="/run/media/garuda/73cf9511-0af0-4ac4-9d83-ee21eb17ff5d/models"
if [[ -d "$EXISTING_MODELS" ]]; then
    log "Found existing Ollama models, copying..."
    sudo cp -r "$EXISTING_MODELS"/* /opt/ollama/models/ 2>/dev/null || true
    sudo chown -R ollama:ollama /opt/ollama
    success "Existing models integrated!"
else
    warn "No existing models found at $EXISTING_MODELS"
fi
show_progress

# Step 10: Copy AI Powerhouse setup files
log "📂 Installing AI Powerhouse configuration files..."
if [[ -d "$(dirname "$0")" ]]; then
    cp -r "$(dirname "$0")" "$HOME/ai-powerhouse-setup"
    chmod +x "$HOME/ai-powerhouse-setup"/*.sh
    chmod +x "$HOME/ai-powerhouse-setup"/ai-ml/*.sh
    chmod +x "$HOME/ai-powerhouse-setup"/virtualization/*.sh
    chmod +x "$HOME/ai-powerhouse-setup"/self-hosting/*.sh
fi
show_progress

# Step 11: Set up media stack
log "🎬 Configuring media stack..."
if [[ -f "$HOME/ai-powerhouse-setup/self-hosting/install-native-media-stack.sh" ]]; then
    cd "$HOME/ai-powerhouse-setup/self-hosting"
    sudo ./install-native-media-stack.sh || warn "Media stack installation encountered issues"
    cd -
fi
show_progress

# Step 12: Configure Proxmox VM integration if available
log "🖥️  Configuring Proxmox VM integration..."
EXISTING_VM="/run/media/garuda/Data/vms/production/proxmox-ve.qcow2"
if [[ -f "$EXISTING_VM" ]] && [[ -f "$HOME/ai-powerhouse-setup/virtualization/proxmox-integration.sh" ]]; then
    log "Found existing Proxmox VM, integrating..."
    cd "$HOME/ai-powerhouse-setup/virtualization"
    ./proxmox-integration.sh || warn "Proxmox integration encountered issues"
    cd -
else
    warn "No existing Proxmox VM found at $EXISTING_VM"
fi
show_progress

# Step 13: Create management scripts
log "🛠️  Creating system management scripts..."
sudo tee /usr/local/bin/ai-powerhouse-status << 'EOF'
#!/bin/bash
echo "🚀 AI Powerhouse System Status"
echo "================================"
echo ""
echo "🤖 AI Services:"
systemctl is-active ollama && echo "  ✅ Ollama: Running" || echo "  ❌ Ollama: Stopped"
echo ""
echo "🖥️  Virtualization:"
systemctl is-active docker && echo "  ✅ Docker: Running" || echo "  ❌ Docker: Stopped"
systemctl is-active libvirtd && echo "  ✅ LibVirt: Running" || echo "  ❌ LibVirt: Stopped"
echo ""
echo "📺 Media Services:"
systemctl is-active jellyfin && echo "  ✅ Jellyfin: Running" || echo "  ❌ Jellyfin: Stopped"
echo ""
echo "💾 Storage:"
if command -v zfs >/dev/null 2>&1; then
    echo "  ✅ ZFS: Available"
    zpool list 2>/dev/null || echo "  ℹ️  No ZFS pools configured"
else
    echo "  ❌ ZFS: Not installed"
fi
EOF

sudo chmod +x /usr/local/bin/ai-powerhouse-status

# Create desktop entry
mkdir -p "$HOME/.local/share/applications"
tee "$HOME/.local/share/applications/ai-powerhouse-control.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=AI Powerhouse Control
Comment=Manage your AI Powerhouse environment
Exec=gnome-terminal -- ai-powerhouse-status
Icon=applications-development
Terminal=true
Categories=Development;System;
EOF
show_progress

# Step 14: Configure automatic services
log "⚙️  Configuring automatic services..."
sudo systemctl enable NetworkManager bluetooth sddm
sudo systemctl start ollama docker libvirtd
show_progress

# Step 15: Final setup and verification
log "🎯 Final setup and verification..."

# Create welcome script
tee "$HOME/.ai-powerhouse-welcome" << 'EOF'
#!/bin/bash
echo ""
echo "🚀 Welcome to your AI Powerhouse!"
echo "=================================="
echo ""
echo "Quick Commands:"
echo "  ai-powerhouse-status     - Check system status"
echo "  ollama list             - List AI models"
echo "  code                    - Visual Studio Code"
echo "  docker ps               - List containers"
echo "  virt-manager            - VM manager"
echo ""
echo "Web Interfaces:"
echo "  http://localhost:11434  - Ollama API"
echo "  http://localhost:8096   - Jellyfin (if configured)"
echo ""
echo "Project Location: ~/ai-powerhouse-setup"
echo ""
EOF

chmod +x "$HOME/.ai-powerhouse-welcome"

# Add to bashrc if not already there
if ! grep -q "ai-powerhouse-welcome" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# AI Powerhouse welcome message" >> "$HOME/.bashrc"
    echo "[[ -f ~/.ai-powerhouse-welcome ]] && ~/.ai-powerhouse-welcome" >> "$HOME/.bashrc"
fi

show_progress

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                🎉 TRANSFORMATION COMPLETE! 🎉                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Your Garuda Linux system has been transformed into an AI Powerhouse!${NC}"
echo ""
echo -e "${YELLOW}✨ What's been installed:${NC}"
echo -e "  🦀 Rust + Tauri + React development environment"
echo -e "  🤖 Ollama for local AI models"
echo -e "  🎮 NVIDIA CUDA support (if GPU detected)"
echo -e "  🖥️  Docker + KVM virtualization"
echo -e "  📺 Media center components"
echo -e "  💾 ZFS filesystem support"
echo -e "  🔧 Development tools and utilities"
echo ""
echo -e "${PURPLE}🚀 Next Steps:${NC}"
echo -e "  1. Reboot to ensure all services start properly"
echo -e "  2. Run 'ai-powerhouse-status' to check system status"
echo -e "  3. Install AI models: 'ollama pull llama2:13b'"
echo -e "  4. Configure media center: cd ~/ai-powerhouse-setup/self-hosting"
echo -e "  5. Set up VMs: virt-manager"
echo ""
echo -e "${GREEN}🎯 Your AI development environment is ready!${NC}"
echo ""

read -p "Would you like to reboot now to complete the setup? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Rebooting system..."
    sleep 3
    sudo reboot
else
    warn "Please reboot manually to complete the setup"
    log "Run 'ai-powerhouse-status' after reboot to verify everything is working"
fi