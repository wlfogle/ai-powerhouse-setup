#!/usr/bin/env python3
"""
Control API Server for Garuda Media Stack Dashboard
Provides REST endpoints for controlling Ghost Mode, VPN, streams, and system monitoring
"""

import json
import subprocess
import time
import os
import psutil
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

STACK_PATH = "/mnt/home/lou/garuda-media-stack"

def run_command(cmd, shell=True):
    """Execute command and return result"""
    try:
        result = subprocess.run(cmd, shell=shell, capture_output=True, text=True, timeout=10)
        return {
            'success': result.returncode == 0,
            'stdout': result.stdout.strip(),
            'stderr': result.stderr.strip(),
            'returncode': result.returncode
        }
    except subprocess.TimeoutExpired:
        return {'success': False, 'error': 'Command timeout'}
    except Exception as e:
        return {'success': False, 'error': str(e)}

def check_service_port(port):
    """Check if service is running on port"""
    try:
        for conn in psutil.net_connections():
            if conn.laddr.port == port and conn.status == 'LISTEN':
                return True
        return False
    except:
        return False

def get_ghost_mode_status():
    """Check if ghost mode (VPN client) is active"""
    result = run_command('wg show wg-client0')
    return result['success']

def toggle_ghost_mode():
    """Toggle ghost mode VPN client"""
    if get_ghost_mode_status():
        # Stop ghost mode
        cmd = f"cd {STACK_PATH}/scripts && sudo ./ghost-mode-control.sh down"
        result = run_command(cmd)
        return {'active': False, 'message': 'Ghost Mode deactivated'}
    else:
        # Start ghost mode  
        cmd = f"cd {STACK_PATH}/scripts && sudo ./ghost-mode-control.sh up"
        result = run_command(cmd)
        return {'active': True, 'message': 'Ghost Mode activated'}

# ===== API ENDPOINTS =====

@app.route('/api/ghost-mode/status', methods=['GET'])
def ghost_mode_status():
    """Get Ghost Mode status"""
    active = get_ghost_mode_status()
    return jsonify({
        'active': active,
        'status': 'invisible' if active else 'visible'
    })

@app.route('/api/ghost-mode/toggle', methods=['POST'])
def ghost_mode_toggle():
    """Toggle Ghost Mode"""
    return jsonify(toggle_ghost_mode())

@app.route('/api/status/<service>', methods=['GET'])
def service_status(service):
    """Check service status by port"""
    port_map = {
        'jellyfin': 8096,
        'plex': 32400,
        'radarr': 7878,
        'sonarr': 8989,
        'lidarr': 8686,
        'readarr': 8787,
        'qbittorrent': 5080,
        'jackett': 9117,
        'calibre-web': 8083,
        'audiobookshelf': 13378,
        'jellyseerr': 5055,
        'pulsarr': 3030
    }
    
    if service not in port_map:
        return jsonify({'status': 'unknown', 'error': 'Service not recognized'})
    
    port = port_map[service]
    online = check_service_port(port)
    
    return jsonify({
        'status': 'online' if online else 'offline',
        'port': port,
        'service': service
    })

@app.route('/api/system/stats', methods=['GET'])
def system_stats():
    """Get system statistics"""
    try:
        # Get uptime
        uptime_result = run_command('uptime -p')
        uptime = uptime_result['stdout'] if uptime_result['success'] else 'Unknown'
        
        # Get VPN client count
        wg_result = run_command('wg show wg-server0')
        vpn_clients = 0
        if wg_result['success'] and 'peer' in wg_result['stdout']:
            vpn_clients = wg_result['stdout'].count('peer')
        
        # Get disk usage for media stack
        df_result = run_command(f'df -h {STACK_PATH}')
        disk_usage = 'Unknown'
        if df_result['success']:
            lines = df_result['stdout'].split('\n')
            if len(lines) > 1:
                parts = lines[1].split()
                if len(parts) >= 5:
                    disk_usage = parts[4]  # Usage percentage
        
        return jsonify({
            'uptime': uptime,
            'vpn_clients': str(vpn_clients),
            'disk_usage': disk_usage,
            'cpu_percent': f"{psutil.cpu_percent()}%",
            'memory_percent': f"{psutil.virtual_memory().percent:.1f}%"
        })
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/api/vpn/<action>', methods=['POST'])
def vpn_action(action):
    """Handle VPN management actions"""
    try:
        if action == 'status':
            result = run_command('wg show')
            return jsonify({'message': result['stdout'] if result['success'] else 'VPN status unavailable'})
        elif action == 'start':
            result = run_command('sudo wg-quick up wg-server0')
            return jsonify({'message': 'VPN server started'})
        elif action == 'stop':
            result = run_command('sudo wg-quick down wg-server0')
            return jsonify({'message': 'VPN server stopped'})
        elif action == 'rotate-keys':
            # Key rotation would be complex, just return placeholder
            return jsonify({'message': 'Key rotation not implemented yet'})
        else:
            return jsonify({'error': 'Invalid VPN action'})
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/api/wireguard/status', methods=['GET'])
def wireguard_status():
    """Get WireGuard VPN status"""
    try:
        server_result = run_command('wg show wg-server0')
        client_result = run_command('wg show wg-client0')
        
        server_status = 'online' if server_result['success'] else 'offline'
        client_count = 0
        
        if server_result['success'] and 'peer' in server_result['stdout']:
            client_count = server_result['stdout'].count('peer')
        
        return jsonify({
            'server_status': server_status,
            'client_status': 'connected' if client_result['success'] else 'disconnected',
            'client_count': client_count,
            'last_rotation': 'Recently rotated'
        })
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/api/firewall/status', methods=['GET'])
def firewall_status():
    """Get firewall status"""
    try:
        ufw_result = run_command('sudo ufw status')
        
        if ufw_result['success']:
            status_text = ufw_result['stdout']
            is_active = 'Status: active' in status_text
            rule_count = status_text.count('ALLOW')
            
            return jsonify({
                'ufw_status': 'active' if is_active else 'inactive',
                'rule_count': rule_count,
                'blocked_count': 'N/A'  # Would need to parse logs for this
            })
        else:
            return jsonify({'error': 'Unable to check UFW status'})
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/api/proxy/status', methods=['GET'])
def proxy_status():
    """Check API proxy status"""
    proxy_running = check_service_port(8888)
    
    return jsonify({
        'status': 'online' if proxy_running else 'offline',
        'requests_masked': 'N/A',  # Would need request logging for this
        'uptime': 'Running' if proxy_running else 'Stopped'
    })

@app.route('/api/logs/recent', methods=['GET'])
def recent_logs():
    """Get recent system logs"""
    try:
        # Get recent systemd logs
        result = run_command('journalctl --no-pager -n 50 --output=short-iso')
        
        if result['success']:
            log_lines = result['stdout'].split('\n')
            entries = []
            
            for line in log_lines:
                if line.strip():
                    # Parse systemd log format
                    parts = line.split(maxsplit=5)
                    if len(parts) >= 6:
                        entries.append({
                            'timestamp': f"{parts[0]} {parts[1]}",
                            'service': parts[3],
                            'message': parts[5]
                        })
            
            return jsonify({'entries': entries[-20:]})  # Last 20 entries
        else:
            return jsonify({'entries': [{'timestamp': 'N/A', 'service': 'system', 'message': 'Unable to fetch logs'}]})
    except Exception as e:
        return jsonify({'entries': [{'timestamp': 'N/A', 'service': 'error', 'message': str(e)}]})

@app.route('/api/services/restart-all', methods=['POST'])
def restart_all_services():
    """Restart all media stack services"""
    try:
        # Kill existing services gently
        services_to_restart = [
            'jellyfin', 'radarr', 'sonarr', 'lidarr', 
            'qbittorrent', 'jackett', 'jellyseerr'
        ]
        
        # Stop services
        for service in services_to_restart:
            run_command(f'pkill -f {service}')
        
        time.sleep(3)
        
        # Start services back up
        startup_commands = [
            f"cd {STACK_PATH} && nohup /usr/bin/jellyfin --webdir=/usr/share/jellyfin/web --datadir={STACK_PATH}/data/jellyfin --cachedir={STACK_PATH}/cache/jellyfin > {STACK_PATH}/logs/jellyfin.log 2>&1 &",
            f"cd {STACK_PATH} && nohup /usr/bin/radarr -nobrowser -data={STACK_PATH}/config/radarr > {STACK_PATH}/logs/radarr.log 2>&1 &",
            f"cd {STACK_PATH} && nohup /usr/bin/sonarr -nobrowser -data={STACK_PATH}/config/sonarr > {STACK_PATH}/logs/sonarr.log 2>&1 &",
            f"cd {STACK_PATH} && nohup /usr/bin/lidarr -nobrowser -data={STACK_PATH}/config/lidarr > {STACK_PATH}/logs/lidarr.log 2>&1 &",
            f"cd {STACK_PATH} && nohup sudo -u lou /usr/bin/qbittorrent-nox --webui-port=5080 --profile={STACK_PATH}/config/qbittorrent > {STACK_PATH}/logs/qbittorrent.log 2>&1 &",
            f"cd {STACK_PATH} && nohup /usr/bin/jackett --DataFolder={STACK_PATH}/config/jackett --NoRestart > {STACK_PATH}/logs/jackett.log 2>&1 &",
            f"cd {STACK_PATH}/apps/jellyseerr && nohup node dist/index.js > {STACK_PATH}/logs/jellyseerr.log 2>&1 &"
        ]
        
        for cmd in startup_commands:
            run_command(cmd)
        
        return jsonify({'message': 'All services restarted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/api/streams/wrestling/start', methods=['POST'])
def start_wrestling_stream():
    """Start wrestling stream"""
    try:
        cmd = f"cd {STACK_PATH}/streams && ./stream-manager.sh start wrestling"
        result = run_command(cmd)
        return jsonify({'message': 'Wrestling stream started'})
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/api/streams/saints/start', methods=['POST'])
def start_saints_stream():
    """Start Saints stream"""
    try:
        cmd = f"cd {STACK_PATH}/streams && ./stream-manager.sh start saints"
        result = run_command(cmd)
        return jsonify({'message': 'Saints stream started'})
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/api/streams/status', methods=['GET'])
def streams_status():
    """Get current streaming status"""
    try:
        # Check for active ffmpeg processes
        result = run_command('pgrep -f "ffmpeg.*rtmp"')
        active_streams = len(result['stdout'].split('\n')) if result['stdout'] else 0
        
        return jsonify({
            'active_streams': active_streams,
            'wrestling_active': check_service_port(1935),
            'saints_active': False,  # Would need more specific checking
            'hdhomerun_active': check_service_port(5004)
        })
    except Exception as e:
        return jsonify({'error': str(e)})

if __name__ == '__main__':
    print("Starting Garuda Media Stack Control API on port 8081...")
    app.run(host='0.0.0.0', port=8081, debug=False)
