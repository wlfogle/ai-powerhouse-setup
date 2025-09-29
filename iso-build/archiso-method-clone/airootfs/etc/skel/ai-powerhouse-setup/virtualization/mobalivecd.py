#!/usr/bin/env python3
"""
MobaLiveCD Linux - A QEMU-based LiveCD/ISO testing tool
Linux port of the original Windows MobaLiveCD application

Copyright (C) 2024 - GPL v2+
"""

import sys
import os
import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Adw, Gio, GLib
from ui.main_window import MobaLiveCDWindow

class MobaLiveCDApplication(Adw.Application):
    """Main application class"""
    
    def __init__(self):
        super().__init__(application_id='org.mobatek.mobalivecd',
                         flags=Gio.ApplicationFlags.HANDLES_OPEN)
        
        # Connect signals
        self.connect('activate', self.on_activate)
        self.connect('open', self.on_open)
        
        # Store boot source if passed as argument
        self.boot_source = None
        
    def on_activate(self, app):
        """Called when application is activated"""
        self.window = MobaLiveCDWindow(application=self)
        self.window.present()
        
        # If we have a boot source from command line, load it (but don't run)
        if self.boot_source:
            if self.boot_source.startswith('/dev/'):
                # It's a USB device
                self.window.load_boot_source(self.boot_source, 'usb')
            else:
                # It's likely an ISO file
                self.window.load_boot_source(self.boot_source, 'iso')
    
    def on_open(self, app, files, n_files, hint):
        """Called when application is opened with files"""
        if n_files > 0:
            # Take the first file
            file = files[0]
            self.boot_source = file.get_path()
        
        self.activate()

def main():
    """Main entry point"""
    app = MobaLiveCDApplication()
    
    # Handle command line arguments
    if len(sys.argv) > 1:
        boot_source_path = sys.argv[1]
        if os.path.exists(boot_source_path):
            app.boot_source = boot_source_path
        else:
            source_type = "USB device" if boot_source_path.startswith('/dev/') else "ISO file"
            print(f"Error: {source_type} '{boot_source_path}' not found")
            return 1
    
    return app.run(sys.argv)

if __name__ == '__main__':
    sys.exit(main())
