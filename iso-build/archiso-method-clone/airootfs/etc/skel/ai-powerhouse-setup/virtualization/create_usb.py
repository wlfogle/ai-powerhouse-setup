#!/usr/bin/env python3
"""
USB Creation Tool for MobaLiveCD Linux
Command-line utility for creating bootable USB drives from ISO files
"""

import sys
import os
import argparse
from pathlib import Path

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from core.usb_creator import USBCreator

def print_progress(message, percent):
    """Print progress to console"""
    bar_length = 50
    filled_length = int(bar_length * percent // 100)
    bar = '█' * filled_length + '-' * (bar_length - filled_length)
    print(f'\r{message} |{bar}| {percent}%', end='', flush=True)
    if percent >= 100:
        print()  # New line at completion

def list_usb_devices():
    """List available USB devices"""
    try:
        creator = USBCreator()
        devices = creator.get_usb_devices()
        
        if not devices:
            print("No USB devices found.")
            return False
        
        print("Available USB devices:")
        print("-" * 80)
        
        for i, device in enumerate(devices):
            mounted_status = ""
            if creator.is_device_mounted(device['device']):
                mounted_status = " [MOUNTED]"
            
            print(f"{i+1}. {device['device']} - {device['vendor']} {device['model']}")
            print(f"   Size: {device['size']}{mounted_status}")
        
        print("-" * 80)
        return True
        
    except Exception as e:
        print(f"Error listing USB devices: {e}")
        return False

def create_usb_interactive():
    """Interactive USB creation"""
    try:
        creator = USBCreator()
        
        # Get ISO file
        iso_path = input("Enter path to ISO file: ").strip()
        if not os.path.exists(iso_path):
            print(f"Error: ISO file '{iso_path}' not found")
            return False
        
        if not iso_path.lower().endswith('.iso'):
            print(f"Warning: File '{iso_path}' doesn't have .iso extension")
            if input("Continue anyway? (y/N): ").lower() != 'y':
                return False
        
        # List USB devices
        print("\nScanning for USB devices...")
        devices = creator.get_usb_devices()
        
        if not devices:
            print("No USB devices found.")
            return False
        
        print("\nAvailable USB devices:")
        for i, device in enumerate(devices):
            mounted_status = ""
            if creator.is_device_mounted(device['device']):
                mounted_status = " [MOUNTED]"
            
            print(f"{i+1}. {device['device']} - {device['vendor']} {device['model']} ({device['size']}){mounted_status}")
        
        # Get user selection
        while True:
            try:
                choice = input(f"\nSelect device (1-{len(devices)}) or 'q' to quit: ").strip()
                if choice.lower() == 'q':
                    return False
                
                device_index = int(choice) - 1
                if 0 <= device_index < len(devices):
                    selected_device = devices[device_index]
                    break
                else:
                    print("Invalid selection")
            except ValueError:
                print("Invalid input")
        
        # Confirm action
        print(f"\nWARNING: This will erase all data on {selected_device['device']}")
        print(f"Device: {selected_device['vendor']} {selected_device['model']} ({selected_device['size']})")
        print(f"ISO file: {os.path.basename(iso_path)}")
        
        confirm = input("\nType 'YES' to confirm: ")
        if confirm != 'YES':
            print("Operation cancelled")
            return False
        
        # Create USB
        print(f"\nCreating bootable USB drive...")
        creator.create_bootable_usb(
            iso_path, 
            selected_device['device'], 
            progress_callback=print_progress
        )
        
        # Verify
        print("\nVerifying USB creation...")
        success, message = creator.verify_usb_creation(selected_device['device'], iso_path)
        
        if success:
            print(f"✓ Success: {message}")
            return True
        else:
            print(f"✗ Verification failed: {message}")
            return False
        
    except Exception as e:
        print(f"Error: {e}")
        return False

def create_usb_automated(iso_path, device_path):
    """Automated USB creation"""
    try:
        creator = USBCreator()
        
        # Validate ISO
        if not os.path.exists(iso_path):
            print(f"Error: ISO file '{iso_path}' not found")
            return False
        
        # Validate device
        if not os.path.exists(device_path):
            print(f"Error: Device '{device_path}' not found")
            return False
        
        # Check if device is USB
        devices = creator.get_usb_devices()
        device_found = False
        for device in devices:
            if device['device'] == device_path:
                device_found = True
                print(f"Target device: {device['vendor']} {device['model']} ({device['size']})")
                break
        
        if not device_found:
            print(f"Warning: {device_path} may not be a USB device")
        
        print(f"ISO file: {os.path.basename(iso_path)}")
        print(f"Creating bootable USB drive...")
        
        creator.create_bootable_usb(
            iso_path, 
            device_path, 
            progress_callback=print_progress
        )
        
        # Verify
        print("\nVerifying USB creation...")
        success, message = creator.verify_usb_creation(device_path, iso_path)
        
        if success:
            print(f"✓ Success: {message}")
            return True
        else:
            print(f"✗ Verification failed: {message}")
            return False
        
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(
        description="Create bootable USB drives from ISO files",
        epilog="Example: python3 create_usb.py --iso mylinux.iso --device /dev/sdb"
    )
    
    parser.add_argument('--iso', '-i', 
                       help='Path to ISO file')
    parser.add_argument('--device', '-d',
                       help='USB device path (e.g. /dev/sdb)')
    parser.add_argument('--list', '-l', action='store_true',
                       help='List available USB devices')
    parser.add_argument('--interactive', action='store_true',
                       help='Interactive mode (default if no args)')
    parser.add_argument('--force', '-f', action='store_true',
                       help='Force creation without confirmation')
    
    args = parser.parse_args()
    
    # Check root privileges
    if os.geteuid() != 0:
        print("Warning: This script typically requires root privileges for USB creation")
        print("You may need to run: sudo python3 create_usb.py ...")
    
    # List devices mode
    if args.list:
        return 0 if list_usb_devices() else 1
    
    # Automated mode
    if args.iso and args.device:
        if not args.force:
            print(f"WARNING: This will erase all data on {args.device}")
            confirm = input("Continue? (y/N): ")
            if confirm.lower() != 'y':
                print("Operation cancelled")
                return 1
        
        return 0 if create_usb_automated(args.iso, args.device) else 1
    
    # Interactive mode (default)
    if args.interactive or (not args.iso and not args.device and not args.list):
        return 0 if create_usb_interactive() else 1
    
    # Missing arguments
    parser.print_help()
    return 1

if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)
