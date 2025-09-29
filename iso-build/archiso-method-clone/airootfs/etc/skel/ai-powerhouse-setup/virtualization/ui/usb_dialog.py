"""
USB Creation Dialog for MobaLiveCD Linux
Provides GUI for creating bootable USB drives from ISO files
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Adw, GLib, GObject
import threading
import os
from core.usb_creator import USBCreator

class USBCreationDialog(Adw.MessageDialog):
    """Dialog for creating bootable USB drives"""
    
    def __init__(self, parent, iso_path):
        super().__init__(transient_for=parent)
        
        self.iso_path = iso_path
        self.usb_creator = None
        self.selected_device = None
        self.creation_thread = None
        
        self.set_heading("Create Bootable USB Drive")
        self.set_body(f"Create a bootable USB drive from:\n{os.path.basename(iso_path)}")
        
        # Try to initialize USB creator
        try:
            self.usb_creator = USBCreator()
        except Exception as e:
            self.show_error(f"USB creation not available: {e}")
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
        
        warning_icon = Gtk.Image.new_from_icon_name("dialog-warning-symbolic")
        warning_icon.set_icon_size(Gtk.IconSize.NORMAL)
        warning_box.append(warning_icon)
        
        warning_label = Gtk.Label()
        warning_label.set_markup("<b>Warning:</b> All data on the selected USB drive will be erased!")
        warning_label.set_wrap(True)
        warning_label.set_xalign(0)
        warning_box.append(warning_label)
        
        content_box.append(warning_box)
        
        # Progress bar (initially hidden)
        self.progress_bar = Gtk.ProgressBar()
        self.progress_bar.set_show_text(True)
        self.progress_bar.set_visible(False)
        self.progress_bar.set_margin_top(12)
        content_box.append(self.progress_bar)
        
        # Status label
        self.status_label = Gtk.Label()
        self.status_label.set_wrap(True)
        self.status_label.set_visible(False)
        self.status_label.set_margin_top(6)
        content_box.append(self.status_label)
        
        # Set content
        self.set_extra_child(content_box)
        
        # Add buttons
        self.add_response('cancel', 'Cancel')
        self.add_response('create', 'Create USB')
        
        # Initially disable create button
        self.set_response_enabled('create', False)
        
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
                row.set_title(f"{device['vendor']} {device['model']} ({device['size']})")
                row.set_subtitle(f"Device: {device['device']}")
                
                # Store device info in row
                row.device_info = device
                
                # Add warning icon if device is mounted
                if self.usb_creator.is_device_mounted(device['device']):
                    warning_icon = Gtk.Image.new_from_icon_name("dialog-warning-symbolic")
                    warning_icon.set_tooltip_text("Device is currently mounted")
                    row.add_suffix(warning_icon)
                
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
        self.set_response_enabled('create', False)
    
    def on_device_selected(self, listbox, row):
        """Handle device selection"""
        if row and hasattr(row, 'device_info'):
            self.selected_device = row.device_info
            self.set_response_enabled('create', True)
        else:
            self.selected_device = None
            self.set_response_enabled('create', False)
    
    def on_response(self, dialog, response):
        """Handle dialog response"""
        if response == 'create':
            self.start_usb_creation()
        elif response == 'cancel':
            if self.creation_thread and self.creation_thread.is_alive():
                # TODO: Add cancellation support
                pass
            self.close()
    
    def start_usb_creation(self):
        """Start USB creation in background thread"""
        if not self.selected_device:
            return
        
        # Disable buttons during creation
        self.set_response_enabled('create', False)
        self.set_response_enabled('cancel', False)
        
        # Show progress bar
        self.progress_bar.set_visible(True)
        self.status_label.set_visible(True)
        
        # Start creation thread
        self.creation_thread = threading.Thread(
            target=self.create_usb_worker,
            args=(self.iso_path, self.selected_device['device'])
        )
        self.creation_thread.daemon = True
        self.creation_thread.start()
    
    def create_usb_worker(self, iso_path, usb_device):
        """Worker thread for USB creation"""
        try:
            self.usb_creator.create_bootable_usb(
                iso_path, 
                usb_device, 
                progress_callback=self.update_progress
            )
            
            # Verify creation
            success, message = self.usb_creator.verify_usb_creation(usb_device, iso_path)
            
            if success:
                GLib.idle_add(self.on_creation_success, message)
            else:
                GLib.idle_add(self.on_creation_error, f"Verification failed: {message}")
                
        except Exception as e:
            GLib.idle_add(self.on_creation_error, str(e))
    
    def update_progress(self, message, percent):
        """Update progress from worker thread"""
        GLib.idle_add(self._update_progress_ui, message, percent)
    
    def _update_progress_ui(self, message, percent):
        """Update progress UI (called from main thread)"""
        self.progress_bar.set_fraction(percent / 100.0)
        self.progress_bar.set_text(f"{percent}%")
        self.status_label.set_text(message)
        return False  # Don't repeat
    
    def on_creation_success(self, message):
        """Handle successful USB creation"""
        self.progress_bar.set_visible(False)
        self.status_label.set_markup(f"<span color='green'><b>Success:</b> {message}</span>")
        
        # Re-enable cancel button (now acts as close)
        self.set_response_enabled('cancel', True)
        self.set_response_label('cancel', 'Close')
        
        return False
    
    def on_creation_error(self, error_message):
        """Handle USB creation error"""
        self.progress_bar.set_visible(False)
        self.status_label.set_markup(f"<span color='red'><b>Error:</b> {error_message}</span>")
        
        # Re-enable buttons
        self.set_response_enabled('create', True)
        self.set_response_enabled('cancel', True)
        
        return False
    
    def show_error(self, message):
        """Show error message and close dialog"""
        error_dialog = Adw.MessageDialog.new(self.get_transient_for())
        error_dialog.set_heading("USB Creation Error")
        error_dialog.set_body(message)
        error_dialog.add_response('ok', 'OK')
        error_dialog.present()
        self.close()
