# MobaLiveCD AI

> 🚀 **AI-Enhanced Linux ISO Virtualization Tool**  
> Built upon the excellent foundation of [MobaLiveCD Linux](https://github.com/wlfogle/mobalivecd-linux) by wlfogle

A Linux port of the MobaLiveCD application - a QEMU-based LiveCD/ISO testing tool with a user-friendly GUI.

## Overview

MobaLiveCD Linux allows you to easily test bootable CD/DVD ISO images using QEMU virtualization. This is a complete rewrite of the original Windows application for Linux systems.

## Features

- Simple GUI for selecting and running ISO files
- **NEW: USB Booting** - Boot USB devices directly in QEMU for testing
- **NEW: USB Creation** - Create bootable USB drives directly from ISO files
- Built-in QEMU integration with optimized settings
- File association support (right-click context menu for ISO files)
- Multi-language support
- Modern GTK4 interface
- Native Linux integration
- Command-line USB creation tool

## Requirements

- Linux distribution with GTK4
- QEMU (qemu-system-x86_64)
- Python 3.8+
- PyGObject (GTK4 bindings)

## Installation

### Dependencies

Install required dependencies:

```bash
# Fedora/RHEL/CentOS
sudo dnf install python3 python3-gobject gtk4-devel libadwaita-devel qemu-system-x86

# Ubuntu/Debian
sudo apt install python3 python3-gi python3-gi-cairo gir1.2-gtk-4.0 gir1.2-adw-1 qemu-system-x86

# Arch Linux
sudo pacman -S python python-gobject gtk4 libadwaita qemu-system-x86
```

### Quick Start

```bash
# Clone or extract the application
cd mobalivecd-linux

# Check dependencies
make check

# Run directly (for testing)
make run
# OR
python3 mobalivecd.py
```

### System Installation

```bash
# Install for current user only
make install-user
# OR
./install.sh user

# Install system-wide (requires root)
sudo make install
# OR
sudo ./install.sh system
```

### Uninstallation

```bash
# Uninstall user installation
./uninstall.sh user

# Uninstall system installation
sudo ./uninstall.sh system
# OR
sudo make uninstall
```

## Architecture

- **mobalivecd.py**: Main application entry point
- **ui/main_window.py**: Main GUI window implementation
- **ui/help_dialog.py**: Help dialog
- **ui/about_dialog.py**: About dialog
- **core/qemu_runner.py**: QEMU execution and management
- **core/iso_handler.py**: ISO file handling
- **i18n/**: Translation files
- **assets/**: Icons and resources

## QEMU Integration

Unlike the original Windows version that bundled QEMU, this Linux version uses the system-installed QEMU with these optimizations:

- KVM acceleration when available
- Appropriate memory allocation (512MB default, configurable)
- Modern VGA adapter (std or virtio)
- CD-ROM boot priority
- Optimized for LiveCD testing

## File Associations

The application can register itself as a handler for ISO files, allowing right-click "Open with MobaLiveCD" functionality.

## USB Booting

**New Feature**: Boot USB devices directly in QEMU for testing!

### GUI Method
1. Click the "Select USB..." button
2. Choose a USB device from the list
3. Click "Boot in QEMU" to test the USB device

### Command Line Method
```bash
# Boot USB device directly
python3 mobalivecd.py /dev/sdb
```

## USB Creation

**New Feature**: Create bootable USB drives directly from ISO files!

### GUI Method
1. Select an ISO file using the "Browse ISO..." button
2. Click the "Create USB" button (appears when ISO is selected)
3. Select your USB device from the list
4. Confirm and wait for completion

### Command Line Method
```bash
# Interactive mode
python3 create_usb.py

# List USB devices
make list-usb

# Create USB interactively
make create-usb

# Direct creation (advanced)
sudo python3 create_usb.py --iso myfile.iso --device /dev/sdb
```

See [USB_CREATION.md](USB_CREATION.md) for detailed documentation.

## Testing

The application has been tested with:
- **System**: Fedora Linux 42 with QEMU 9.2.4
- **KVM**: Hardware acceleration available and working
- **GUI**: GTK4/Libadwaita interface
- **ISO Support**: Standard ISO 9660 images
- **USB Booting**: USB flash drives with bootable content
- **USB Creation**: Various Linux distributions and rescue disks

### Command Line Testing

```bash
# Test system capabilities
make check

# Test core functionality
make test

# Run with specific ISO file
python3 mobalivecd.py /path/to/your/livecd.iso
```

## File Associations

After installation, you can:
1. Right-click on any `.iso` file
2. Select "Open with MobaLiveCD" from the context menu
3. The application will launch and automatically load the ISO

Or use the "Install Association" button in the application to set up file associations.

## Performance Tips

- **KVM Acceleration**: Automatically used when `/dev/kvm` is accessible
- **Memory**: Default 512MB RAM allocation works for most LiveCDs
- **Graphics**: Uses modern VGA adapter with hardware acceleration when possible
- **Audio**: PulseAudio integration for multimedia LiveCDs

## Compatibility

### Supported ISO Types
- Linux LiveCD distributions (Ubuntu, Fedora, Debian, etc.)
- Rescue/Recovery CDs (SystemRescue, Clonezilla, etc.)
- Diagnostic tools (MemTest86, hardware testing CDs)
- Any bootable ISO 9660 image

### System Requirements
- **OS**: Any modern Linux distribution with GTK4 support
- **RAM**: 1GB+ recommended (512MB for VM + host system)
- **CPU**: x86_64 architecture
- **Storage**: Minimal disk space for temporary files
- **Optional**: KVM support for hardware acceleration

## Differences from Original MobaLiveCD

### Improvements
- Native Linux integration with modern GTK4 interface
- Automatic KVM acceleration when available
- Better memory management and performance
- Proper desktop environment integration
- No bundled QEMU binaries (uses system QEMU)

### Features Maintained
- Simple GUI for ISO file selection and execution
- File association support for right-click menu
- Help and about dialogs
- Easy installation and uninstallation

## Troubleshooting

### Common Issues

**"QEMU not found" error:**
```bash
sudo dnf install qemu-system-x86  # Fedora
sudo apt install qemu-system-x86  # Ubuntu
```

**GUI doesn't start:**
```bash
sudo dnf install python3-gobject gtk4-devel libadwaita-devel  # Fedora
sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-adw-1     # Ubuntu
```

**No KVM acceleration:**
- Check if KVM is enabled in BIOS/UEFI
- Add user to `kvm` group: `sudo usermod -a -G kvm $USER`
- Reboot after group changes

## 🙏 Attribution & Credits

**This project is built upon and enhances:**
- **Original Project**: [MobaLiveCD Linux](https://github.com/wlfogle/mobalivecd-linux) by **wlfogle**
- **License**: GPL v2+ (preserved and respected)
- **Enhancement**: AI capabilities, modern UI, advanced packaging

**Full acknowledgments**: See [ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md) for complete credits and attribution.

This enhanced version maintains the same core functionality while adding AI-powered features and modern Linux desktop integration.

## 📄 License

GPL v2+ (Same as original project)

Based on the excellent foundation of MobaLiveCD Linux by wlfogle. All enhancements preserve the original GPL v2+ license and maintain full attribution to the original creator.
