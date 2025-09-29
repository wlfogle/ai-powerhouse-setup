# Garuda AI Powerhouse - System Clone ISO Builder

This directory contains modified scripts to create a bootable ISO from your existing Garuda system at `/mnt` instead of building from packages.

## Overview

The system clone approach creates an ISO that contains your **exact current system** with all your:
- Installed packages (including AUR packages)
- System configurations 
- User settings and data
- Custom modifications
- AI/ML tools and data

## Scripts

### 1. `prepare-system-for-clone.sh`
**Purpose**: Cleans up the system before cloning to create a smaller, cleaner ISO.

**What it does**:
- Removes temporary files and caches
- Cleans package manager caches
- Removes user browser caches and histories
- Cleans system logs
- Removes system-specific identifiers
- Removes network configurations

**Usage**:
```bash
./prepare-system-for-clone.sh
```

**Environment variables**:
- `TARGET_DIR`: Source directory to clean (default: `/mnt`)

### 2. `build-ai-powerhouse-iso-from-system.sh`
**Purpose**: Creates a bootable ISO from the system at `/mnt`.

**What it does**:
- Uses `rsync` to clone your entire system
- Excludes problematic directories (`/dev`, `/proc`, `/sys`, etc.)
- Prepares the cloned system for live environment
- Creates proper live environment configuration
- Builds bootable ISO using archiso

**Usage**:
```bash
./build-ai-powerhouse-iso-from-system.sh
```

**Environment variables**:
- `SOURCE_DIR`: Source directory to clone (default: `/mnt`)
- `WORK_DIR`: Temporary work directory (default: `/tmp/ai-powerhouse-workdir`)
- `OUTPUT_DIR`: Output directory for ISO (default: `/tmp/ai-powerhouse-output`)

## Usage Workflow

### Step 1: Prepare Your System (Optional but Recommended)
```bash
cd /mnt/home/lou/ai-powerhouse-setup/iso-build/
./prepare-system-for-clone.sh
```

This step is optional but recommended to:
- Reduce ISO size by removing caches
- Clean up sensitive data
- Remove system-specific files

### Step 2: Build the ISO
```bash
./build-ai-powerhouse-iso-from-system.sh
```

## Requirements

### Disk Space
You need approximately **3x your system size** in free space:
- 1x for the source system (your `/mnt`)
- 1x for the cloned copy during build
- 1x for the final ISO

Example: If your system is 22GB, you need ~66GB free space.

### Dependencies
- `archiso` (will be installed automatically)
- `rsync` (usually pre-installed)
- `sudo` access

## Technical Details

### What Gets Excluded
The clone process excludes these directories:
- `/dev/*` - Device files
- `/proc/*` - Process information
- `/sys/*` - System information
- `/tmp/*` - Temporary files
- `/run/*` - Runtime data
- `/mnt/*` - Mount points
- `/media/*` - Removable media
- `/var/cache/pacman/pkg/*` - Package cache
- `/var/log/*` - System logs
- `/home/*/.cache/*` - User caches
- `/.snapshots/*` - BTRFS snapshots
- `/swapfile` - Swap files

### Live Environment Features
The resulting ISO will have:
- Standard login screen (no auto-login)
- XFCE as the default desktop environment
- All your installed packages and configurations
- Working desktop environment
- All your custom settings
- AI/ML tools and data preserved

### Boot Support
The ISO supports:
- UEFI (64-bit and 32-bit)
- Legacy BIOS
- Secure Boot compatible

## Troubleshooting

### Insufficient Disk Space
If you get disk space warnings:
- Clean up your `/tmp` directory
- Use external storage for `WORK_DIR` or `OUTPUT_DIR`
- Run the preparation script to reduce system size

### Build Failures
Check the build log at: `/tmp/ai-powerhouse-output/build.log`

Common issues:
- Permissions errors: Ensure sudo access
- Disk space: See disk space section above
- Missing dependencies: Script will install archiso automatically

### Large ISO Size
If your ISO is too large:
- Run the preparation script first
- Remove unnecessary packages from your system
- Clean up user data and downloads

## Differences from Package-Based Build

| Aspect | Package Build | System Clone |
|--------|--------------|--------------|
| **Source** | Downloads packages fresh | Copies existing system |
| **Size** | ~4-6GB typical | Varies (your system size) |
| **Packages** | Predefined list | Everything you have installed |
| **Settings** | Default configurations | Your exact configurations |
| **User Data** | No user data | Your user data included |
| **AUR Packages** | Not included | All AUR packages included |
| **Build Time** | Depends on download speed | Depends on system size |
| **Customization** | Limited to package list | Complete system clone |

## Tips

1. **Before Building**:
   - Update your system: `sudo pacman -Syu`
   - Clean up files you don't want in the ISO
   - Test that your system boots properly

2. **For Smaller ISOs**:
   - Run the preparation script
   - Remove unused packages: `sudo pacman -Rns $(pacman -Qtdq)`
   - Clear downloads and large files

3. **For Testing**:
   - Test the ISO in a virtual machine first
   - Verify all your applications work
   - Check that hardware drivers are included

## Output

The script creates:
- **ISO file**: `Garuda-AI-Powerhouse-Clone-YYYYMMDD.iso`
- **Build log**: `build.log` 
- **Location**: `/tmp/ai-powerhouse-output/` (or your specified `OUTPUT_DIR`)

The ISO will be bootable and contain your complete system ready for live use or installation.