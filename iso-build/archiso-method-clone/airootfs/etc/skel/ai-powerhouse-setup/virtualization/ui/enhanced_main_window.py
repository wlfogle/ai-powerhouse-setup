"""
AI-Enhanced Main Window for MobaLiveCD Linux
Modern GTK4/Libadwaita interface with intelligent features
"""

import os
import gi
import json
import threading
import time
from pathlib import Path
from typing import Optional, Dict, List

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Adw, Gio, GLib, GdkPixbuf
from core.enhanced_qemu_runner import AIEnhancedQEMURunner

@Gtk.Template(resource_path='/org/mobatek/mobalivecd/ui/enhanced_main_window.ui')
class EnhancedMobaLiveCDWindow(Adw.ApplicationWindow):
    """AI-Enhanced main application window"""
    
    __gtype_name__ = 'EnhancedMobaLiveCDWindow'
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        
        # Initialize AI-enhanced QEMU runner
        try:
            self.qemu_runner = AIEnhancedQEMURunner()
        except Exception as e:
            self._show_error_dialog("QEMU Initialization Error", str(e))
            return
        
        # UI State
        self.current_iso_path = None
        self.running_vms = {}
        
        # Setup UI
        self._setup_ui()
        self._setup_styling()
        self._start_performance_monitoring()
        
        # Load system information
        self._load_system_info()
    
    def _setup_ui(self):
        """Setup the enhanced UI components"""
        
        # Main container
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.set_content(self.main_box)
        
        # Header bar with modern styling
        self._setup_header_bar()
        
        # Main content area
        self._setup_main_content()
        
        # Status bar
        self._setup_status_bar()
        
    def _setup_header_bar(self):
        """Setup modern header bar"""
        
        header_bar = Adw.HeaderBar()
        header_bar.set_title_widget(Adw.WindowTitle(
            title="MobaLiveCD AI",
            subtitle="Intelligent ISO Virtualization"
        ))
        
        # Menu button
        menu_button = Gtk.MenuButton()
        menu_button.set_icon_name("open-menu-symbolic")
        menu_button.set_tooltip_text("Application Menu")
        
        # Create menu model
        menu = Gio.Menu()
        menu.append("System Diagnostics", "app.diagnostics")
        menu.append("Preferences", "app.preferences")
        menu.append("About", "app.about")
        
        menu_button.set_menu_model(menu)
        header_bar.pack_end(menu_button)
        
        # System info indicator
        self.system_indicator = Gtk.Button()
        self.system_indicator.set_icon_name("computer-symbolic")
        self.system_indicator.connect("clicked", self._on_system_info_clicked)
        header_bar.pack_start(self.system_indicator)
        
        self.set_titlebar(header_bar)
    
    def _setup_main_content(self):
        """Setup main content area with modern layout"""
        
        # Main paned view
        self.paned = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL)
        self.main_box.append(self.paned)
        
        # Left panel - ISO selection and info
        self._setup_left_panel()
        
        # Right panel - VM management and monitoring
        self._setup_right_panel()
        
    def _setup_left_panel(self):
        """Setup left panel for ISO selection"""
        
        left_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        left_box.set_margin_start(12)
        left_box.set_margin_end(12)
        left_box.set_margin_top(12)
        left_box.set_margin_bottom(12)
        left_box.set_size_request(400, -1)
        
        # ISO Selection Group
        iso_group = Adw.PreferencesGroup()
        iso_group.set_title("🎯 ISO Selection")
        iso_group.set_description("Select and configure your ISO image")
        
        # ISO file row
        self.iso_row = Adw.ActionRow()
        self.iso_row.set_title("ISO Image")
        self.iso_row.set_subtitle("No ISO selected")
        
        # Browse button
        browse_button = Gtk.Button()
        browse_button.set_icon_name("folder-open-symbolic")
        browse_button.set_tooltip_text("Browse for ISO file")
        browse_button.connect("clicked", self._on_browse_clicked)
        browse_button.add_css_class("flat")
        self.iso_row.add_suffix(browse_button)
        
        # Drag and drop
        drop_target = Gtk.DropTarget.new(Gio.File.__gtype__, Gtk.DropAction.COPY)
        drop_target.connect("drop", self._on_iso_dropped)
        self.iso_row.add_controller(drop_target)
        
        iso_group.add(self.iso_row)
        left_box.append(iso_group)
        
        # AI Detection Results
        self.detection_group = Adw.PreferencesGroup()
        self.detection_group.set_title("🤖 AI Detection")
        self.detection_group.set_description("Intelligent ISO analysis and optimization")
        self.detection_group.set_visible(False)
        
        # Detection info rows (will be populated dynamically)
        self.detection_rows = {}
        
        left_box.append(self.detection_group)
        
        # Configuration Group
        config_group = Adw.PreferencesGroup()
        config_group.set_title("⚙️ Configuration")
        config_group.set_description("Customize virtualization settings")
        
        # Memory configuration
        self.memory_row = Adw.SpinRow()
        self.memory_row.set_title("Memory (GB)")
        self.memory_row.set_subtitle("RAM allocated to virtual machine")
        adjustment = Gtk.Adjustment(value=2, lower=0.5, upper=64, step_increment=0.5)
        self.memory_row.set_adjustment(adjustment)
        config_group.add(self.memory_row)
        
        # CPU cores
        self.cpu_row = Adw.SpinRow()
        self.cpu_row.set_title("CPU Cores")
        self.cpu_row.set_subtitle("Number of CPU cores")
        cpu_adjustment = Gtk.Adjustment(value=2, lower=1, upper=16, step_increment=1)
        self.cpu_row.set_adjustment(cpu_adjustment)
        config_group.add(self.cpu_row)
        
        # Enable KVM
        self.kvm_row = Adw.SwitchRow()
        self.kvm_row.set_title("Hardware Acceleration")
        self.kvm_row.set_subtitle("Use KVM for better performance")
        config_group.add(self.kvm_row)
        
        # Enable 3D
        self.gpu_row = Adw.SwitchRow()
        self.gpu_row.set_title("3D Acceleration")
        self.gpu_row.set_subtitle("Enable GPU acceleration")
        config_group.add(self.gpu_row)
        
        # Enable Audio
        self.audio_row = Adw.SwitchRow()
        self.audio_row.set_title("Audio Support")
        self.audio_row.set_subtitle("Enable audio devices")
        config_group.add(self.audio_row)
        
        # Enable Network
        self.network_row = Adw.SwitchRow()
        self.network_row.set_title("Network Access")
        self.network_row.set_subtitle("Enable network connectivity")
        self.network_row.set_active(True)
        config_group.add(self.network_row)
        
        left_box.append(config_group)
        
        # Action buttons
        self._setup_action_buttons(left_box)
        
        # Add to paned
        self.paned.set_start_child(left_box)
    
    def _setup_action_buttons(self, parent_box):
        """Setup action buttons"""
        
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        button_box.set_homogeneous(True)
        button_box.set_margin_top(24)
        
        # Run button
        self.run_button = Gtk.Button()
        self.run_button.set_label("🚀 Launch VM")
        self.run_button.add_css_class("suggested-action")
        self.run_button.add_css_class("pill")
        self.run_button.set_sensitive(False)
        self.run_button.connect("clicked", self._on_run_clicked)
        button_box.append(self.run_button)
        
        # Quick launch button (uses AI optimization)
        self.quick_button = Gtk.Button()
        self.quick_button.set_label("⚡ Quick Launch")
        self.quick_button.add_css_class("pill")
        self.quick_button.set_sensitive(False)
        self.quick_button.set_tooltip_text("Launch with AI-optimized settings")
        self.quick_button.connect("clicked", self._on_quick_launch_clicked)
        button_box.append(self.quick_button)
        
        parent_box.append(button_box)
    
    def _setup_right_panel(self):
        """Setup right panel for VM management"""
        
        right_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        right_box.set_margin_start(12)
        right_box.set_margin_end(12)
        right_box.set_margin_top(12)
        right_box.set_margin_bottom(12)
        
        # Running VMs Group
        self.vm_group = Adw.PreferencesGroup()
        self.vm_group.set_title("💻 Running VMs")
        self.vm_group.set_description("Manage active virtual machines")
        
        # VM list (will be populated dynamically)
        self.vm_list_box = Gtk.ListBox()
        self.vm_list_box.add_css_class("boxed-list")
        self.vm_group.add(self.vm_list_box)
        
        right_box.append(self.vm_group)
        
        # System Monitor Group
        monitor_group = Adw.PreferencesGroup()
        monitor_group.set_title("📊 System Monitor")
        monitor_group.set_description("Real-time system performance")
        
        # CPU usage
        self.cpu_usage_row = Adw.ActionRow()
        self.cpu_usage_row.set_title("CPU Usage")
        self.cpu_usage_bar = Gtk.ProgressBar()
        self.cpu_usage_bar.set_size_request(200, -1)
        self.cpu_usage_row.add_suffix(self.cpu_usage_bar)
        monitor_group.add(self.cpu_usage_row)
        
        # Memory usage
        self.memory_usage_row = Adw.ActionRow()
        self.memory_usage_row.set_title("Memory Usage")
        self.memory_usage_bar = Gtk.ProgressBar()
        self.memory_usage_bar.set_size_request(200, -1)
        self.memory_usage_row.add_suffix(self.memory_usage_bar)
        monitor_group.add(self.memory_usage_row)
        
        right_box.append(monitor_group)
        
        # Add to paned
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_child(right_box)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.paned.set_end_child(scrolled)
    
    def _setup_status_bar(self):
        """Setup status bar"""
        
        status_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        status_box.set_margin_start(12)
        status_box.set_margin_end(12)
        status_box.set_margin_top(6)
        status_box.set_margin_bottom(6)
        status_box.add_css_class("toolbar")
        
        # Status label
        self.status_label = Gtk.Label()
        self.status_label.set_text("Ready")
        self.status_label.set_halign(Gtk.Align.START)
        status_box.append(self.status_label)
        
        # Spacer
        spacer = Gtk.Box()
        spacer.set_hexpand(True)
        status_box.append(spacer)
        
        # System capabilities indicator
        self.caps_label = Gtk.Label()
        self.caps_label.set_markup("<small>System: Loading...</small>")
        status_box.append(self.caps_label)
        
        self.main_box.append(status_box)
    
    def _setup_styling(self):
        """Apply modern CSS styling"""
        
        css_provider = Gtk.CssProvider()
        css_content = """
        .performance-good { background-color: alpha(@success_color, 0.1); }
        .performance-warning { background-color: alpha(@warning_color, 0.1); }
        .performance-critical { background-color: alpha(@error_color, 0.1); }
        
        .vm-row {
            padding: 8px;
            margin: 4px;
            border-radius: 8px;
        }
        
        .pill {
            border-radius: 20px;
            padding: 8px 16px;
        }
        
        .ai-detection {
            background: linear-gradient(45deg, alpha(@accent_color, 0.1), alpha(@accent_color, 0.05));
            border-radius: 8px;
            padding: 8px;
        }
        """
        css_provider.load_from_string(css_content)
        
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
    
    def _load_system_info(self):
        """Load system information asynchronously"""
        
        def load_info():
            try:
                diagnostics = self.qemu_runner.get_system_diagnostics()
                GLib.idle_add(self._update_system_info, diagnostics)
            except Exception as e:
                GLib.idle_add(self._update_system_info, None, str(e))
        
        thread = threading.Thread(target=load_info, daemon=True)
        thread.start()
    
    def _update_system_info(self, diagnostics, error=None):
        """Update system information in UI"""
        
        if error:
            self.caps_label.set_markup(f"<small>System: Error - {error}</small>")
            return
        
        if not diagnostics:
            return
        
        caps = diagnostics['system_capabilities']
        qemu_info = diagnostics['qemu_info']
        
        # Update capabilities label
        kvm_status = "✅" if caps['kvm_available'] else "❌"
        gpu_status = "🎮" if caps['gpu_acceleration'] else "🚫"
        
        caps_text = (f"<small>CPU: {caps['cpu_cores']}c/{caps['cpu_threads']}t | "
                    f"RAM: {caps['memory_gb']:.1f}GB | "
                    f"KVM: {kvm_status} | GPU: {gpu_status}</small>")
        
        self.caps_label.set_markup(caps_text)
        
        # Update system indicator tooltip
        tooltip_text = (f"QEMU: {qemu_info['binary']}\n"
                       f"Version: {qemu_info['version']}\n"
                       f"Architecture: {caps['architecture']}\n"
                       f"KVM Available: {caps['kvm_available']}\n"
                       f"GPU Acceleration: {caps['gpu_acceleration']}")
        
        self.system_indicator.set_tooltip_text(tooltip_text)
        
        # Set default values based on system capabilities
        self.kvm_row.set_active(caps['kvm_available'])
        self.gpu_row.set_active(caps['gpu_acceleration'])
        
        # Adjust limits based on system
        max_memory = max(1, int(caps['memory_gb'] * 0.8))  # 80% of system memory
        self.memory_row.get_adjustment().set_upper(max_memory)
        
        max_cpu = caps['cpu_cores']
        self.cpu_row.get_adjustment().set_upper(max_cpu)
    
    def _start_performance_monitoring(self):
        """Start background performance monitoring"""
        
        def monitor_performance():
            while True:
                try:
                    import psutil
                    
                    # Update system metrics
                    cpu_percent = psutil.cpu_percent(interval=1)
                    memory = psutil.virtual_memory()
                    
                    GLib.idle_add(self._update_performance_display, cpu_percent, memory.percent)
                    
                    # Update VM list
                    diagnostics = self.qemu_runner.get_system_diagnostics()
                    GLib.idle_add(self._update_vm_list, diagnostics.get('performance', {}))
                    
                    time.sleep(5)
                    
                except Exception as e:
                    print(f"Performance monitoring error: {e}")
                    time.sleep(10)
        
        thread = threading.Thread(target=monitor_performance, daemon=True)
        thread.start()
    
    def _update_performance_display(self, cpu_percent, memory_percent):
        """Update performance displays"""
        
        # Update CPU usage
        self.cpu_usage_bar.set_fraction(cpu_percent / 100.0)
        self.cpu_usage_row.set_subtitle(f"{cpu_percent:.1f}%")
        
        # Update memory usage  
        self.memory_usage_bar.set_fraction(memory_percent / 100.0)
        self.memory_usage_row.set_subtitle(f"{memory_percent:.1f}%")
        
        # Color coding
        cpu_class = "performance-good" if cpu_percent < 70 else "performance-warning" if cpu_percent < 90 else "performance-critical"
        memory_class = "performance-good" if memory_percent < 70 else "performance-warning" if memory_percent < 90 else "performance-critical"
        
        self.cpu_usage_row.remove_css_class("performance-good")
        self.cpu_usage_row.remove_css_class("performance-warning") 
        self.cpu_usage_row.remove_css_class("performance-critical")
        self.cpu_usage_row.add_css_class(cpu_class)
        
        self.memory_usage_row.remove_css_class("performance-good")
        self.memory_usage_row.remove_css_class("performance-warning")
        self.memory_usage_row.remove_css_class("performance-critical")
        self.memory_usage_row.add_css_class(memory_class)
    
    def _update_vm_list(self, performance_data):
        """Update running VM list"""
        
        # Clear existing VM rows
        child = self.vm_list_box.get_first_child()
        while child:
            next_child = child.get_next_sibling()
            self.vm_list_box.remove(child)
            child = next_child
        
        # Add current VMs
        for pid, vm_info in performance_data.items():
            self._add_vm_row(int(pid), vm_info)
    
    def _add_vm_row(self, pid, vm_info):
        """Add a VM row to the list"""
        
        row = Adw.ActionRow()
        row.add_css_class("vm-row")
        
        # VM title
        iso_name = os.path.basename(vm_info.get('iso_path', 'Unknown'))
        profile = vm_info.get('profile', 'unknown').title()
        row.set_title(f"{profile} VM")
        
        # Subtitle with performance info
        cpu_usage = vm_info.get('cpu_percent', 0)
        memory_mb = vm_info.get('memory_mb', 0)
        status = vm_info.get('status', 'unknown')
        
        subtitle = f"PID: {pid} | CPU: {cpu_usage:.1f}% | RAM: {memory_mb:.0f}MB | Status: {status}"
        row.set_subtitle(subtitle)
        
        # Kill button
        kill_button = Gtk.Button()
        kill_button.set_icon_name("process-stop-symbolic")
        kill_button.set_tooltip_text("Terminate VM")
        kill_button.add_css_class("destructive-action")
        kill_button.add_css_class("circular")
        kill_button.connect("clicked", lambda btn, p=pid: self._on_kill_vm_clicked(p))
        row.add_suffix(kill_button)
        
        self.vm_list_box.append(row)
    
    # Event Handlers
    def _on_browse_clicked(self, button):
        """Handle browse button click"""
        
        file_dialog = Gtk.FileDialog()
        file_dialog.set_title("Select ISO Image")
        
        # Set up file filter
        iso_filter = Gtk.FileFilter()
        iso_filter.set_name("ISO Images")
        iso_filter.add_pattern("*.iso")
        iso_filter.add_pattern("*.ISO")
        
        filter_list = Gio.ListStore()
        filter_list.append(iso_filter)
        file_dialog.set_filters(filter_list)
        
        file_dialog.open(self, None, self._on_file_selected)
    
    def _on_file_selected(self, dialog, result):
        """Handle file selection"""
        
        try:
            file = dialog.open_finish(result)
            if file:
                self.load_iso_file(file.get_path())
        except Exception as e:
            self._show_error_dialog("File Selection Error", str(e))
    
    def _on_iso_dropped(self, drop_target, file, x, y):
        """Handle ISO file drop"""
        
        if file and file.get_path():
            self.load_iso_file(file.get_path())
            return True
        return False
    
    def load_iso_file(self, iso_path):
        """Load and analyze ISO file"""
        
        if not os.path.exists(iso_path):
            self._show_error_dialog("File Error", f"ISO file not found: {iso_path}")
            return
        
        self.current_iso_path = iso_path
        
        # Update UI
        iso_name = os.path.basename(iso_path)
        self.iso_row.set_subtitle(iso_name)
        
        # Enable buttons
        self.run_button.set_sensitive(True)
        self.quick_button.set_sensitive(True)
        
        # Run AI detection
        self._run_ai_detection(iso_path)
        
        self.status_label.set_text(f"Loaded: {iso_name}")
    
    def _run_ai_detection(self, iso_path):
        """Run AI detection on ISO"""
        
        def detect():
            try:
                profile_key, profile = self.qemu_runner.identify_iso(iso_path)
                optimal_resources = self.qemu_runner.calculate_optimal_resources(profile)
                GLib.idle_add(self._show_ai_detection_results, profile, optimal_resources)
            except Exception as e:
                GLib.idle_add(self._show_error_dialog, "AI Detection Error", str(e))
        
        thread = threading.Thread(target=detect, daemon=True)
        thread.start()
    
    def _show_ai_detection_results(self, profile, optimal_resources):
        """Show AI detection results"""
        
        # Clear existing detection rows
        for row in self.detection_rows.values():
            self.detection_group.remove(row)
        self.detection_rows.clear()
        
        # Add detection results
        detection_info = [
            ("Detected Type", f"{profile.name} ({profile.category})"),
            ("Description", profile.description),
            ("Recommended Memory", optimal_resources['memory']),
            ("Recommended CPU Cores", optimal_resources['cpu_cores']),
            ("KVM Available", "Yes" if optimal_resources['enable_kvm'] == 'True' else "No"),
            ("GPU Acceleration", "Yes" if optimal_resources['enable_gpu'] == 'True' else "No")
        ]
        
        for title, value in detection_info:
            row = Adw.ActionRow()
            row.set_title(title)
            row.set_subtitle(str(value))
            self.detection_group.add(row)
            self.detection_rows[title] = row
        
        self.detection_group.set_visible(True)
        
        # Update configuration with optimal values
        memory_gb = float(optimal_resources['memory'].replace('G', '').replace('M', '0.001'))
        self.memory_row.set_value(memory_gb)
        self.cpu_row.set_value(int(optimal_resources['cpu_cores']))
    
    def _on_run_clicked(self, button):
        """Handle run button click"""
        
        if not self.current_iso_path:
            return
        
        options = self._get_vm_options()
        self._launch_vm(options)
    
    def _on_quick_launch_clicked(self, button):
        """Handle quick launch button click"""
        
        if not self.current_iso_path:
            return
        
        # Use AI-optimized settings
        options = {'use_ai_optimization': True}
        self._launch_vm(options)
    
    def _get_vm_options(self):
        """Get VM configuration options from UI"""
        
        return {
            'memory': f"{int(self.memory_row.get_value())}G",
            'cpu_cores': str(int(self.cpu_row.get_value())),
            'enable_kvm': self.kvm_row.get_active(),
            'enable_gpu': self.gpu_row.get_active(),
            'enable_audio': self.audio_row.get_active(),
            'enable_network': self.network_row.get_active()
        }
    
    def _launch_vm(self, options):
        """Launch VM with specified options"""
        
        def launch():
            try:
                pid = self.qemu_runner.run_optimized_iso(self.current_iso_path, **options)
                GLib.idle_add(self._on_vm_launched, pid)
            except Exception as e:
                GLib.idle_add(self._show_error_dialog, "VM Launch Error", str(e))
        
        thread = threading.Thread(target=launch, daemon=True)
        thread.start()
        
        self.status_label.set_text("Launching VM...")
    
    def _on_vm_launched(self, pid):
        """Handle successful VM launch"""
        
        self.status_label.set_text(f"VM launched successfully (PID: {pid})")
        
        # Show success toast
        toast = Adw.Toast()
        toast.set_title(f"🚀 Virtual machine started (PID: {pid})")
        toast.set_timeout(3)
        
        if hasattr(self, 'toast_overlay'):
            self.toast_overlay.add_toast(toast)
    
    def _on_kill_vm_clicked(self, pid):
        """Handle VM termination"""
        
        def kill_vm():
            try:
                success = self.qemu_runner.kill_vm(pid)
                GLib.idle_add(self._on_vm_killed, pid, success)
            except Exception as e:
                GLib.idle_add(self._show_error_dialog, "VM Kill Error", str(e))
        
        thread = threading.Thread(target=kill_vm, daemon=True)
        thread.start()
    
    def _on_vm_killed(self, pid, success):
        """Handle VM termination result"""
        
        if success:
            self.status_label.set_text(f"VM {pid} terminated")
            
            toast = Adw.Toast()
            toast.set_title(f"VM {pid} terminated successfully")
            toast.set_timeout(2)
            
            if hasattr(self, 'toast_overlay'):
                self.toast_overlay.add_toast(toast)
        else:
            self._show_error_dialog("VM Termination", f"Failed to terminate VM {pid}")
    
    def _on_system_info_clicked(self, button):
        """Handle system info button click"""
        
        # Show system diagnostics dialog
        self._show_system_diagnostics()
    
    def _show_system_diagnostics(self):
        """Show system diagnostics dialog"""
        
        def get_diagnostics():
            try:
                diagnostics = self.qemu_runner.get_system_diagnostics()
                GLib.idle_add(self._display_diagnostics_dialog, diagnostics)
            except Exception as e:
                GLib.idle_add(self._show_error_dialog, "Diagnostics Error", str(e))
        
        thread = threading.Thread(target=get_diagnostics, daemon=True)
        thread.start()
    
    def _display_diagnostics_dialog(self, diagnostics):
        """Display diagnostics in a dialog"""
        
        dialog = Adw.MessageDialog(
            transient_for=self,
            heading="🔍 System Diagnostics"
        )
        
        # Format diagnostics text
        caps = diagnostics['system_capabilities']
        qemu_info = diagnostics['qemu_info']
        
        body_text = f"""**System Information:**
• CPU: {caps['cpu_cores']} cores / {caps['cpu_threads']} threads
• Memory: {caps['memory_gb']:.2f} GB
• Architecture: {caps['architecture']}
• KVM Available: {'✅ Yes' if caps['kvm_available'] else '❌ No'}
• GPU Acceleration: {'✅ Yes' if caps['gpu_acceleration'] else '❌ No'}
• Nested Virtualization: {'✅ Yes' if caps['nested_virtualization'] else '❌ No'}

**QEMU Information:**
• Binary: {qemu_info['binary']}
• Version: {qemu_info['version']}

**Active VMs:** {diagnostics['active_vms']}"""
        
        dialog.set_body(body_text)
        dialog.add_response("close", "Close")
        dialog.set_default_response("close")
        
        dialog.present()
    
    def _show_error_dialog(self, title, message):
        """Show error dialog"""
        
        dialog = Adw.MessageDialog(
            transient_for=self,
            heading=title
        )
        dialog.set_body(message)
        dialog.add_response("close", "Close")
        dialog.set_default_response("close")
        dialog.set_response_appearance("close", Adw.ResponseAppearance.DESTRUCTIVE)
        
        dialog.present()
