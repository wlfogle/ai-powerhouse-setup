#!/usr/bin/env python3
"""
Simple API Server for Garuda Media Stack Dashboard
Provides status endpoints for services
"""

import http.server
import socketserver
import json
import subprocess
import urllib.parse
from datetime import datetime

class MediaStackAPIHandler(http.server.BaseHTTPRequestHandler):
    
    def do_GET(self):
        if self.path == '/api/ghost-mode/status':
            self.send_ghost_status()
        elif self.path == '/api/stream-status':
            self.send_stream_status()
        elif self.path == '/api/system/stats':
            self.send_system_stats()
        elif self.path.startswith('/api/status/'):
            service = self.path.split('/')[-1]
            self.send_service_status(service)
        else:
            self.send_error(404, "API endpoint not found")
    
    def do_POST(self):
        if self.path == '/api/ghost-mode/toggle':
            self.toggle_ghost_mode()
        elif self.path == '/api/start-wrestling':
            self.start_wrestling_stream()
        elif self.path == '/api/start-saints':
            self.start_saints_stream()
        elif self.path == '/api/stop-streams':
            self.stop_streams()
        else:
            self.send_error(404, "API endpoint not found")
    
    def send_json_response(self, data, status_code=200):
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def send_ghost_status(self):
        try:
            with open('/home/lou/garuda-media-stack/ghost-mode-status.txt', 'r') as f:
                status = f.read().strip()
            
            self.send_json_response({
                'active': status == 'active',
                'status': status,
                'timestamp': datetime.now().isoformat()
            })
        except:
            self.send_json_response({'active': False, 'status': 'unknown'})
    
    def send_stream_status(self):
        try:
            result = subprocess.run(['/home/lou/garuda-media-stack/stream-manager.sh', 'status-json'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                data = json.loads(result.stdout)
                self.send_json_response(data)
            else:
                self.send_json_response({'active_streams': []})
        except:
            self.send_json_response({'active_streams': []})
    
    def send_service_status(self, service):
        # Map service names to ports
        ports = {
            'jellyfin': 8096,
            'radarr': 7878,
            'sonarr': 8989,
            'lidarr': 8686,
            'jackett': 9117,
            'qbittorrent': 5080,
            'jellyseerr': 5055
        }
        
        if service in ports:
            try:
                result = subprocess.run(['netstat', '-tln'], capture_output=True, text=True)
                port_listening = f":{ports[service]}" in result.stdout
                self.send_json_response({
                    'status': 'online' if port_listening else 'offline',
                    'port': ports[service]
                })
            except:
                self.send_json_response({'status': 'unknown'})
        else:
            self.send_error(404, f"Unknown service: {service}")
    
    def send_system_stats(self):
        try:
            # Get basic system stats
            uptime_result = subprocess.run(['uptime'], capture_output=True, text=True)
            uptime = uptime_result.stdout.strip() if uptime_result.returncode == 0 else "Unknown"
            
            # VPN client count
            wg_result = subprocess.run(['wg', 'show'], capture_output=True, text=True)
            vpn_clients = wg_result.stdout.count('peer') if wg_result.returncode == 0 else 0
            
            self.send_json_response({
                'uptime': uptime.split('up ')[1].split(',')[0] if 'up ' in uptime else 'Unknown',
                'vpn_clients': vpn_clients,
                'disk_usage': '75%',  # Placeholder
                'timestamp': datetime.now().isoformat()
            })
        except:
            self.send_json_response({'uptime': 'Unknown', 'vpn_clients': 0, 'disk_usage': 'Unknown'})
    
    def toggle_ghost_mode(self):
        try:
            result = subprocess.run(['/home/lou/garuda-media-stack/ghost-control.sh', 'toggle'], 
                                  capture_output=True, text=True)
            success = result.returncode == 0
            self.send_json_response({
                'success': success,
                'status': 'toggled' if success else 'failed',
                'message': result.stdout if success else result.stderr
            })
        except:
            self.send_json_response({'success': False, 'status': 'error'})
    
    def start_wrestling_stream(self):
        # Parse POST data
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        try:
            data = json.loads(post_data.decode())
            event = data.get('event', 'raw')
            quality = data.get('quality', '720p')
            
            result = subprocess.run(['/home/lou/garuda-media-stack/stream-manager.sh', 
                                   'start-wrestling', event, quality], 
                                  capture_output=True, text=True)
            success = result.returncode == 0
            self.send_json_response({
                'success': success,
                'message': result.stdout if success else result.stderr
            })
        except:
            self.send_json_response({'success': False, 'message': 'Invalid request'})
    
    def start_saints_stream(self):
        try:
            result = subprocess.run(['/home/lou/garuda-media-stack/stream-manager.sh', 
                                   'start-saints', 'regular', '1080p'], 
                                  capture_output=True, text=True)
            success = result.returncode == 0
            self.send_json_response({
                'success': success,
                'message': result.stdout if success else result.stderr
            })
        except:
            self.send_json_response({'success': False, 'message': 'Stream failed'})
    
    def stop_streams(self):
        try:
            result = subprocess.run(['/home/lou/garuda-media-stack/stream-manager.sh', 'stop'], 
                                  capture_output=True, text=True)
            success = result.returncode == 0
            self.send_json_response({
                'success': success,
                'message': 'All streams stopped' if success else result.stderr
            })
        except:
            self.send_json_response({'success': False, 'message': 'Stop failed'})

if __name__ == "__main__":
    PORT = 8601
    with socketserver.TCPServer(("", PORT), MediaStackAPIHandler) as httpd:
        print(f"🚀 Media Stack API Server running on port {PORT}")
        httpd.serve_forever()
