# USB Booting Guide for MobaLiveCD Linux

This guide explains how to use the USB booting functionality in MobaLiveCD Linux. This feature allows you to boot USB devices directly in QEMU virtual machines for testing and validation.

## Overview

The USB booting functionality extends MobaLiveCD Linux to support not just ISO files, but also USB devices as boot sources. This is particularly useful for:

- Testing bootable USB drives before using them on physical hardware
- Validating USB drives created with the USB creation tool
- Testing custom bootable USB configurations
- Safe testing of potentially problematic USB drives

## How USB Booting Works

When you select a USB device to boot:

1. **Device Detection**: The application detects available USB devices
2. **QEMU Integration**: The USB device is passed to QEMU as a raw disk
3. **Virtual Booting**: QEMU boots from the USB device as if it were connected to a physical machine
4. **Safe Testing**: No changes are made to the USB device (read-only access)

## GUI Method

### Steps to Boot a USB Device

1. **Launch MobaLiveCD**: Run `python3 mobalivecd.py`
2. **Select USB Device**: Click the "Select USB..." button
3. **Choose Device**: In the USB selector dialog:
   - Review the list of available USB devices
   - Select the device you want to boot
   - Click "Boot USB"
4. **Boot in QEMU**: Click the "Boot in QEMU" button
5. **Test**: The USB device will boot in a QEMU virtual machine

### USB Device Information

The USB selector shows:
- **Device Name**: Vendor and model information
- **Device Path**: Linux device path (e.g., `/dev/sdb`)
- **Size**: Storage capacity of the device
- **Mount Status**: Warning if currently mounted
- **Boot Status**: Indication that device could be bootable

### Safety Features

- **Read-Only Access**: USB devices are accessed read-only by default
- **Mount Detection**: Warns if devices are currently mounted
- **Device Validation**: Ensures selected devices are valid block devices
- **Safe Testing**: No risk to the USB device or host system

## Command Line Method

### Basic Usage

```bash
# Boot a USB device directly
python3 mobalivecd.py /dev/sdb

# The application will:
# 1. Detect it's a USB device (starts with /dev/)
# 2. Load it as a USB boot source
# 3. Enable the "Boot in QEMU" button
```

### Example Usage

```bash
# Boot first USB device
python3 mobalivecd.py /dev/sdb

# Boot second USB device
python3 mobalivecd.py /dev/sdc

# Still works with ISO files
python3 mobalivecd.py /path/to/file.iso
```

## Technical Details

### QEMU Configuration for USB Devices

When booting USB devices, MobaLiveCD uses these QEMU parameters:

```bash
-drive file=/dev/sdb,format=raw,cache=unsafe,if=none,id=usbdisk
-device usb-storage,drive=usbdisk,bootindex=1
```

This configuration:
- Mounts the USB device as a raw disk
- Uses USB storage emulation for compatibility
- Sets boot priority to ensure USB boots first
- Uses unsafe caching for better performance (safe since read-only)

### Differences from ISO Booting

| Aspect | ISO Files | USB Devices |
|--------|-----------|-------------|
| **Access** | File system access | Block device access |
| **Format** | ISO 9660 format | Raw disk format |
| **QEMU Device** | CD-ROM drive | USB storage device |
| **Boot Method** | Optical boot | USB boot |
| **Permissions** | File permissions | Block device permissions |

## Use Cases

### 1. Testing Created USB Drives

After creating a USB drive with MobaLiveCD's USB creation tool:

```bash
# Create USB drive
python3 create_usb.py --iso mylinux.iso --device /dev/sdb

# Test the created USB drive
python3 mobalivecd.py /dev/sdb
```

### 2. Validating Bootable USB Drives

Test USB drives before using them on physical hardware:

1. Insert USB drive
2. Select it in MobaLiveCD
3. Boot in QEMU to verify it works
4. Use with confidence on real hardware

### 3. Troubleshooting Boot Issues

Debug boot problems safely:

- Test different boot configurations
- Analyze boot sequences
- Verify bootloader configurations
- Test without risking physical hardware

### 4. Development and Testing

For developers creating bootable USB tools:

- Test custom boot configurations
- Validate bootloader modifications
- Test on different virtual hardware
- Rapid iteration without physical reboots

## Supported USB Device Types

### ✅ Supported

- **Standard USB Flash Drives**: Most common USB sticks
- **Bootable Linux USB Drives**: Ubuntu, Fedora, etc.
- **Rescue Disks**: SystemRescue, Clonezilla on USB
- **Custom Bootable USB**: Personal bootable configurations
- **Multi-Boot USB**: Drives with multiple boot options

### ⚠️ Partially Supported

- **Encrypted USB Drives**: May work if bootable partition is accessible
- **Multi-Partition USB**: Only boots from first bootable partition
- **Hardware-Specific USB**: May not work if requires specific hardware

### ❌ Not Supported

- **Write-Protected USB**: Not a limitation, but won't show write capability
- **Damaged USB Drives**: May fail if hardware issues exist
- **Non-Bootable USB**: Will start QEMU but won't boot successfully

## Troubleshooting

### "No USB devices found"

**Causes:**
- No USB devices connected
- USB devices not detected as USB transport
- Permission issues

**Solutions:**
```bash
# Check if devices are detected
lsblk -o NAME,SIZE,TYPE,TRAN

# Look for devices with TRAN=usb
# If missing, try different USB ports or devices
```

### "Permission denied" when booting USB

**Cause:** Insufficient permissions to access block device

**Solution:**
```bash
# Run with sudo (not recommended for GUI)
sudo python3 mobalivecd.py /dev/sdb

# Or add user to disk group (preferred)
sudo usermod -a -G disk $USER
# Log out and back in for changes to take effect
```

### USB device boots but shows errors

**Possible causes:**
- Corrupted bootable USB
- Incompatible boot configuration
- Missing boot files

**Debugging steps:**
1. Try the USB on physical hardware first
2. Check if USB was created correctly
3. Verify boot files are present
4. Test with different QEMU options

### QEMU fails to start with USB device

**Check:**
- Device path is correct (`/dev/sdb`, not `/dev/sdb1`)
- Device is not mounted
- User has read permissions
- QEMU is properly installed

**Solution:**
```bash
# Unmount if mounted
sudo umount /dev/sdb*

# Check permissions
ls -l /dev/sdb

# Test QEMU manually
qemu-system-x86_64 -drive file=/dev/sdb,format=raw
```

## Best Practices

### 1. Safety First

- **Always backup important data** before testing
- **Use read-only access** (default behavior)
- **Test in VM first** before physical hardware
- **Verify device selection** to avoid wrong device

### 2. Performance Optimization

- **Unmount USB devices** before booting
- **Close other applications** using the USB device
- **Use adequate system resources** for QEMU
- **Enable KVM acceleration** when available

### 3. Workflow Integration

```bash
# Recommended workflow
1. Create USB: python3 create_usb.py -i distro.iso -d /dev/sdb
2. Test USB:   python3 mobalivecd.py /dev/sdb
3. Use USB:    Insert in target machine and boot
```

## Advanced Configuration

### Custom QEMU Options

You can customize QEMU behavior by modifying the QEMURunner:

```python
# Example: Boot USB with more memory
qemu_runner = QEMURunner()
qemu_runner.run_boot_source('/dev/sdb', memory='8192M')
```

### Multiple USB Devices

Currently, MobaLiveCD boots one USB device at a time. For multiple devices:

1. Boot primary USB device
2. Additional devices could be added to QEMU manually
3. Future versions may support multiple USB devices

## Integration with MobaLiveCD Workflow

USB booting integrates seamlessly with the existing MobaLiveCD workflow:

### Complete Workflow

1. **Test ISO**: `python3 mobalivecd.py distro.iso`
2. **Create USB**: Use "Create USB" button in GUI
3. **Test USB**: `python3 mobalivecd.py /dev/sdb`
4. **Deploy**: Use USB on target hardware

### GUI Workflow

1. Launch MobaLiveCD application
2. Either:
   - Select ISO file → Test → Create USB → Test USB
   - Select USB device directly → Test

## Limitations

### Current Limitations

- **Single USB Device**: Only one USB device can be booted at a time
- **Read-Only Access**: Cannot test USB write operations in VM
- **Block Device Access**: Requires appropriate permissions
- **Linux-Specific**: Device paths are Linux-specific (`/dev/`)

### Future Enhancements

Potential improvements for future versions:

- Multiple USB device support
- Write testing capabilities
- Cross-platform device detection
- USB device benchmarking
- Boot sequence analysis

## Contributing

If you encounter issues or have suggestions for USB booting:

1. **Report Issues**: Include system info and device details
2. **Test Different Devices**: Various USB types and brands
3. **Contribute Improvements**: Better device detection or compatibility
4. **Documentation**: Help improve these guides

## License

USB booting functionality is released under the same GPL v2+ license as MobaLiveCD Linux.
