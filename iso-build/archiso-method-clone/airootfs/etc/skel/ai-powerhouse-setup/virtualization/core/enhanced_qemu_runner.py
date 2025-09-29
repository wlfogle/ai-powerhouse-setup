"""
AI-Enhanced QEMU Runner for MobaLiveCD Linux
Advanced virtualization engine with intelligent optimization and hardware detection
"""

import os
import subprocess
import shutil
import tempfile
import json
import re
import threading
import time
import psutil
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass

@dataclass
class SystemCapabilities:
    """System hardware capabilities"""
    cpu_cores: int
    cpu_threads: int
    memory_gb: float
    kvm_available: bool
    gpu_acceleration: bool
    nested_virtualization: bool
    cpu_flags: List[str]
    architecture: str

@dataclass
class ISOProfile:
    """ISO-specific optimization profile"""
    name: str
    category: str
    memory_min: str
    memory_recommended: str
    cpu_cores: int
    enable_3d: bool
    enable_audio: bool
    network_mode: str
    boot_priority: str
    special_flags: List[str]
    description: str

class AIEnhancedQEMURunner:
    """AI-powered QEMU runner with intelligent optimization"""
    
    def __init__(self):
        self.qemu_binary = self._find_optimal_qemu_binary()
        self.system_caps = self._analyze_system_capabilities()
        self.iso_profiles = self._load_iso_profiles()
        self.active_processes = {}
        self._init_performance_monitoring()
        
    def _find_optimal_qemu_binary(self) -> str:
        """Find the best QEMU binary for the system"""
        candidates = [
            ('qemu-system-x86_64', 10),  # Preferred for 64-bit
            ('qemu-system-i386', 8),     # Fallback for 32-bit
            ('qemu', 5),                 # Generic
            ('qemu-kvm', 9)              # KVM-specific variant
        ]
        
        available = []
        for binary, priority in candidates:
            if shutil.which(binary):
                # Check if it actually works
                try:
                    result = subprocess.run(
                        [binary, '--version'], 
                        capture_output=True, 
                        text=True, 
                        timeout=5
                    )
                    if result.returncode == 0:
                        available.append((binary, priority))
                except:
                    continue
        
        if not available:
            raise RuntimeError("No working QEMU binary found. Install qemu-system-x86 package")
        
        # Return highest priority binary
        return max(available, key=lambda x: x[1])[0]
    
    def _analyze_system_capabilities(self) -> SystemCapabilities:
        """Analyze system hardware capabilities using AI-driven detection"""
        
        # CPU Information
        cpu_info = {}
        try:
            with open('/proc/cpuinfo', 'r') as f:
                content = f.read()
                cpu_info = self._parse_cpuinfo(content)
        except:
            cpu_info = {'cores': psutil.cpu_count(logical=False), 'threads': psutil.cpu_count()}
        
        # Memory Information
        memory = psutil.virtual_memory()
        memory_gb = memory.total / (1024**3)
        
        # KVM Support
        kvm_available = (
            os.path.exists('/dev/kvm') and 
            os.access('/dev/kvm', os.R_OK | os.W_OK)
        )
        
        # GPU Acceleration Detection
        gpu_acceleration = self._detect_gpu_acceleration()
        
        # Nested Virtualization
        nested_virt = self._check_nested_virtualization()
        
        # CPU Flags
        cpu_flags = cpu_info.get('flags', [])
        
        return SystemCapabilities(
            cpu_cores=cpu_info.get('cores', 1),
            cpu_threads=cpu_info.get('threads', 1),
            memory_gb=memory_gb,
            kvm_available=kvm_available,
            gpu_acceleration=gpu_acceleration,
            nested_virtualization=nested_virt,
            cpu_flags=cpu_flags,
            architecture=os.uname().machine
        )
    
    def _parse_cpuinfo(self, content: str) -> Dict:
        """Parse /proc/cpuinfo with AI pattern recognition"""
        lines = content.strip().split('\n')
        info = {'cores': 1, 'threads': 1, 'flags': []}
        
        processor_count = 0
        core_ids = set()
        
        for line in lines:
            if ':' in line:
                key, value = line.split(':', 1)
                key = key.strip()
                value = value.strip()
                
                if key == 'processor':
                    processor_count += 1
                elif key == 'core id':
                    core_ids.add(value)
                elif key == 'flags':
                    info['flags'] = value.split()
        
        info['threads'] = processor_count
        info['cores'] = len(core_ids) if core_ids else processor_count
        
        return info
    
    def _detect_gpu_acceleration(self) -> bool:
        """Detect GPU acceleration capabilities"""
        gpu_indicators = [
            'nvidia',
            'amd',
            'intel',
            'virgl',
            'virtio-gpu'
        ]
        
        try:
            # Check lspci for GPU
            result = subprocess.run(['lspci'], capture_output=True, text=True)
            if result.returncode == 0:
                output = result.stdout.lower()
                return any(indicator in output for indicator in gpu_indicators)
        except:
            pass
        
        return False
    
    def _check_nested_virtualization(self) -> bool:
        """Check if nested virtualization is enabled"""
        try:
            # Check Intel
            if os.path.exists('/sys/module/kvm_intel/parameters/nested'):
                with open('/sys/module/kvm_intel/parameters/nested', 'r') as f:
                    return f.read().strip() in ['1', 'Y', 'y']
            
            # Check AMD
            if os.path.exists('/sys/module/kvm_amd/parameters/nested'):
                with open('/sys/module/kvm_amd/parameters/nested', 'r') as f:
                    return f.read().strip() in ['1', 'Y', 'y']
        except:
            pass
        
        return False
    
    def _load_iso_profiles(self) -> Dict[str, ISOProfile]:
        """Load AI-curated ISO optimization profiles"""
        profiles = {
            'proxmox': ISOProfile(
                name="Proxmox VE",
                category="Virtualization",
                memory_min="2G",
                memory_recommended="8G",
                cpu_cores=4,
                enable_3d=False,
                enable_audio=False,
                network_mode="virtio",
                boot_priority="d",
                special_flags=["-machine", "type=q35", "-cpu", "host,+vmx"],
                description="Enterprise virtualization platform"
            ),
            'debian': ISOProfile(
                name="Debian Live",
                category="Linux Distribution",
                memory_min="512M",
                memory_recommended="2G",
                cpu_cores=2,
                enable_3d=True,
                enable_audio=True,
                network_mode="virtio",
                boot_priority="d",
                special_flags=["-machine", "type=pc"],
                description="Stable Linux distribution"
            ),
            'systemrescue': ISOProfile(
                name="SystemRescue",
                category="Recovery",
                memory_min="1G",
                memory_recommended="4G",
                cpu_cores=2,
                enable_3d=False,
                enable_audio=False,
                network_mode="virtio",
                boot_priority="d",
                special_flags=["-machine", "type=pc"],
                description="System rescue and recovery toolkit"
            ),
            'windows': ISOProfile(
                name="Windows",
                category="Operating System",
                memory_min="2G",
                memory_recommended="8G",
                cpu_cores=2,
                enable_3d=True,
                enable_audio=True,
                network_mode="e1000",
                boot_priority="d",
                special_flags=["-machine", "type=q35"],
                description="Microsoft Windows operating system"
            ),
            'gaming': ISOProfile(
                name="Gaming Linux",
                category="Gaming",
                memory_min="4G",
                memory_recommended="8G",
                cpu_cores=4,
                enable_3d=True,
                enable_audio=True,
                network_mode="virtio",
                boot_priority="d",
                special_flags=["-machine", "type=q35", "-vga", "virtio"],
                description="Gaming-optimized Linux distribution"
            )
        }
        
        return profiles
    
    def _init_performance_monitoring(self):
        """Initialize performance monitoring subsystem"""
        self.performance_thread = threading.Thread(
            target=self._monitor_performance,
            daemon=True
        )
        self.performance_thread.start()
    
    def _monitor_performance(self):
        """Background performance monitoring"""
        while True:
            try:
                # Monitor active QEMU processes
                for pid, info in list(self.active_processes.items()):
                    try:
                        process = psutil.Process(pid)
                        if not process.is_running():
                            del self.active_processes[pid]
                            continue
                        
                        # Update performance metrics
                        cpu_percent = process.cpu_percent()
                        memory_info = process.memory_info()
                        
                        info.update({
                            'cpu_percent': cpu_percent,
                            'memory_mb': memory_info.rss / (1024*1024),
                            'status': process.status()
                        })
                        
                    except psutil.NoSuchProcess:
                        if pid in self.active_processes:
                            del self.active_processes[pid]
                
                time.sleep(5)  # Check every 5 seconds
                
            except Exception as e:
                print(f"Performance monitoring error: {e}")
                time.sleep(10)
    
    def identify_iso(self, iso_path: str) -> Tuple[str, ISOProfile]:
        """AI-powered ISO identification and profile selection"""
        iso_name = os.path.basename(iso_path).lower()
        
        # Pattern matching with AI logic
        patterns = {
            r'proxmox.*ve.*\d+': 'proxmox',
            r'debian.*live': 'debian',
            r'systemrescue': 'systemrescue',
            r'win.*\d+': 'windows',
            r'garuda.*gaming': 'gaming',
            r'fedora.*workstation': 'debian',  # Use Debian profile as base
            r'ubuntu.*desktop': 'debian',
            r'mint.*cinnamon': 'debian',
            r'rescue|recovery|repair': 'systemrescue'
        }
        
        for pattern, profile_key in patterns.items():
            if re.search(pattern, iso_name):
                return profile_key, self.iso_profiles[profile_key]
        
        # Default to Debian profile for unknown ISOs
        return 'debian', self.iso_profiles['debian']
    
    def calculate_optimal_resources(self, profile: ISOProfile) -> Dict[str, str]:
        """Calculate optimal resource allocation based on system capabilities"""
        
        # Memory calculation
        available_memory_gb = self.system_caps.memory_gb * 0.7  # Leave 30% for host
        recommended_memory = self._parse_memory_string(profile.memory_recommended)
        min_memory = self._parse_memory_string(profile.memory_min)
        
        if available_memory_gb >= recommended_memory:
            memory = profile.memory_recommended
        elif available_memory_gb >= min_memory:
            memory = f"{int(available_memory_gb)}G"
        else:
            memory = profile.memory_min
        
        # CPU calculation
        available_cores = self.system_caps.cpu_cores
        recommended_cores = min(profile.cpu_cores, max(1, available_cores // 2))
        
        return {
            'memory': memory,
            'cpu_cores': str(recommended_cores),
            'enable_kvm': str(self.system_caps.kvm_available),
            'enable_gpu': str(profile.enable_3d and self.system_caps.gpu_acceleration)
        }
    
    def _parse_memory_string(self, memory_str: str) -> float:
        """Parse memory string to GB"""
        memory_str = memory_str.upper()
        if 'G' in memory_str:
            return float(memory_str.replace('G', ''))
        elif 'M' in memory_str:
            return float(memory_str.replace('M', '')) / 1024
        return 1.0  # Default
    
    def build_optimized_command(self, iso_path: str, **user_options) -> List[str]:
        """Build AI-optimized QEMU command"""
        
        # Identify ISO and get profile
        profile_key, profile = self.identify_iso(iso_path)
        optimal_resources = self.calculate_optimal_resources(profile)
        
        # Start building command
        cmd = [self.qemu_binary]
        
        # Machine type from profile
        if profile.special_flags:
            cmd.extend(profile.special_flags)
        else:
            cmd.extend(['-machine', 'type=pc'])
        
        # Memory optimization
        memory = user_options.get('memory', optimal_resources['memory'])
        cmd.extend(['-m', memory])
        
        # CPU optimization
        cpu_cores = user_options.get('cpu_cores', optimal_resources['cpu_cores'])
        cmd.extend(['-smp', cpu_cores])
        
        # Acceleration
        if self.system_caps.kvm_available and user_options.get('enable_kvm', True):
            cmd.extend(['-accel', 'kvm'])
            cmd.extend(['-cpu', 'host'])
        else:
            cmd.extend(['-accel', 'tcg'])
        
        # Display optimization
        if profile.enable_3d and self.system_caps.gpu_acceleration:
            cmd.extend(['-vga', 'virtio'])
            cmd.extend(['-display', 'gtk,gl=on'])
        else:
            cmd.extend(['-vga', 'std'])
            cmd.extend(['-display', 'gtk'])
        
        # Audio
        if profile.enable_audio and user_options.get('enable_audio', True):
            cmd.extend(['-audiodev', 'alsa,id=audio0'])
            cmd.extend(['-device', 'AC97,audiodev=audio0'])
        
        # Network optimization
        if user_options.get('enable_network', True):
            if profile.network_mode == 'virtio':
                cmd.extend(['-netdev', 'user,id=net0'])
                cmd.extend(['-device', 'virtio-net,netdev=net0'])
            else:
                cmd.extend(['-netdev', 'user,id=net0'])
                cmd.extend(['-device', 'rtl8139,netdev=net0'])
        
        # USB and tablet for better mouse handling
        cmd.extend(['-usb', '-device', 'usb-tablet'])
        
        # Boot configuration
        cmd.extend(['-boot', profile.boot_priority])
        cmd.extend(['-cdrom', iso_path])
        
        # Performance optimizations
        cmd.extend(['-no-reboot'])
        cmd.extend(['-rtc', 'base=localtime,clock=host'])
        
        return cmd
    
    def run_optimized_iso(self, iso_path: str, **options) -> int:
        """Run ISO with AI optimization"""
        
        if not os.path.exists(iso_path):
            raise FileNotFoundError(f"ISO file not found: {iso_path}")
        
        # Build optimized command
        cmd = self.build_optimized_command(iso_path, **options)
        
        # Log command for debugging
        print(f"🚀 AI-Optimized QEMU Command:")
        print(f"   {' '.join(cmd)}")
        
        # Get profile info for display
        profile_key, profile = self.identify_iso(iso_path)
        print(f"📊 Detected: {profile.name} ({profile.category})")
        print(f"💡 {profile.description}")
        
        try:
            # Launch QEMU
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE if options.get('quiet', True) else None,
                stderr=subprocess.PIPE
            )
            
            # Give QEMU time to start
            time.sleep(2)
            
            if process.poll() is not None:
                # Process terminated - error occurred
                stdout, stderr = process.communicate()
                error_msg = stderr.decode('utf-8') if stderr else "QEMU failed to start"
                raise RuntimeError(f"QEMU startup failed: {error_msg}")
            
            # Add to monitoring
            self.active_processes[process.pid] = {
                'iso_path': iso_path,
                'profile': profile_key,
                'start_time': time.time(),
                'command': cmd
            }
            
            print(f"✅ QEMU started successfully (PID: {process.pid})")
            return process.pid
            
        except FileNotFoundError:
            raise RuntimeError(f"QEMU binary '{self.qemu_binary}' not found")
        except Exception as e:
            raise RuntimeError(f"Failed to start QEMU: {e}")
    
    def get_system_diagnostics(self) -> Dict:
        """Get comprehensive system diagnostics"""
        return {
            'system_capabilities': {
                'cpu_cores': self.system_caps.cpu_cores,
                'cpu_threads': self.system_caps.cpu_threads,
                'memory_gb': round(self.system_caps.memory_gb, 2),
                'kvm_available': self.system_caps.kvm_available,
                'gpu_acceleration': self.system_caps.gpu_acceleration,
                'nested_virtualization': self.system_caps.nested_virtualization,
                'architecture': self.system_caps.architecture
            },
            'qemu_info': {
                'binary': self.qemu_binary,
                'version': self._get_qemu_version()
            },
            'active_vms': len(self.active_processes),
            'performance': {
                pid: info for pid, info in self.active_processes.items()
            }
        }
    
    def _get_qemu_version(self) -> str:
        """Get QEMU version"""
        try:
            result = subprocess.run(
                [self.qemu_binary, '--version'],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                return result.stdout.strip().split('\n')[0]
        except:
            pass
        return 'Unknown'
    
    def kill_vm(self, pid: int) -> bool:
        """Gracefully terminate a VM"""
        try:
            process = psutil.Process(pid)
            process.terminate()
            
            # Wait up to 10 seconds for graceful shutdown
            try:
                process.wait(timeout=10)
            except psutil.TimeoutExpired:
                # Force kill if needed
                process.kill()
            
            if pid in self.active_processes:
                del self.active_processes[pid]
            
            return True
        except psutil.NoSuchProcess:
            return True
        except Exception as e:
            print(f"Error killing VM {pid}: {e}")
            return False
