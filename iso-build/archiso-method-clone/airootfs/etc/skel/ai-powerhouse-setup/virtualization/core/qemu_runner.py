"""
QEMU runner for MobaLiveCD Linux
Handles QEMU execution and configuration
"""

import os
import stat
import subprocess
import shutil
import tempfile
from pathlib import Path

class QEMURunner:
    """Handles QEMU execution for ISO files"""
    
    def __init__(self):
        self.qemu_binary = self.find_qemu_binary()
        self.default_memory = "16384M"  # 16 GB for testing large ISOs
        self.default_disk_interface = "ide"
        self.use_kvm = self.check_kvm_support()
        
    def find_qemu_binary(self):
        """Find the appropriate QEMU binary"""
        candidates = [
            'qemu-system-x86_64',
            'qemu-system-i386',
            'qemu'
        ]
        
        for binary in candidates:
            if shutil.which(binary):
                return binary
                
        raise RuntimeError("QEMU not found. Please install qemu-system-x86 package")
    
    def check_kvm_support(self):
        """Check if KVM acceleration is available"""
        try:
            # Check if /dev/kvm exists and is accessible
            return os.path.exists('/dev/kvm') and os.access('/dev/kvm', os.R_OK | os.W_OK)
        except:
            return False
    
    def build_qemu_command(self, boot_source, **options):
        """Build QEMU command line arguments
        
        Args:
            boot_source: Path to ISO file or USB device (e.g. /dev/sdb)
            **options: Additional QEMU options
        """
        
        # Base command
        cmd = [self.qemu_binary]
        
        # Memory - reduce for USB devices to avoid memory mapping issues
        if self._is_usb_device(boot_source):
            memory = options.get('memory', '4096M')  # 4GB for USB devices
        else:
            memory = options.get('memory', self.default_memory)  # 16GB for ISOs
        cmd.extend(['-m', memory])
        
        # Machine type - use compatible version for USB devices
        if self._is_usb_device(boot_source):
            # Use older, more compatible machine type for Ventoy
            machine_type = 'pc-q35-2.12'
        else:
            # Use modern machine type for ISOs
            machine_type = 'pc-i440fx-7.2'
            
        if self.use_kvm and options.get('enable_kvm', True):
            cmd.extend(['-machine', f'{machine_type},accel=kvm'])
        else:
            cmd.extend(['-machine', f'{machine_type},accel=tcg'])
        
        # CPU - use host CPU if KVM is available
        if self.use_kvm:
            cmd.extend(['-cpu', 'host'])
        
        # Display
        display = options.get('display', 'gtk')
        if display == 'none':
            cmd.extend(['-display', 'none'])
        else:
            # Use GTK display (remove GL to avoid potential issues)
            cmd.extend(['-display', 'gtk'])
        
        # VGA - adjust based on boot source
        if self._is_usb_device(boot_source):
            # Use standard VGA for USB devices (better Ventoy compatibility)
            vga = options.get('vga', 'std')
        else:
            # Use virtio for ISO files (better performance)
            vga = options.get('vga', 'virtio')
        cmd.extend(['-vga', vga])
        
        # Boot configuration - adjust based on device type
        if self._is_usb_device(boot_source):
            # For USB devices - comprehensive boot configuration with timeout
            cmd.extend(['-boot', 'order=c,menu=on,strict=off,splash-time=10000'])  # 10s timeout
        else:
            # For ISO files, boot from CD-ROM
            cmd.extend(['-boot', 'order=d,menu=on'])  # d = CD-ROM
        
        # Determine if boot source is USB device or ISO file
        is_usb_device = self._is_usb_device(boot_source)
        
        if is_usb_device:
            # Add USB device as primary hard drive for better compatibility with Ventoy
            cmd.extend(['-hda', boot_source])
        else:
            # Add ISO as CD-ROM with better caching
            cmd.extend(['-drive', f'file={boot_source},media=cdrom,readonly=on,cache=unsafe'])
        
        # Audio (simplified to avoid PulseAudio issues)
        if options.get('enable_audio', False):  # Disabled by default
            cmd.extend(['-audiodev', 'alsa,id=audio0'])
            cmd.extend(['-device', 'AC97,audiodev=audio0'])
        
        # USB
        cmd.extend(['-usb'])
        cmd.extend(['-device', 'usb-tablet'])  # Better mouse integration
        
        # Network (user mode)
        if options.get('enable_network', True):
            cmd.extend(['-netdev', 'user,id=net0'])
            cmd.extend(['-device', 'rtl8139,netdev=net0'])
        
        # Additional options for better compatibility
        cmd.extend(['-no-reboot'])
        
        # Add RTC for USB devices for better time handling
        if self._is_usb_device(boot_source):
            cmd.extend(['-rtc', 'base=utc'])
        
        # For USB devices (like Ventoy), add specific compatibility options
        if self._is_usb_device(boot_source):
            # Use standard VGA for better Ventoy compatibility
            # Ventoy sometimes has issues with virtio-vga
            pass
        
        # Enable more CPU features for better compatibility
        if not self.use_kvm:
            cmd.extend(['-cpu', 'max'])
        
        # Machine type already set above with acceleration
        
        return cmd
    
    def _is_usb_device(self, path):
        """Check if path is a USB device (e.g., /dev/sdb)"""
        if not path.startswith('/dev/') or path.lower().endswith('.iso'):
            return False
        
        # Check if it's a block device
        try:
            mode = os.stat(path).st_mode
            return stat.S_ISBLK(mode)
        except (OSError, FileNotFoundError):
            return False
    
    def _can_access_device(self, device_path):
        """Check if we can access the device without sudo"""
        try:
            with open(device_path, 'rb') as f:
                f.read(1)
            return True
        except (OSError, PermissionError):
            return False
    
    def _prepare_usb_device(self, device_path):
        """Prepare USB device for QEMU access by unmounting partitions"""
        try:
            # Unmount all partitions of this device
            result = subprocess.run(['lsblk', '-ln', '-o', 'NAME', device_path], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                for line in result.stdout.strip().split('\n'):
                    if line.strip():
                        partition = f'/dev/{line.strip()}'
                        if partition != device_path:  # Don't try to unmount the main device
                            subprocess.run(['sudo', 'umount', partition], 
                                         capture_output=True, stderr=subprocess.DEVNULL)
                            print(f"Unmounted {partition}")
        except Exception as e:
            print(f"Warning: Could not prepare device {device_path}: {e}")
    
    def run_boot_source(self, boot_source, **options):
        """Run a boot source (ISO file or USB device) with QEMU"""
        if not os.path.exists(boot_source):
            source_type = "USB device" if self._is_usb_device(boot_source) else "ISO file"
            raise FileNotFoundError(f"{source_type} not found: {boot_source}")
        
        # Prepare USB device if needed
        if self._is_usb_device(boot_source):
            print(f"Preparing USB device {boot_source} for QEMU...")
            self._prepare_usb_device(boot_source)
        
        # Build command
        cmd = self.build_qemu_command(boot_source, **options)
        
        # Check if we need sudo for USB device access
        if self._is_usb_device(boot_source):
            if not self._can_access_device(boot_source):
                print(f"USB device requires elevated permissions, using sudo...")
                cmd = ['sudo'] + cmd
        
        # Log the command for debugging
        print(f"Running: {' '.join(cmd)}")
        
        try:
            # Run QEMU - don't wait for it to complete
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE if options.get('quiet', True) else None,
                stderr=subprocess.PIPE
            )
            
            # Just check if it started successfully
            # Don't wait for completion as QEMU should run independently
            import time
            time.sleep(1)  # Give QEMU a moment to start
            
            if process.poll() is not None:
                # Process has already terminated - there was an error
                stdout, stderr = process.communicate()
                error_msg = stderr.decode('utf-8') if stderr else "QEMU failed to start"
                raise RuntimeError(f"QEMU failed: {error_msg}")
            
            print(f"QEMU started successfully with PID: {process.pid}")
                
        except FileNotFoundError:
            raise RuntimeError(f"QEMU binary '{self.qemu_binary}' not found")
        except KeyboardInterrupt:
            # User cancelled - this is normal
            pass
    
    def run_iso(self, iso_path, **options):
        """Run an ISO file with QEMU (backward compatibility)"""
        return self.run_boot_source(iso_path, **options)
    
    def get_system_info(self):
        """Get system information for diagnostics"""
        info = {
            'qemu_binary': self.qemu_binary,
            'kvm_available': self.use_kvm,
            'memory': self.default_memory
        }
        
        # Get QEMU version
        try:
            result = subprocess.run(
                [self.qemu_binary, '--version'],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                info['qemu_version'] = result.stdout.strip().split('\n')[0]
        except:
            info['qemu_version'] = 'Unknown'
        
        return info
    
    def validate_boot_source(self, boot_source):
        """Basic validation of boot source (ISO file or USB device)"""
        if not os.path.exists(boot_source):
            return False, "Boot source does not exist"
        
        if self._is_usb_device(boot_source):
            # Validate USB device
            try:
                # Check if it's a block device
                import stat
                st = os.stat(boot_source)
                if not stat.S_ISBLK(st.st_mode):
                    return False, "Not a valid block device"
                
                # Check if device has some size
                size = st.st_size
                if size == 0:
                    # For block devices, size might be 0, try to read device size differently
                    try:
                        with open(boot_source, 'rb') as f:
                            f.seek(0, 2)  # Seek to end
                            size = f.tell()
                    except (OSError, IOError):
                        pass  # Size check not critical for USB devices
                        
                return True, "Valid USB device"
                
            except OSError as e:
                return False, f"Cannot access device: {e}"
        else:
            # Validate ISO file
            if not boot_source.lower().endswith('.iso'):
                return False, "File does not have .iso extension"
            
            # Check file size (should be > 1MB for a valid ISO)
            try:
                size = os.path.getsize(boot_source)
                if size < 1024 * 1024:  # 1MB
                    return False, "File too small to be a valid ISO"
            except OSError as e:
                return False, f"Cannot read file: {e}"
            
            return True, "Valid ISO file"
    
    def validate_iso(self, iso_path):
        """Basic validation of ISO file (backward compatibility)"""
        return self.validate_boot_source(iso_path)
