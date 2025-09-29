"""
Main window implementation for MobaLiveCD Linux
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Adw, Gio, GLib
import os
import threading
from core.qemu_runner import QEMURunner
from ui.help_dialog import HelpDialog
from ui.about_dialog import AboutDialog
from ui.usb_dialog import USBCreationDialog
from ui.usb_selector_dialog import USBSelectorDialog

class MobaLiveCDWindow(Adw.ApplicationWindow):
    """Main application window"""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        
        # Initialize QEMU runner
        self.qemu_runner = QEMURunner()
        self.current_boot_source = None
        self.boot_source_type = None  # 'iso' or 'usb'
        
        # Set up window properties
        self.set_title("MobaLiveCD")
        self.set_default_size(600, 500)
        
        # Create main content (includes header)
        self.setup_main_content()
        
        # Add actions
        self.create_actions()
        
        # Load translations
        self.setup_translations()
    
    def create_actions(self):
        """Create window actions"""
        # Help action
        help_action = Gio.SimpleAction.new("help", None)
        help_action.connect("activate", self.on_help)
        self.add_action(help_action)
        
        # About action
        about_action = Gio.SimpleAction.new("about", None)
        about_action.connect("activate", self.on_about)
        self.add_action(about_action)
    
    def setup_main_content(self):
        """Setup the main window content"""
        # Main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        
        # Add header bar to main content
        header = Adw.HeaderBar()
        
        # Menu button
        menu_button = Gtk.MenuButton()
        menu_button.set_icon_name("open-menu-symbolic")
        menu_button.set_tooltip_text("Application menu")
        
        # Create menu model
        menu = Gio.Menu()
        menu.append("Help", "win.help")
        menu.append("About", "win.about")
        menu_button.set_menu_model(menu)
        
        header.pack_end(menu_button)
        main_box.append(header)
        
        self.set_content(main_box)
        
        # Welcome section
        self.create_welcome_section(main_box)
        
        # File association section
        self.create_association_section(main_box)
        
        # ISO selection section  
        self.create_iso_section(main_box)
        
        # Action buttons
        self.create_action_buttons(main_box)
    
    def create_welcome_section(self, parent):
        """Create welcome section"""
        welcome_group = Adw.PreferencesGroup()
        welcome_group.set_title("Welcome to MobaLiveCD")
        welcome_group.set_description(
            "This program allows you to test your bootable CD-ROM (LiveCD) "
            "using QEMU virtualization. You can either set up file associations "
            "for ISO images or directly run a LiveCD ISO file.")
        
        parent.append(welcome_group)
    
    def create_association_section(self, parent):
        """Create file association section"""
        assoc_group = Adw.PreferencesGroup()
        assoc_group.set_title("File Association")
        
        # Association row
        assoc_row = Adw.ActionRow()
        assoc_row.set_title("Install right-click menu association")
        assoc_row.set_subtitle("Add 'Open with MobaLiveCD' to ISO file context menu")
        
        # Association button
        assoc_button = Gtk.Button()
        assoc_button.set_label("Install Association")
        assoc_button.set_valign(Gtk.Align.CENTER)
        assoc_button.connect("clicked", self.on_install_association)
        assoc_row.add_suffix(assoc_button)
        
        # Uninstall button
        uninstall_button = Gtk.Button()
        uninstall_button.set_label("Remove")
        uninstall_button.set_valign(Gtk.Align.CENTER)
        uninstall_button.connect("clicked", self.on_remove_association)
        assoc_row.add_suffix(uninstall_button)
        
        assoc_group.add(assoc_row)
        parent.append(assoc_group)
    
    def create_iso_section(self, parent):
        """Create boot source selection section"""
        boot_group = Adw.PreferencesGroup()
        boot_group.set_title("Boot Source Selection")
        boot_group.set_description("Select either an ISO file or USB device to boot in QEMU")
        
        # Boot source selection row
        boot_row = Adw.ActionRow()
        boot_row.set_title("Choose boot source")
        boot_row.set_subtitle("Select an ISO file or USB device to boot in QEMU virtual machine")
        
        # Current boot source label
        self.boot_source_label = Gtk.Label()
        self.boot_source_label.set_text("No boot source selected")
        self.boot_source_label.set_halign(Gtk.Align.START)
        self.boot_source_label.add_css_class("dim-label")
        
        # Buttons container
        button_box = Gtk.Box(spacing=6)
        button_box.set_valign(Gtk.Align.CENTER)
        
        # Browse ISO button
        browse_iso_button = Gtk.Button()
        browse_iso_button.set_label("Browse ISO...")
        browse_iso_button.connect("clicked", self.on_browse_iso)
        button_box.append(browse_iso_button)
        
        # Select USB button
        select_usb_button = Gtk.Button()
        select_usb_button.set_label("Select USB...")
        select_usb_button.connect("clicked", self.on_select_usb)
        button_box.append(select_usb_button)
        
        # Run button
        self.run_button = Gtk.Button()
        self.run_button.set_label("Boot in QEMU")
        self.run_button.add_css_class("suggested-action")
        self.run_button.set_sensitive(False)
        self.run_button.connect("clicked", self.on_run_boot_source)
        button_box.append(self.run_button)
        
        boot_row.add_suffix(button_box)
        boot_group.add(boot_row)
        
        # Add boot source label as second row
        boot_label_row = Adw.ActionRow()
        boot_label_row.set_title("")
        boot_label_row.add_prefix(self.boot_source_label)
        boot_group.add(boot_label_row)
        
        # USB creation section (only show when ISO is selected)
        self.usb_creation_group = Adw.PreferencesGroup()
        self.usb_creation_group.set_title("USB Creation")
        self.usb_creation_group.set_visible(False)
        
        usb_creation_row = Adw.ActionRow()
        usb_creation_row.set_title("Create bootable USB drive")
        usb_creation_row.set_subtitle("Create a bootable USB drive from the selected ISO file")
        
        # USB creation button
        self.usb_button = Gtk.Button()
        self.usb_button.set_label("Create USB")
        self.usb_button.add_css_class("destructive-action")
        self.usb_button.set_sensitive(False)
        self.usb_button.connect("clicked", self.on_create_usb)
        self.usb_button.set_tooltip_text("Create a bootable USB drive from this ISO")
        usb_creation_row.add_suffix(self.usb_button)
        
        self.usb_creation_group.add(usb_creation_row)
        
        parent.append(boot_group)
        parent.append(self.usb_creation_group)
    
    def create_action_buttons(self, parent):
        """Create bottom action buttons"""
        # Add some spacing
        parent.append(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL))
        
        # Button box
        button_box = Gtk.Box(spacing=12)
        button_box.set_halign(Gtk.Align.CENTER)
        button_box.set_margin_top(20)
        button_box.set_margin_bottom(20)
        
        # Exit button
        exit_button = Gtk.Button()
        exit_button.set_label("Exit")
        exit_button.connect("clicked", lambda x: self.close())
        button_box.append(exit_button)
        
        parent.append(button_box)
    
    def setup_translations(self):
        """Setup language support - placeholder for now"""
        # TODO: Implement i18n support
        pass
    
    # Event handlers
    def on_browse_iso(self, button):
        """Handle ISO file browsing"""
        dialog = Gtk.FileChooserDialog(
            title="Select ISO file",
            transient_for=self,
            action=Gtk.FileChooserAction.OPEN
        )
        
        dialog.add_buttons(
            "_Cancel", Gtk.ResponseType.CANCEL,
            "_Open", Gtk.ResponseType.ACCEPT
        )
        
        # Add ISO filter
        filter_iso = Gtk.FileFilter()
        filter_iso.set_name("ISO Image Files")
        filter_iso.add_pattern("*.iso")
        filter_iso.add_pattern("*.ISO")
        dialog.add_filter(filter_iso)
        
        filter_all = Gtk.FileFilter()
        filter_all.set_name("All Files")
        filter_all.add_pattern("*")
        dialog.add_filter(filter_all)
        
        dialog.connect("response", self.on_file_dialog_response)
        dialog.show()
    
    def on_file_dialog_response(self, dialog, response):
        """Handle file dialog response"""
        if response == Gtk.ResponseType.ACCEPT:
            file = dialog.get_file()
            if file:
                self.load_iso_file(file.get_path())
        
        dialog.destroy()
    
    def load_boot_source(self, source_path, source_type):
        """Load a boot source (ISO file or USB device)"""
        # Validate the boot source
        is_valid, message = self.qemu_runner.validate_boot_source(source_path)
        
        if is_valid:
            self.current_boot_source = source_path
            self.boot_source_type = source_type
            
            if source_type == 'iso':
                self.boot_source_label.set_text(f"ISO: {os.path.basename(source_path)}")
                self.usb_creation_group.set_visible(True)
                self.usb_button.set_sensitive(True)
            else:  # USB device
                self.boot_source_label.set_text(f"USB: {source_path}")
                self.usb_creation_group.set_visible(False)
                self.usb_button.set_sensitive(False)
            
            self.boot_source_label.remove_css_class("dim-label")
            self.run_button.set_sensitive(True)
            print(f"Loaded {source_type.upper()}: {source_path}")  # Debug info
        else:
            self.show_error(f"Invalid {source_type}: {message}")
    
    def load_iso_file(self, iso_path):
        """Load an ISO file (backward compatibility)"""
        self.load_boot_source(iso_path, 'iso')
    
    def on_select_usb(self, button):
        """Handle USB device selection"""
        dialog = USBSelectorDialog(self)
        dialog.present()
        
        def on_dialog_response(dialog, response_id):
            if response_id == 'select':
                device_path = dialog.get_selected_device()
                if device_path:
                    self.load_boot_source(device_path, 'usb')
            dialog.destroy()
        
        dialog.connect('response', on_dialog_response)
    
    def on_run_boot_source(self, button):
        """Handle running the boot source (ISO or USB)"""
        if not self.current_boot_source:
            return
        
        # Disable button during execution
        button.set_sensitive(False)
        button.set_label("Starting QEMU...")
        
        # Run QEMU in a separate thread
        def run_qemu():
            try:
                self.qemu_runner.run_boot_source(self.current_boot_source)
            except Exception as e:
                GLib.idle_add(self.show_error, f"Failed to start QEMU: {str(e)}")
            finally:
                GLib.idle_add(self.reset_run_button)
        
        thread = threading.Thread(target=run_qemu, daemon=True)
        thread.start()
    
    def on_run_iso(self, button):
        """Handle running the ISO (backward compatibility)"""
        self.on_run_boot_source(button)
    
    def reset_run_button(self):
        """Reset run button state"""
        self.run_button.set_sensitive(True)
        self.run_button.set_label("Boot in QEMU")
    
    def on_create_usb(self, button):
        """Handle USB creation"""
        if not self.current_boot_source or self.boot_source_type != 'iso':
            self.show_error("Please select an ISO file first to create a USB drive")
            return
        
        # Show USB creation dialog
        dialog = USBCreationDialog(self, self.current_boot_source)
        dialog.present()
    
    def on_install_association(self, button):
        """Handle installing file association"""
        try:
            self.install_desktop_association()
            self.show_success("File association installed successfully!")
        except Exception as e:
            self.show_error(f"Failed to install association: {str(e)}")
    
    def on_remove_association(self, button):
        """Handle removing file association"""
        try:
            self.remove_desktop_association()
            self.show_success("File association removed successfully!")
        except Exception as e:
            self.show_error(f"Failed to remove association: {str(e)}")
    
    def install_desktop_association(self):
        """Install desktop file association"""
        desktop_entry = """[Desktop Entry]
Name=MobaLiveCD
Comment=Test LiveCD ISO files with QEMU
Exec={exec_path} %f
Icon=application-x-cd-image
Terminal=false
Type=Application
MimeType=application/x-cd-image;application/x-iso9660-image;
Categories=System;Emulator;
""".format(exec_path=os.path.abspath(__file__.replace('ui/main_window.py', 'mobalivecd.py')))
        
        # Create desktop file
        desktop_dir = os.path.expanduser("~/.local/share/applications")
        os.makedirs(desktop_dir, exist_ok=True)
        
        desktop_file = os.path.join(desktop_dir, "mobalivecd.desktop")
        with open(desktop_file, 'w') as f:
            f.write(desktop_entry)
        
        # Update MIME database
        os.system("update-desktop-database ~/.local/share/applications 2>/dev/null || true")
    
    def remove_desktop_association(self):
        """Remove desktop file association"""
        desktop_file = os.path.expanduser("~/.local/share/applications/mobalivecd.desktop")
        if os.path.exists(desktop_file):
            os.remove(desktop_file)
            os.system("update-desktop-database ~/.local/share/applications 2>/dev/null || true")
    
    def on_help(self, action, param):
        """Show help dialog"""
        dialog = HelpDialog(self)
        dialog.present()
    
    def on_about(self, action, param):
        """Show about dialog"""
        dialog = AboutDialog(self)
        dialog.present()
    
    def show_error(self, message):
        """Show error message"""
        toast = Adw.Toast()
        toast.set_title(f"Error: {message}")
        toast.set_timeout(5)
        
        if not hasattr(self, 'toast_overlay'):
            self.toast_overlay = Adw.ToastOverlay()
            content = self.get_content()
            self.set_content(self.toast_overlay)
            self.toast_overlay.set_child(content)
        
        self.toast_overlay.add_toast(toast)
    
    def show_success(self, message):
        """Show success message"""
        toast = Adw.Toast()
        toast.set_title(message)
        toast.set_timeout(3)
        
        if not hasattr(self, 'toast_overlay'):
            self.toast_overlay = Adw.ToastOverlay()
            content = self.get_content()
            self.set_content(self.toast_overlay)
            self.toast_overlay.set_child(content)
        
        self.toast_overlay.add_toast(toast)
