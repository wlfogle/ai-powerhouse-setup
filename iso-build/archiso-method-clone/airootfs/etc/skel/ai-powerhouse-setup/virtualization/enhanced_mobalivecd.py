#!/usr/bin/env python3
"""
MobaLiveCD AI - Enhanced Linux ISO Virtualization Tool
AI-powered QEMU-based LiveCD testing with intelligent optimization

Features:
- 🤖 AI-powered ISO detection and optimization
- ⚡ Smart hardware acceleration
- 📊 Real-time performance monitoring
- 🎨 Modern GTK4/Libadwaita interface
- 🔧 Advanced QEMU configuration
- 💻 Multi-VM management
- 🎯 Intelligent resource allocation

Copyright (C) 2024 - GPL v2+
Enhanced by AI optimization
"""

import sys
import os
import gi
import json
import argparse
from pathlib import Path

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Adw, Gio, GLib
from ui.enhanced_main_window import EnhancedMobaLiveCDWindow

class AIEnhancedMobaLiveCDApplication(Adw.Application):
    """AI-Enhanced MobaLiveCD Application"""
    
    def __init__(self):
        super().__init__(
            application_id='org.mobatek.mobalivecd.ai',
            flags=Gio.ApplicationFlags.HANDLES_OPEN | Gio.ApplicationFlags.HANDLES_COMMAND_LINE
        )
        
        # Application state
        self.iso_file = None
        self.config = self._load_config()
        
        # Connect signals
        self.connect('activate', self.on_activate)
        self.connect('open', self.on_open)
        self.connect('command-line', self.on_command_line)
        
        # Setup actions
        self._setup_actions()
        
    def _load_config(self):
        """Load application configuration"""
        config_dir = Path.home() / '.config' / 'mobalivecd-ai'
        config_file = config_dir / 'config.json'
        
        # Default configuration
        default_config = {
            'version': '2.0.0',
            'window': {
                'width': 1200,
                'height': 800,
                'maximized': False
            },
            'preferences': {
                'auto_detect_iso': True,
                'show_performance_overlay': True,
                'enable_ai_optimization': True,
                'default_memory_gb': 2,
                'default_cpu_cores': 2,
                'enable_kvm_by_default': True,
                'enable_audio_by_default': True,
                'enable_network_by_default': True
            },
            'advanced': {
                'qemu_debug': False,
                'performance_monitoring_interval': 5,
                'max_concurrent_vms': 5
            }
        }
        
        try:
            config_dir.mkdir(parents=True, exist_ok=True)
            
            if config_file.exists():
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    # Merge with defaults for new keys
                    return self._merge_config(default_config, config)
            else:
                # Save default config
                with open(config_file, 'w') as f:
                    json.dump(default_config, f, indent=2)
                return default_config
                
        except Exception as e:
            print(f"Error loading config: {e}")
            return default_config
    
    def _merge_config(self, default, user):
        """Merge user config with defaults"""
        for key, value in default.items():
            if key not in user:
                user[key] = value
            elif isinstance(value, dict) and isinstance(user[key], dict):
                user[key] = self._merge_config(value, user[key])
        return user
    
    def _save_config(self):
        """Save application configuration"""
        config_dir = Path.home() / '.config' / 'mobalivecd-ai'
        config_file = config_dir / 'config.json'
        
        try:
            with open(config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            print(f"Error saving config: {e}")
    
    def _setup_actions(self):
        """Setup application actions"""
        
        # System diagnostics action
        diagnostics_action = Gio.SimpleAction.new("diagnostics", None)
        diagnostics_action.connect("activate", self._on_diagnostics_action)
        self.add_action(diagnostics_action)
        
        # Preferences action
        preferences_action = Gio.SimpleAction.new("preferences", None)
        preferences_action.connect("activate", self._on_preferences_action)
        self.add_action(preferences_action)
        
        # About action
        about_action = Gio.SimpleAction.new("about", None)
        about_action.connect("activate", self._on_about_action)
        self.add_action(about_action)
        
        # Quit action
        quit_action = Gio.SimpleAction.new("quit", None)
        quit_action.connect("activate", lambda a, b: self.quit())
        self.add_action(quit_action)
        
        # Keyboard shortcuts
        self.set_accels_for_action("app.quit", ["<primary>q"])
        self.set_accels_for_action("app.preferences", ["<primary>comma"])
        self.set_accels_for_action("app.diagnostics", ["<primary><shift>d"])
    
    def on_activate(self, app):
        """Called when application is activated"""
        
        # Create main window
        self.window = EnhancedMobaLiveCDWindow(application=self)
        
        # Apply saved window state
        window_config = self.config.get('window', {})
        self.window.set_default_size(
            window_config.get('width', 1200),
            window_config.get('height', 800)
        )
        
        if window_config.get('maximized', False):
            self.window.maximize()
        
        # Load ISO file if provided
        if self.iso_file:
            self.window.load_iso_file(self.iso_file)
        
        # Present window
        self.window.present()
    
    def on_open(self, app, files, n_files, hint):
        """Called when application is opened with files"""
        if n_files > 0:
            # Take the first file
            file = files[0]
            self.iso_file = file.get_path()
        
        self.activate()
    
    def on_command_line(self, app, command_line):
        """Handle command line arguments"""
        
        parser = argparse.ArgumentParser(
            description='MobaLiveCD AI - Enhanced ISO Virtualization',
            prog='mobalivecd-ai'
        )
        
        parser.add_argument(
            'iso_file',
            nargs='?',
            help='ISO file to load'
        )
        
        parser.add_argument(
            '--quick-launch',
            action='store_true',
            help='Automatically launch with AI-optimized settings'
        )
        
        parser.add_argument(
            '--memory',
            type=int,
            help='Memory in GB for quick launch'
        )
        
        parser.add_argument(
            '--cpu-cores',
            type=int,
            help='Number of CPU cores for quick launch'
        )
        
        parser.add_argument(
            '--no-kvm',
            action='store_true',
            help='Disable KVM acceleration'
        )
        
        parser.add_argument(
            '--debug',
            action='store_true',
            help='Enable debug output'
        )
        
        parser.add_argument(
            '--version',
            action='version',
            version=f'MobaLiveCD AI v{self.config.get("version", "2.0.0")}'
        )
        
        # Parse arguments
        args = parser.parse_args(command_line.get_arguments()[1:])
        
        # Handle ISO file
        if args.iso_file:
            if os.path.exists(args.iso_file):
                self.iso_file = args.iso_file
            else:
                print(f"Error: ISO file '{args.iso_file}' not found")
                return 1
        
        # Handle quick launch
        if args.quick_launch and self.iso_file:
            self._handle_quick_launch(args)
        
        # Enable debug if requested
        if args.debug:
            self.config['advanced']['qemu_debug'] = True
        
        # Activate application
        self.activate()
        return 0
    
    def _handle_quick_launch(self, args):
        """Handle quick launch from command line"""
        
        def quick_launch():
            try:
                from core.enhanced_qemu_runner import AIEnhancedQEMURunner
                
                runner = AIEnhancedQEMURunner()
                
                # Build options
                options = {}
                
                if args.memory:
                    options['memory'] = f"{args.memory}G"
                
                if args.cpu_cores:
                    options['cpu_cores'] = str(args.cpu_cores)
                
                if args.no_kvm:
                    options['enable_kvm'] = False
                
                # Launch VM
                print(f"🚀 Quick launching: {os.path.basename(self.iso_file)}")
                pid = runner.run_optimized_iso(self.iso_file, **options)
                print(f"✅ Virtual machine started successfully (PID: {pid})")
                
            except Exception as e:
                print(f"❌ Quick launch failed: {e}")
        
        # Run quick launch in thread
        import threading
        thread = threading.Thread(target=quick_launch, daemon=True)
        thread.start()
    
    def _on_diagnostics_action(self, action, param):
        """Handle diagnostics action"""
        if hasattr(self, 'window'):
            self.window._show_system_diagnostics()
    
    def _on_preferences_action(self, action, param):
        """Handle preferences action"""
        self._show_preferences_dialog()
    
    def _on_about_action(self, action, param):
        """Handle about action"""
        self._show_about_dialog()
    
    def _show_preferences_dialog(self):
        """Show preferences dialog"""
        
        dialog = Adw.PreferencesWindow()
        dialog.set_transient_for(self.window)
        dialog.set_title("Preferences")
        
        # General page
        general_page = Adw.PreferencesPage()
        general_page.set_title("General")
        general_page.set_icon_name("applications-system-symbolic")
        
        # AI & Detection group
        ai_group = Adw.PreferencesGroup()
        ai_group.set_title("🤖 AI & Detection")
        ai_group.set_description("Configure intelligent features")
        
        # Auto-detect ISO
        auto_detect_row = Adw.SwitchRow()
        auto_detect_row.set_title("Auto-detect ISO Types")
        auto_detect_row.set_subtitle("Automatically identify and optimize ISO configurations")
        auto_detect_row.set_active(self.config['preferences']['auto_detect_iso'])
        auto_detect_row.connect('notify::active', 
            lambda row, param: self._update_config('preferences', 'auto_detect_iso', row.get_active()))
        ai_group.add(auto_detect_row)
        
        # Enable AI optimization
        ai_opt_row = Adw.SwitchRow()
        ai_opt_row.set_title("AI Optimization")
        ai_opt_row.set_subtitle("Use AI-powered resource allocation and optimization")
        ai_opt_row.set_active(self.config['preferences']['enable_ai_optimization'])
        ai_opt_row.connect('notify::active',
            lambda row, param: self._update_config('preferences', 'enable_ai_optimization', row.get_active()))
        ai_group.add(ai_opt_row)
        
        general_page.add(ai_group)
        
        # Default Settings group
        defaults_group = Adw.PreferencesGroup()
        defaults_group.set_title("⚙️ Default Settings")
        defaults_group.set_description("Default values for new VMs")
        
        # Default memory
        memory_row = Adw.SpinRow()
        memory_row.set_title("Default Memory (GB)")
        memory_row.set_subtitle("Default RAM allocation for new VMs")
        memory_adjustment = Gtk.Adjustment(
            value=self.config['preferences']['default_memory_gb'],
            lower=0.5, upper=64, step_increment=0.5
        )
        memory_row.set_adjustment(memory_adjustment)
        memory_row.connect('notify::value',
            lambda row, param: self._update_config('preferences', 'default_memory_gb', row.get_value()))
        defaults_group.add(memory_row)
        
        # Default CPU cores
        cpu_row = Adw.SpinRow()
        cpu_row.set_title("Default CPU Cores")
        cpu_row.set_subtitle("Default number of CPU cores")
        cpu_adjustment = Gtk.Adjustment(
            value=self.config['preferences']['default_cpu_cores'],
            lower=1, upper=16, step_increment=1
        )
        cpu_row.set_adjustment(cpu_adjustment)
        cpu_row.connect('notify::value',
            lambda row, param: self._update_config('preferences', 'default_cpu_cores', int(row.get_value())))
        defaults_group.add(cpu_row)
        
        general_page.add(defaults_group)
        dialog.add(general_page)
        
        # Performance page
        performance_page = Adw.PreferencesPage()
        performance_page.set_title("Performance")
        performance_page.set_icon_name("applications-monitoring-symbolic")
        
        # Monitoring group
        monitoring_group = Adw.PreferencesGroup()
        monitoring_group.set_title("📊 Monitoring")
        
        # Performance overlay
        overlay_row = Adw.SwitchRow()
        overlay_row.set_title("Show Performance Overlay")
        overlay_row.set_subtitle("Display real-time performance metrics")
        overlay_row.set_active(self.config['preferences']['show_performance_overlay'])
        overlay_row.connect('notify::active',
            lambda row, param: self._update_config('preferences', 'show_performance_overlay', row.get_active()))
        monitoring_group.add(overlay_row)
        
        # Monitoring interval
        interval_row = Adw.SpinRow()
        interval_row.set_title("Monitoring Interval (seconds)")
        interval_row.set_subtitle("How often to update performance metrics")
        interval_adjustment = Gtk.Adjustment(
            value=self.config['advanced']['performance_monitoring_interval'],
            lower=1, upper=30, step_increment=1
        )
        interval_row.set_adjustment(interval_adjustment)
        interval_row.connect('notify::value',
            lambda row, param: self._update_config('advanced', 'performance_monitoring_interval', int(row.get_value())))
        monitoring_group.add(interval_row)
        
        performance_page.add(monitoring_group)
        
        # Limits group
        limits_group = Adw.PreferencesGroup()
        limits_group.set_title("🚧 Resource Limits")
        
        # Max concurrent VMs
        max_vms_row = Adw.SpinRow()
        max_vms_row.set_title("Maximum Concurrent VMs")
        max_vms_row.set_subtitle("Limit number of simultaneous virtual machines")
        max_vms_adjustment = Gtk.Adjustment(
            value=self.config['advanced']['max_concurrent_vms'],
            lower=1, upper=20, step_increment=1
        )
        max_vms_row.set_adjustment(max_vms_adjustment)
        max_vms_row.connect('notify::value',
            lambda row, param: self._update_config('advanced', 'max_concurrent_vms', int(row.get_value())))
        limits_group.add(max_vms_row)
        
        performance_page.add(limits_group)
        dialog.add(performance_page)
        
        # Advanced page
        advanced_page = Adw.PreferencesPage()
        advanced_page.set_title("Advanced")
        advanced_page.set_icon_name("applications-development-symbolic")
        
        # Debug group
        debug_group = Adw.PreferencesGroup()
        debug_group.set_title("🐛 Debugging")
        
        # QEMU debug
        debug_row = Adw.SwitchRow()
        debug_row.set_title("QEMU Debug Output")
        debug_row.set_subtitle("Show detailed QEMU command output (for troubleshooting)")
        debug_row.set_active(self.config['advanced']['qemu_debug'])
        debug_row.connect('notify::active',
            lambda row, param: self._update_config('advanced', 'qemu_debug', row.get_active()))
        debug_group.add(debug_row)
        
        advanced_page.add(debug_group)
        dialog.add(advanced_page)
        
        dialog.present()
    
    def _update_config(self, section, key, value):
        """Update configuration value"""
        if section in self.config:
            self.config[section][key] = value
            self._save_config()
    
    def _show_about_dialog(self):
        """Show about dialog"""
        
        about = Adw.AboutWindow()
        about.set_transient_for(self.window)
        
        about.set_application_name("MobaLiveCD AI")
        about.set_application_icon("org.mobatek.mobalivecd.ai")
        about.set_version(self.config.get('version', '2.0.0'))
        about.set_developer_name("Enhanced by AI")
        about.set_license_type(Gtk.License.GPL_2_0)
        about.set_website("https://github.com/wlfogle/mobalivecd-linux")
        about.set_issue_url("https://github.com/wlfogle/mobalivecd-linux/issues")
        
        about.set_comments("AI-Enhanced QEMU-based LiveCD/ISO testing tool with intelligent optimization")
        
        about.set_copyright("Copyright (C) 2024")
        
        # Credits
        about.set_developers([
            "Original MobaLiveCD Team",
            "Enhanced with AI Optimization",
            "GTK4/Libadwaita Modern Interface"
        ])
        
        about.add_credit_section("AI Features", [
            "🤖 Intelligent ISO Detection",
            "⚡ Smart Hardware Acceleration",
            "📊 Real-time Performance Monitoring", 
            "🎯 Optimal Resource Allocation",
            "🔧 Advanced QEMU Configuration"
        ])
        
        about.add_credit_section("Technologies", [
            "QEMU/KVM Virtualization",
            "GTK4 & Libadwaita UI",
            "Python 3.8+ Runtime",
            "AI-Powered Optimization"
        ])
        
        about.present()
    
    def do_shutdown(self):
        """Called when application is shutting down"""
        
        # Save window state
        if hasattr(self, 'window'):
            size = self.window.get_default_size()
            self.config['window']['width'] = size.width
            self.config['window']['height'] = size.height
            self.config['window']['maximized'] = self.window.is_maximized()
            
        self._save_config()
        Adw.Application.do_shutdown(self)

def main():
    """Main entry point"""
    
    # Set up application
    app = AIEnhancedMobaLiveCDApplication()
    
    # Handle command line and run
    return app.run(sys.argv)

if __name__ == '__main__':
    sys.exit(main())
