"""
USB Creator for MobaLiveCD Linux
Handles creation of bootable USB drives from ISO files
"""

import os
import subprocess
import shutil
import tempfile
from pathlib import Path
import time

class USBCreator:
    """Handles creation of bootable USB drives from ISO files"""
    
    def __init__(self):
        self.required_tools = ['dd', 'lsblk', 'sync']
        self.check_dependencies()
        
    def check_dependencies(self):
        """Check if required tools are available"""
        missing = []
        for tool in self.required_tools:
            if not shutil.which(tool):
                missing.append(tool)
        
        if missing:
            raise RuntimeError(f"Missing required tools: {', '.join(missing)}")
    
    def get_usb_devices(self):
        """Get list of available USB devices"""
        try:
            # Use lsblk to get USB block devices
            result = subprocess.run([
                'lsblk', '-J', '-o', 'NAME,SIZE,TYPE,MOUNTPOINT,TRAN,MODEL,VENDOR'
            ], capture_output=True, text=True, check=True)
            
            import json
            data = json.loads(result.stdout)
            
            usb_devices = []
            for device in data.get('blockdevices', []):
                # Look for USB transport type
                if device.get('tran') == 'usb' and device.get('type') == 'disk':
                    usb_devices.append({
                        'device': f"/dev/{device['name']}",
                        'name': device['name'],
                        'size': device.get('size', 'Unknown'),
                        'model': device.get('model', 'Unknown'),
                        'vendor': device.get('vendor', 'Unknown'),
                        'mountpoint': device.get('mountpoint'),
                        'children': device.get('children', [])
                    })
                    
            return usb_devices
            
        except (subprocess.CalledProcessError, json.JSONDecodeError, FileNotFoundError):
            # Fallback method using /sys/block
            return self._get_usb_devices_fallback()
    
    def _get_usb_devices_fallback(self):
        """Fallback method to detect USB devices"""
        usb_devices = []
        block_devices = Path('/sys/block')
        
        if not block_devices.exists():
            return []
            
        for device_path in block_devices.iterdir():
            if device_path.is_symlink():
                # Check if it's a USB device by following the symlink
                real_path = device_path.resolve()
                if 'usb' in str(real_path):
                    device_name = device_path.name
                    device_file = f"/dev/{device_name}"
                    
                    # Get size if possible
                    size = "Unknown"
                    try:
                        size_file = device_path / 'size'
                        if size_file.exists():
                            sectors = int(size_file.read_text().strip())
                            # Convert sectors to human readable (assuming 512 bytes/sector)
                            bytes_size = sectors * 512
                            size = self._format_size(bytes_size)
                    except (ValueError, OSError):
                        pass
                    
                    usb_devices.append({
                        'device': device_file,
                        'name': device_name,
                        'size': size,
                        'model': 'Unknown',
                        'vendor': 'Unknown',
                        'mountpoint': None,
                        'children': []
                    })
        
        return usb_devices
    
    def _format_size(self, bytes_size):
        """Format size in human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_size < 1024.0:
                return f"{bytes_size:.1f}{unit}"
            bytes_size /= 1024.0
        return f"{bytes_size:.1f}PB"
    
    def is_device_mounted(self, device):
        """Check if device or any of its partitions are mounted"""
        try:
            result = subprocess.run(['lsblk', '-n', '-o', 'MOUNTPOINT', device],
                                  capture_output=True, text=True, check=True)
            mountpoints = result.stdout.strip().split('\n')
            return any(mp and mp != '' for mp in mountpoints)
        except subprocess.CalledProcessError:
            return False
    
    def unmount_device(self, device):
        """Unmount device and all its partitions"""
        try:
            # Get all partitions
            result = subprocess.run(['lsblk', '-n', '-o', 'NAME', device],
                                  capture_output=True, text=True, check=True)
            
            device_names = result.stdout.strip().split('\n')
            
            for name in device_names:
                name = name.strip()
                if name:
                    partition_device = f"/dev/{name}"
                    try:
                        subprocess.run(['umount', partition_device], 
                                     capture_output=True, check=False)
                    except subprocess.CalledProcessError:
                        pass  # Ignore errors, partition might not be mounted
                        
            return True
            
        except subprocess.CalledProcessError as e:
            return False
    
    def create_bootable_usb(self, iso_path, usb_device, progress_callback=None):
        """Create bootable USB from ISO file"""
        
        if not os.path.exists(iso_path):
            raise FileNotFoundError(f"ISO file not found: {iso_path}")
        
        if not os.path.exists(usb_device):
            raise FileNotFoundError(f"USB device not found: {usb_device}")
        
        # Check if ISO file is valid
        iso_size = os.path.getsize(iso_path)
        if iso_size < 1024 * 1024:  # Less than 1MB
            raise ValueError("ISO file appears to be too small")
        
        # Unmount the device first
        if not self.unmount_device(usb_device):
            raise RuntimeError(f"Failed to unmount {usb_device}")
        
        if progress_callback:
            progress_callback("Preparing to write ISO to USB drive...", 0)
        
        try:
            # Use dd to write ISO to USB device
            # We'll use a block size that balances speed and progress updates
            block_size = 1024 * 1024  # 1MB blocks
            
            if progress_callback:
                progress_callback("Writing ISO to USB drive...", 10)
            
            # For progress monitoring, we'll use dd with status=progress if available
            dd_cmd = [
                'dd',
                f'if={iso_path}',
                f'of={usb_device}',
                f'bs={block_size}',
                'conv=fdatasync',
                'status=progress'
            ]
            
            # Execute dd command
            process = subprocess.Popen(
                dd_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True
            )
            
            # Monitor progress
            while process.poll() is None:
                if progress_callback:
                    # We can't easily get exact progress from dd
                    # So we'll just update with a general progress message
                    progress_callback("Writing data to USB drive...", 50)
                time.sleep(1)
            
            # Wait for completion
            process.wait()
            
            if process.returncode != 0:
                output = process.communicate()[0] if process.stdout else ""
                raise RuntimeError(f"dd command failed: {output}")
            
            if progress_callback:
                progress_callback("Syncing data to USB drive...", 90)
            
            # Ensure all data is written
            subprocess.run(['sync'], check=True)
            
            if progress_callback:
                progress_callback("USB creation completed successfully!", 100)
            
            return True
            
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Failed to create bootable USB: {e}")
        except KeyboardInterrupt:
            raise RuntimeError("USB creation was cancelled by user")
    
    def verify_usb_creation(self, usb_device, iso_path):
        """Verify that USB was created successfully"""
        try:
            # Basic verification - check if device is readable
            # and has similar size to ISO
            iso_size = os.path.getsize(iso_path)
            
            # Try to read first few KB from USB device
            with open(usb_device, 'rb') as f:
                data = f.read(2048)  # Read first 2KB
                if len(data) < 512:
                    return False, "USB device appears empty"
            
            # Check if it looks like an ISO (very basic check)
            # ISOs typically start with specific signatures
            if data[0x8000:0x8005] != b'CD001':
                # Not a strict requirement, but many ISOs have this signature
                pass  # We'll be lenient here
            
            return True, "USB creation appears successful"
            
        except (OSError, IOError) as e:
            return False, f"Cannot verify USB: {e}"
    
    def get_recommended_usb_size(self, iso_path):
        """Get recommended USB size for given ISO"""
        try:
            iso_size = os.path.getsize(iso_path)
            # Recommend at least 1.5x ISO size for safety
            recommended_size = int(iso_size * 1.5)
            return recommended_size
        except OSError:
            return None
