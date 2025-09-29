"""
Help dialog for MobaLiveCD Linux
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Adw

class HelpDialog(Adw.Window):
    """Help dialog showing keyboard shortcuts and usage"""
    
    def __init__(self, parent):
        super().__init__()
        
        self.set_title("MobaLiveCD - Help")
        self.set_transient_for(parent)
        self.set_modal(True)
        self.set_default_size(500, 400)
        
        self.create_content()
    
    def create_content(self):
        """Create help dialog content"""
        # Main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.set_content(main_box)
        
        # Header bar
        header = Adw.HeaderBar()
        main_box.append(header)
        
        # Scrolled window for content
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_vexpand(True)
        main_box.append(scrolled)
        
        # Content box
        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        content_box.set_margin_top(24)
        content_box.set_margin_bottom(24)
        content_box.set_margin_start(24)
        content_box.set_margin_end(24)
        scrolled.set_child(content_box)
        
        # Virtual machine controls section
        vm_group = Adw.PreferencesGroup()
        vm_group.set_title("Virtual Machine Controls")
        vm_group.set_description("During emulation, you can use the following keyboard shortcuts:")
        content_box.append(vm_group)
        
        # Keyboard shortcuts
        shortcuts = [
            ("Click in the window", "Interact with the emulated operating system"),
            ("Ctrl + Alt + G", "Release mouse and keyboard from the virtual machine"),
            ("Ctrl + Alt + F", "Toggle fullscreen mode"),
            ("Ctrl + Alt + Q", "Quit the virtual machine"),
            ("Ctrl + Alt + 1", "Switch to virtual machine console"),
            ("Ctrl + Alt + 2", "Switch to QEMU monitor console"),
        ]
        
        for shortcut, description in shortcuts:
            row = Adw.ActionRow()
            row.set_title(shortcut)
            row.set_subtitle(description)
            vm_group.add(row)
        
        # Usage tips section
        tips_group = Adw.PreferencesGroup()
        tips_group.set_title("Usage Tips")
        content_box.append(tips_group)
        
        tips = [
            ("File Association", "Use 'Install Association' to add MobaLiveCD to right-click menu for ISO files"),
            ("Performance", "KVM acceleration is automatically used when available for better performance"),
            ("Memory", "Virtual machines are allocated 512MB RAM by default - sufficient for most LiveCDs"),
            ("Network", "Virtual machines have network access through user-mode networking"),
            ("Audio", "Audio is enabled by default for multimedia LiveCDs"),
        ]
        
        for tip_title, tip_desc in tips:
            row = Adw.ActionRow()
            row.set_title(tip_title)
            row.set_subtitle(tip_desc)
            tips_group.add(row)
        
        # System requirements section
        req_group = Adw.PreferencesGroup()
        req_group.set_title("System Requirements")
        content_box.append(req_group)
        
        requirements = [
            ("QEMU", "qemu-system-x86_64 package must be installed"),
            ("KVM (Optional)", "/dev/kvm access for hardware acceleration"),
            ("Memory", "At least 1GB RAM recommended (512MB for VM + host system)"),
            ("Disk Space", "Temporary space for QEMU runtime files"),
        ]
        
        for req_title, req_desc in requirements:
            row = Adw.ActionRow()
            row.set_title(req_title)
            row.set_subtitle(req_desc)
            req_group.add(row)
        
        # Close button
        button_box = Gtk.Box(spacing=12)
        button_box.set_halign(Gtk.Align.CENTER)
        button_box.set_margin_top(24)
        
        close_button = Gtk.Button()
        close_button.set_label("Close")
        close_button.add_css_class("suggested-action")
        close_button.connect("clicked", lambda x: self.close())
        button_box.append(close_button)
        
        content_box.append(button_box)
