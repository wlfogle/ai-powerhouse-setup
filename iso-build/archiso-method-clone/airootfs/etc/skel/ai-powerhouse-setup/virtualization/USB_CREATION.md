# USB Creation Guide for MobaLiveCD Linux

This guide explains how to use the USB creation functionality that has been added to MobaLiveCD Linux. This feature allows you to create bootable USB drives directly from ISO files.

## Overview

The USB creation functionality provides two ways to create bootable USB drives:

1. **GUI Method**: Through the main application interface
2. **Command Line Method**: Using the standalone `create_usb.py` script

## GUI Method

### Prerequisites

- GTK4 and PyGObject installed
- Root privileges (the application will prompt for sudo when needed)
- USB device with sufficient space

### Steps

1. Launch MobaLiveCD: `python3 mobalivecd.py`
2. Click "Browse..." to select your ISO file
3. Once an ISO is loaded, the "Create USB" button becomes active
4. Click the "Create USB" button
5. In the USB Creation dialog:
   - Select your target USB device from the list
   - Click "Refresh Devices" if your USB drive isn't visible
   - Click "Create USB" to start the process
   - Monitor the progress bar
6. Wait for the process to complete and verify success

### Safety Features

- **Device Detection**: Automatically detects USB devices
- **Mount Checking**: Warns if devices are currently mounted
- **Confirmation**: Requires explicit device selection
- **Progress Monitoring**: Shows real-time progress
- **Verification**: Automatically verifies the created USB

## Command Line Method

### Basic Usage

```bash
# Interactive mode (recommended for beginners)
python3 create_usb.py

# List available USB devices
python3 create_usb.py --list

# Direct creation (advanced users)
sudo python3 create_usb.py --iso /path/to/file.iso --device /dev/sdb

# Force creation without confirmation
sudo python3 create_usb.py --iso file.iso --device /dev/sdb --force
```

### Makefile Targets

For convenience, you can also use the Makefile:

```bash
# List USB devices
make list-usb

# Interactive USB creation
make create-usb
```

### Command Line Options

- `--iso, -i`: Path to the ISO file
- `--device, -d`: Target USB device (e.g., `/dev/sdb`)
- `--list, -l`: List available USB devices
- `--interactive`: Force interactive mode
- `--force, -f`: Skip confirmation prompts

### Interactive Mode Example

```bash
$ python3 create_usb.py
Enter path to ISO file: /home/user/ubuntu-22.04.iso

Scanning for USB devices...

Available USB devices:
1. /dev/sdb - SanDisk Ultra (32.0GB)
2. /dev/sdc - Kingston DataTraveler (16.0GB) [MOUNTED]

Select device (1-2) or 'q' to quit: 1

WARNING: This will erase all data on /dev/sdb
Device: SanDisk Ultra (32.0GB)
ISO file: ubuntu-22.04.iso

Type 'YES' to confirm: YES

Creating bootable USB drive...
Writing ISO to USB drive... |████████████████████████| 100%

Verifying USB creation...
✓ Success: USB creation appears successful
```

## Technical Details

### How It Works

1. **Device Detection**: Uses `lsblk` to detect USB devices by transport type
2. **Unmounting**: Automatically unmounts any mounted partitions
3. **Raw Copy**: Uses `dd` to copy the ISO directly to the USB device
4. **Synchronization**: Ensures all data is written with `sync`
5. **Verification**: Basic verification by reading back device data

### Supported ISO Types

- **Linux Live CDs**: Ubuntu, Fedora, Debian, etc.
- **Rescue Disks**: SystemRescue, Clonezilla, etc.
- **Diagnostic Tools**: MemTest86+, hardware testing tools
- **Any ISO 9660 Image**: Standard bootable ISOs

### Requirements

The USB creation functionality requires:

- Python 3.8+
- `dd` command (standard on Linux)
- `lsblk` command (standard on Linux)  
- `sync` command (standard on Linux)
- Root privileges for device access
- USB device with adequate space

### Safety Considerations

**⚠️ WARNING**: USB creation will completely erase the target device!

- **Backup Important Data**: Ensure any important data on the USB drive is backed up
- **Verify Device Selection**: Double-check you've selected the correct device
- **Check Device Size**: Ensure the USB drive is larger than the ISO file
- **Avoid System Disks**: Never select your system disk or important storage

### Troubleshooting

#### "No USB devices found"

- Ensure USB device is properly connected
- Try a different USB port
- Check if the device appears in `lsblk` output
- Some USB devices may not be detected as transport type "usb"

#### "Permission denied" errors

- Run with `sudo` for device access
- Ensure your user is in the appropriate groups (`disk`, `storage`)
- Check device permissions in `/dev/`

#### "Device is mounted" warnings

- Unmount the device before creation: `sudo umount /dev/sdb*`
- The script will attempt automatic unmounting

#### USB doesn't boot

- Ensure the original ISO is bootable
- Check that your system supports booting from USB
- Verify BIOS/UEFI boot settings
- Try different USB ports during boot

#### Verification failed

- The USB may still be functional despite verification warnings
- Try the USB device on the target system
- Some ISOs have non-standard signatures that may cause false verification failures

## Advanced Usage

### Scripting

The command-line tool can be used in scripts:

```bash
#!/bin/bash
# Automated USB creation script

ISO_FILE="/path/to/distro.iso"
USB_DEVICE="/dev/sdb"

# Check if ISO exists
if [ ! -f "$ISO_FILE" ]; then
    echo "ISO file not found: $ISO_FILE"
    exit 1
fi

# Create USB with force flag
sudo python3 create_usb.py --iso "$ISO_FILE" --device "$USB_DEVICE" --force

if [ $? -eq 0 ]; then
    echo "USB creation successful!"
else
    echo "USB creation failed!"
    exit 1
fi
```

### Custom Progress Handling

The USB creator can be imported and used with custom progress callbacks:

```python
from core.usb_creator import USBCreator

def my_progress(message, percent):
    print(f"Custom progress: {message} - {percent}%")

creator = USBCreator()
creator.create_bootable_usb(
    "/path/to/file.iso", 
    "/dev/sdb", 
    progress_callback=my_progress
)
```

## Integration with MobaLiveCD

The USB creation functionality is fully integrated with the existing MobaLiveCD workflow:

1. **Unified Interface**: Same ISO selection process
2. **Consistent Experience**: Similar look and feel
3. **Shared Validation**: Uses same ISO validation logic
4. **Error Handling**: Consistent error reporting

This means you can seamlessly switch between running ISOs in QEMU and creating bootable USB drives from the same interface.

## Contributing

If you encounter issues or have suggestions for improving the USB creation functionality:

1. Check the existing issues in the GitHub repository
2. Create detailed bug reports with system information
3. Test the functionality on different distributions
4. Submit pull requests for improvements

## License

The USB creation functionality is released under the same GPL v2+ license as the original MobaLiveCD Linux project.
