# 🚀 AI Powerhouse Setup - Ultimate Development Environment

Transform Garuda Linux into an AI-powered development and self-hosting powerhouse with superior ZFS snapshots.

## 🔥 System Specs
- **CPU**: Intel i9-13900HX (32 threads)
- **GPU**: NVIDIA RTX 4080 (16GB VRAM)
- **RAM**: 64GB DDR5
- **Storage**: Multiple NVMe SSDs with ZFS root

## ⚡ Features
- **ZFS Root Filesystem** - Superior snapshots and rollback (better than btrfs)
- **AI/ML Development** - CUDA acceleration, local LLMs, PyTorch
- **Rust + Tauri + React** - Modern cross-platform app development
- **Virtualization** - KVM/QEMU, Docker, existing Proxmox VM integration
- **Self-Hosting** - Traefik, Portainer, monitoring stack
- **Gaming Optimized** - Maintains Garuda's gaming performance

## 🎯 Integrated Projects
- **[Garuda Media Stack](https://github.com/wlfogle/garuda-media-stack)** - Complete media center (Jellyfin, Sonarr, Radarr) with systemd services
- **[MobaLiveCD Linux](https://github.com/wlfogle/mobalivecd-linux)** - QEMU-based ISO/USB testing tool with GUI
- **Existing Assets Integration**:
  - Your 502GB Proxmox VM automatically configured
  - Ollama models from `/run/media/*/models` integrated
  - All projects combined into one powerhouse setup

## 📁 Project Structure
```
ai-powerhouse-setup/
├── installation/           # ZFS installation scripts and guides
├── configuration/          # System configuration files
├── development/            # Development environment setup
├── ai-ml/                  # AI/ML tools and model management
├── virtualization/         # VM and container configurations  
├── self-hosting/           # Self-hosted services
├── automation/             # Automation scripts and workflows
└── docs/                   # Documentation and guides
```

## 🎯 Installation Phases

### Phase 1: ZFS Root Installation
- Custom Garuda installation with ZFS root
- Superior snapshot and rollback capabilities
- Compression and deduplication

### Phase 2: Development Stack
- Rust toolchain with analyzer
- Node.js and Tauri for desktop apps
- Docker and container orchestration

### Phase 3: AI/ML Environment
- NVIDIA drivers and CUDA toolkit
- PyTorch with GPU acceleration
- Ollama integration with existing models
- Jupyter Lab for experimentation

### Phase 4: Virtualization
- KVM/QEMU setup
- Integration with existing Proxmox VM (502GB)
- Docker Compose orchestration

### Phase 5: Self-Hosting Services
- Traefik reverse proxy
- Portainer container management
- Prometheus + Grafana monitoring
- Essential self-hosted applications

## 🛡️ Backup and Recovery
- Automated ZFS snapshots (hourly, daily, weekly)
- Instant system rollback capabilities
- Configuration backup automation

## 🚀 Getting Started

### Option 1: Build Custom ISO (Recommended)
```bash
# Build your custom AI Powerhouse ISO with everything included
sudo ./installation/build-custom-iso.sh
```
This creates a custom Garuda Linux ISO (~4-6GB) with:
- ZFS root filesystem support
- All AI/ML tools pre-installed
- Media stack ready to deploy
- Your existing Ollama models integrated
- Proxmox VM configuration included

### Option 2: Manual Installation from Live ISO
1. Boot from standard Garuda Live ISO
2. Run ZFS installation: `sudo ./installation/zfs-installation.sh`
3. After reboot, run integration scripts:
   ```bash
   ./ai-ml/ollama-integration.sh
   ./virtualization/proxmox-integration.sh
   cd self-hosting && sudo ./install-native-media-stack.sh
   ```

## 📚 Documentation
- [ZFS Installation Guide](docs/zfs-installation.md)
- [Development Setup](docs/development-setup.md)
- [AI/ML Configuration](docs/ai-ml-setup.md)
- [Self-Hosting Guide](docs/self-hosting.md)

---
*Ultimate AI-powered development environment - Gaming performance meets enterprise reliability*