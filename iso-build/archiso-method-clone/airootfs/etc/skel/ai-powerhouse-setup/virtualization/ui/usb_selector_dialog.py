"""
USB Device Selector Dialog for MobaLiveCD Linux
Provides GUI for selecting USB devices to boot in QEMU
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Adw, GLib
import os
from core.usb_creator import USBCreator

class USBSelectorDialog(Adw.MessageDialog):
    """Dialog for selecting USB devices to boot in QEMU"""
    
    def __init__(self, parent):
        super().__init__(transient_for=parent)
        
        self.usb_creator = None
        self.selected_device = None
        
        self.set_heading("Select USB Device to Boot")
        self.set_body("Choose a USB device to boot in QEMU virtual machine")
        
        # Try to initialize USB creator for device detection
        try:
            self.usb_creator = USBCreator()
        except Exception as e:
            self.show_error(f"USB device detection not available: {e}")
            return
        
        self.setup_ui()
        self.refresh_devices()
    
    def setup_ui(self):
        """Set up the dialog UI"""
        
        # Create main content box
        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        content_box.set_margin_top(12)
        content_box.set_margin_bottom(12)
        content_box.set_margin_start(12)
        content_box.set_margin_end(12)
        
        # USB device selection
        device_group = Adw.PreferencesGroup()
        device_group.set_title("USB Device Selection")
        device_group.set_description("Select a USB device to boot in QEMU. The device will be mounted as a USB drive in the virtual machine.")
        
        # Device list
        self.device_list = Gtk.ListBox()
        self.device_list.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.device_list.connect('row-selected', self.on_device_selected)
        self.device_list.add_css_class('boxed-list')
        
        device_group.add(self.device_list)
        content_box.append(device_group)
        
        # Refresh button
        refresh_button = Gtk.Button.new_with_label("Refresh Devices")
        refresh_button.connect('clicked', self.on_refresh_clicked)
        refresh_button.set_margin_top(6)
        content_box.append(refresh_button)
        
        # Warning label
        warning_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        warning_box.set_margin_top(12)
        
        warning_icon = Gtk.Image.new_from_icon_name("dialog-information-symbolic")
        warning_icon.set_icon_size(Gtk.IconSize.NORMAL)
        warning_box.append(warning_icon)
        
        warning_label = Gtk.Label()
        warning_label.set_markup("<b>Note:</b> The USB device will be accessed read-only in QEMU. No changes will be made to the device.")
        warning_label.set_wrap(True)
        warning_label.set_xalign(0)
        warning_box.append(warning_label)
        
        content_box.append(warning_box)
        
        # Set content
        self.set_extra_child(content_box)
        
        # Add buttons
        self.add_response('cancel', 'Cancel')
        self.add_response('select', 'Boot USB')
        
        # Initially disable select button
        self.set_response_enabled('select', False)
        
        # Connect response
        self.connect('response', self.on_response)
    
    def refresh_devices(self):
        """Refresh the list of available USB devices"""
        
        # Clear existing devices
        while True:
            row = self.device_list.get_first_child()
            if row is None:
                break
            self.device_list.remove(row)
        
        if not self.usb_creator:
            return
        
        try:
            devices = self.usb_creator.get_usb_devices()
            
            if not devices:
                # Show "no devices" message
                row = Adw.ActionRow()
                row.set_title("No USB devices found")
                row.set_subtitle("Please insert a USB drive and click Refresh")
                row.set_sensitive(False)
                self.device_list.append(row)
                return
            
            for device in devices:
                row = Adw.ActionRow()
                
                # Create title with device info
                title = f"{device['vendor']} {device['model']}"
                if title.strip() == "Unknown Unknown":
                    title = f"USB Device ({device['name']})"
                
                row.set_title(title)
                row.set_subtitle(f"Device: {device['device']} • Size: {device['size']}")
                
                # Store device info in row
                row.device_info = device
                
                # Add status icons
                icon_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
                
                # Add warning icon if device is mounted
                if self.usb_creator.is_device_mounted(device['device']):
                    warning_icon = Gtk.Image.new_from_icon_name("dialog-warning-symbolic")
                    warning_icon.set_tooltip_text("Device is currently mounted")
                    warning_icon.add_css_class("warning")
                    icon_box.append(warning_icon)
                
                # Add bootable icon (we assume USB devices could be bootable)
                boot_icon = Gtk.Image.new_from_icon_name("media-optical-symbolic")
                boot_icon.set_tooltip_text("Bootable device")
                boot_icon.add_css_class("success")
                icon_box.append(boot_icon)
                
                if icon_box.get_first_child():
                    row.add_suffix(icon_box)
                
                self.device_list.append(row)
                
        except Exception as e:
            # Show error message
            row = Adw.ActionRow()
            row.set_title("Error detecting USB devices")
            row.set_subtitle(str(e))
            row.set_sensitive(False)
            self.device_list.append(row)
    
    def on_refresh_clicked(self, button):
        """Handle refresh button click"""
        self.refresh_devices()
        self.selected_device = None
        self.set_response_enabled('select', False)
    
    def on_device_selected(self, listbox, row):
        """Handle device selection"""
        if row and hasattr(row, 'device_info'):
            self.selected_device = row.device_info
            self.set_response_enabled('select', True)
        else:
            self.selected_device = None
            self.set_response_enabled('select', False)
    
    def on_response(self, dialog, response):
        """Handle dialog response"""
        if response == 'select':
            if self.selected_device:
                # Return the selected device path
                self.device_path = self.selected_device['device']
                self.close()
        elif response == 'cancel':
            self.device_path = None
            self.close()
    
    def get_selected_device(self):
        """Get the selected device path"""
        return getattr(self, 'device_path', None)
    
    def show_error(self, message):
        """Show error message and close dialog"""
        error_dialog = Adw.MessageDialog.new(self.get_transient_for())
        error_dialog.set_heading("USB Device Selection Error")
        error_dialog.set_body(message)
        error_dialog.add_response('ok', 'OK')
        error_dialog.present()
        self.close()


class USBSelectorWindow(Adw.Window):
    """Standalone window for USB device selection (for testing)"""
    
    def __init__(self):
        super().__init__()
        
        self.set_title("USB Device Selector")
        self.set_default_size(500, 400)
        
        # Create header bar
        header = Adw.HeaderBar()
        
        # Create main content
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        main_box.append(header)
        
        # Add selector dialog content
        try:
            self.usb_creator = USBCreator()
        except Exception as e:
            label = Gtk.Label()
            label.set_text(f"Error: {e}")
            main_box.append(label)
            self.set_content(main_box)
            return
        
        # Create device list
        self.create_device_list(main_box)
        
        self.set_content(main_box)
    
    def create_device_list(self, parent):
        """Create device list in main window"""
        
        # Welcome section
        welcome_group = Adw.PreferencesGroup()
        welcome_group.set_title("USB Device Selector")
        welcome_group.set_description("Select a USB device to boot in QEMU virtual machine")
        parent.append(welcome_group)
        
        # Device selection
        device_group = Adw.PreferencesGroup()
        device_group.set_title("Available USB Devices")
        
        # Device list
        self.device_list = Gtk.ListBox()
        self.device_list.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.device_list.connect('row-activated', self.on_device_activated)
        self.device_list.add_css_class('boxed-list')
        
        device_group.add(self.device_list)
        parent.append(device_group)
        
        # Refresh devices
        self.refresh_devices()
    
    def refresh_devices(self):
        """Refresh device list"""
        # Clear existing
        while True:
            row = self.device_list.get_first_child()
            if row is None:
                break
            self.device_list.remove(row)
        
        try:
            devices = self.usb_creator.get_usb_devices()
            
            for device in devices:
                row = Adw.ActionRow()
                row.set_title(f"{device['vendor']} {device['model']} ({device['size']})")
                row.set_subtitle(f"Device: {device['device']}")
                row.device_info = device
                self.device_list.append(row)
                
        except Exception as e:
            row = Adw.ActionRow()
            row.set_title(f"Error: {e}")
            row.set_sensitive(False)
            self.device_list.append(row)
    
    def on_device_activated(self, listbox, row):
        """Handle device activation"""
        if hasattr(row, 'device_info'):
            print(f"Selected device: {row.device_info['device']}")


if __name__ == '__main__':
    """Test the USB selector"""
    import sys
    import os
    
    # Add parent directory to path for imports
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    
    app = Adw.Application()
    
    def on_activate(app):
        window = USBSelectorWindow()
        app.add_window(window)
        window.present()
    
    app.connect('activate', on_activate)
    app.run(sys.argv)
