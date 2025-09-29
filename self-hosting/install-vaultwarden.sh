#!/bin/bash

# 🔐 VAULTWARDEN INSTALLER FOR GARUDA MEDIA STACK
# Native installation of Vaultwarden password manager
# Following Garuda Linux optimizations and media stack patterns

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_ROOT="/var/lib/vaultwarden"
CONFIG_ROOT="/etc/vaultwarden"
LOG_ROOT="/var/log"
VAULTWARDEN_USER="vaultwarden"
VAULTWARDEN_GROUP="vaultwarden"
VAULTWARDEN_PORT="8222"
ADMIN_TOKEN=""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"; }
info() { echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"; }

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root for system-level installation"
        exit 1
    fi
}

# Generate admin token
generate_admin_token() {
    log "Generating admin token..."
    ADMIN_TOKEN=$(openssl rand -hex 32)
    info "Admin token generated (will be shown at end of installation)"
}

# Create system user and group for Vaultwarden
setup_vaultwarden_user() {
    log "Setting up Vaultwarden system user..."
    
    # Create vaultwarden group if it doesn't exist
    if ! getent group "$VAULTWARDEN_GROUP" >/dev/null 2>&1; then
        groupadd --system "$VAULTWARDEN_GROUP"
        log "Created system group: $VAULTWARDEN_GROUP"
    fi
    
    # Create vaultwarden user if it doesn't exist
    if ! getent passwd "$VAULTWARDEN_USER" >/dev/null 2>&1; then
        useradd --system --gid "$VAULTWARDEN_GROUP" \
                --home-dir "$DATA_ROOT" \
                --shell /usr/bin/nologin \
                --comment "Vaultwarden password manager" \
                "$VAULTWARDEN_USER"
        log "Created system user: $VAULTWARDEN_USER"
    fi
    
    # Create data directories with proper permissions
    mkdir -p "$DATA_ROOT" "$CONFIG_ROOT"
    chown -R "$VAULTWARDEN_USER:$VAULTWARDEN_GROUP" "$DATA_ROOT"
    chown -R "$VAULTWARDEN_USER:$VAULTWARDEN_GROUP" "$CONFIG_ROOT"
    chmod 700 "$DATA_ROOT"
    chmod 755 "$CONFIG_ROOT"
    
    log "Vaultwarden directories created with proper permissions"
}

# Install Vaultwarden binary
install_vaultwarden_binary() {
    log "Installing Vaultwarden binary..."
    
    # Check if already installed and running
    if systemctl is-active --quiet vaultwarden 2>/dev/null; then
        log "✅ Vaultwarden is already running - skipping installation"
        return 0
    fi
    
    # Get latest release version
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/dani-garcia/vaultwarden/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    
    if [[ -z "$latest_version" ]]; then
        error "Failed to get latest Vaultwarden version"
        return 1
    fi
    
    log "Installing Vaultwarden version: $latest_version"
    
    # Download binary
    local download_url="https://github.com/dani-garcia/vaultwarden/releases/download/${latest_version}/vaultwarden-${latest_version}-linux-x64.tar.gz"
    local temp_dir=$(mktemp -d)
    
    if curl -L "$download_url" -o "$temp_dir/vaultwarden.tar.gz"; then
        cd "$temp_dir"
        tar -xzf vaultwarden.tar.gz
        
        # Install binary to system location
        install -m 755 vaultwarden /usr/local/bin/vaultwarden
        
        # Cleanup
        rm -rf "$temp_dir"
        
        log "✅ Vaultwarden binary installed to /usr/local/bin/vaultwarden"
    else
        error "Failed to download Vaultwarden binary"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Create Vaultwarden configuration
create_vaultwarden_config() {
    log "Creating Vaultwarden configuration..."
    
    # Create main configuration file
    cat > "$CONFIG_ROOT/config.json" << EOF
{
  "domain": "http://localhost:$VAULTWARDEN_PORT",
  "database_url": "$DATA_ROOT/db.sqlite3",
  "rocket_address": "127.0.0.1",
  "rocket_port": $VAULTWARDEN_PORT,
  "rocket_workers": 10,
  "web_vault_enabled": true,
  "web_vault_folder": "web-vault/",
  "admin_token": "$ADMIN_TOKEN",
  "invitation_org_name": "Garuda Vaultwarden",
  "invitations_allowed": true,
  "emergency_access_allowed": true,
  "sends_allowed": true,
  "password_iterations": 600000,
  "password_hints_allowed": true,
  "show_password_hint": false,
  "signups_allowed": true,
  "signups_verify": false,
  "signups_domains_whitelist": "",
  "org_creation_users": "",
  "org_events_enabled": false,
  "org_groups_enabled": false,
  "log_level": "warn",
  "log_file": "$LOG_ROOT/vaultwarden.log",
  "extended_logging": true,
  "reload_templates": false,
  "require_device_email": false,
  "disable_admin_token": false,
  "disable_icon_download": false,
  "icon_cache_ttl": 2592000,
  "icon_cache_negttl": 259200,
  "icon_download_timeout": 10,
  "icon_blacklist_non_global_ips": true,
  "disable_2fa_remember": false,
  "authenticator_disable_time_driftiness": false,
  "u2f_enabled": true,
  "yubico_cred_set": false,
  "duo_ikey": "",
  "duo_skey": "",
  "duo_host": "",
  "_enable_yubico": false,
  "_enable_duo": false,
  "smtp_host": "",
  "smtp_from": "",
  "smtp_from_name": "Vaultwarden",
  "smtp_port": 587,
  "smtp_ssl": true,
  "smtp_explicit_tls": false,
  "smtp_username": "",
  "smtp_password": "",
  "smtp_timeout": 15,
  "smtp_auth_mechanism": "Plain",
  "helo_name": ""
}
EOF
    
    chown "$VAULTWARDEN_USER:$VAULTWARDEN_GROUP" "$CONFIG_ROOT/config.json"
    chmod 600 "$CONFIG_ROOT/config.json"
    
    log "✅ Vaultwarden configuration created"
}

# Create systemd service
create_systemd_service() {
    log "Creating systemd service..."
    
    cat > /etc/systemd/system/vaultwarden.service << 'EOF'
[Unit]
Description=Vaultwarden Password Manager
Documentation=https://github.com/dani-garcia/vaultwarden
After=network.target
Wants=network.target

[Service]
Type=simple
User=vaultwarden
Group=vaultwarden
ExecStart=/usr/local/bin/vaultwarden
WorkingDirectory=/var/lib/vaultwarden
Environment=ROCKET_ENV=production
Environment=ROCKET_PORT=8222
Environment=ROCKET_ADDRESS=127.0.0.1
Environment=DATA_FOLDER=/var/lib/vaultwarden
Environment=CONFIG_FILE=/etc/vaultwarden/config.json
Environment=WEB_VAULT_ENABLED=true

# Security settings
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
DevicePolicy=closed
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/var/lib/vaultwarden
ReadOnlyPaths=/etc/vaultwarden

# Process restrictions
LimitNOFILE=65536
LimitNPROC=4096

# Restart policy
Restart=always
RestartSec=5
KillMode=process
TimeoutStopSec=30

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=vaultwarden

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable vaultwarden
    
    log "✅ Systemd service created and enabled"
}

# Install web vault
install_web_vault() {
    log "Installing Bitwarden Web Vault..."
    
    local web_vault_dir="$DATA_ROOT/web-vault"
    
    # Get latest web vault version
    local web_version
    web_version=$(curl -s https://api.github.com/repos/dani-garcia/bw_web_builds/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    
    if [[ -z "$web_version" ]]; then
        warn "Failed to get latest web vault version, using fallback"
        web_version="2024.6.2"
    fi
    
    log "Installing web vault version: $web_version"
    
    # Download and install web vault
    local temp_dir=$(mktemp -d)
    local download_url="https://github.com/dani-garcia/bw_web_builds/releases/download/${web_version}/bw_web_${web_version}.tar.gz"
    
    if curl -L "$download_url" -o "$temp_dir/web-vault.tar.gz"; then
        rm -rf "$web_vault_dir"
        mkdir -p "$web_vault_dir"
        cd "$temp_dir"
        tar -xzf web-vault.tar.gz -C "$web_vault_dir" --strip-components=1
        
        # Set proper permissions
        chown -R "$VAULTWARDEN_USER:$VAULTWARDEN_GROUP" "$web_vault_dir"
        
        rm -rf "$temp_dir"
        log "✅ Web vault installed"
    else
        warn "Failed to download web vault, Vaultwarden will work without web interface"
        rm -rf "$temp_dir"
    fi
}

# Configure nginx reverse proxy
setup_nginx_config() {
    log "Setting up nginx reverse proxy..."
    
    # Check if nginx is installed
    if ! command -v nginx >/dev/null 2>&1; then
        log "Installing nginx..."
        pacman -S --needed --noconfirm nginx
    fi
    
    # Create Vaultwarden nginx configuration
    cat > /etc/nginx/sites-available/vaultwarden << EOF
server {
    listen 80;
    server_name localhost;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; object-src 'none'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; media-src 'self'; frame-src 'self'; font-src 'self'; connect-src 'self' ws: wss:";
    add_header Referrer-Policy "same-origin";
    
    # Prevent access to certain file extensions
    location ~* \.(log|db|sqlite|sqlite3)$ {
        deny all;
        return 404;
    }
    
    # Main proxy
    location / {
        proxy_pass http://127.0.0.1:$VAULTWARDEN_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$server_name;
        
        proxy_connect_timeout 60;
        proxy_send_timeout 60;
        proxy_read_timeout 60;
    }
    
    # WebSocket support for notifications
    location /notifications/hub {
        proxy_pass http://127.0.0.1:$VAULTWARDEN_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Admin panel (optional, comment out if not needed)
    location /admin {
        proxy_pass http://127.0.0.1:$VAULTWARDEN_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Optional: Restrict admin access to local network
        # allow 192.168.0.0/16;
        # allow 10.0.0.0/8;
        # deny all;
    }
}
EOF
    
    # Enable sites-available/sites-enabled structure if not exists
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    
    # Add include directive to main nginx.conf if not present
    if ! grep -q "include /etc/nginx/sites-enabled/\*;" /etc/nginx/nginx.conf; then
        sed -i '/http {/a\    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
    fi
    
    # Enable the site
    ln -sf /etc/nginx/sites-available/vaultwarden /etc/nginx/sites-enabled/vaultwarden
    
    # Test nginx configuration
    if nginx -t; then
        systemctl enable nginx
        systemctl restart nginx
        log "✅ Nginx configuration created and enabled"
    else
        error "Nginx configuration test failed"
        return 1
    fi
}

# Setup firewall rules
setup_firewall() {
    log "Setting up firewall rules..."
    
    # Install ufw if not present
    if ! command -v ufw >/dev/null 2>&1; then
        pacman -S --needed --noconfirm ufw
    fi
    
    # Allow nginx
    ufw allow nginx
    
    # Allow Vaultwarden port (for direct access during troubleshooting)
    ufw allow $VAULTWARDEN_PORT/tcp comment "Vaultwarden direct access"
    
    log "✅ Firewall rules configured"
}

# Start services
start_services() {
    log "Starting Vaultwarden services..."
    
    # Start Vaultwarden
    systemctl start vaultwarden
    
    # Check if service started successfully
    sleep 3
    if systemctl is-active --quiet vaultwarden; then
        log "✅ Vaultwarden service started successfully"
    else
        error "Failed to start Vaultwarden service"
        systemctl status vaultwarden
        return 1
    fi
}

# Health check
perform_health_check() {
    log "Performing health check..."
    
    # Check if service is running
    if systemctl is-active --quiet vaultwarden; then
        log "✅ Vaultwarden service is running"
    else
        error "❌ Vaultwarden service is not running"
        return 1
    fi
    
    # Check if port is listening
    if ss -tln | grep -q ":$VAULTWARDEN_PORT "; then
        log "✅ Vaultwarden is listening on port $VAULTWARDEN_PORT"
    else
        error "❌ Vaultwarden is not listening on port $VAULTWARDEN_PORT"
        return 1
    fi
    
    # Try to connect to the service
    sleep 2
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$VAULTWARDEN_PORT" | grep -q "200\|302"; then
        log "✅ Vaultwarden web interface is accessible"
    else
        warn "⚠️  Vaultwarden web interface may not be fully ready yet"
    fi
}

# Display installation summary
show_summary() {
    log "Installation completed successfully!"
    
    echo ""
    echo -e "${GREEN}🔐 VAULTWARDEN INSTALLATION SUMMARY${NC}"
    echo "========================================"
    echo ""
    echo -e "${BLUE}Service Information:${NC}"
    echo "  • Service: vaultwarden.service"
    echo "  • User: $VAULTWARDEN_USER"
    echo "  • Data Directory: $DATA_ROOT"
    echo "  • Config Directory: $CONFIG_ROOT"
    echo "  • Log File: $LOG_ROOT/vaultwarden.log"
    echo ""
    echo -e "${BLUE}Web Access:${NC}"
    echo "  • Main Interface: http://localhost (via nginx)"
    echo "  • Direct Access: http://localhost:$VAULTWARDEN_PORT"
    echo "  • Admin Panel: http://localhost/admin"
    echo ""
    echo -e "${BLUE}Admin Token:${NC}"
    echo "  • Token: $ADMIN_TOKEN"
    echo "  • Save this token securely - you'll need it to access the admin panel"
    echo ""
    echo -e "${BLUE}Commands:${NC}"
    echo "  • Status: systemctl status vaultwarden"
    echo "  • Logs: journalctl -u vaultwarden -f"
    echo "  • Restart: systemctl restart vaultwarden"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Visit http://localhost to access Vaultwarden"
    echo "  2. Create your first user account"
    echo "  3. Configure SMTP settings in the admin panel (optional)"
    echo "  4. Set up SSL/TLS for production use"
    echo "  5. Configure backups for $DATA_ROOT"
    echo ""
}

# Main installation function
main() {
    log "🔐 Starting Vaultwarden installation for Garuda Media Stack..."
    
    check_root
    generate_admin_token
    setup_vaultwarden_user
    install_vaultwarden_binary
    create_vaultwarden_config
    create_systemd_service
    install_web_vault
    setup_nginx_config
    setup_firewall
    start_services
    perform_health_check
    show_summary
    
    log "🎉 Vaultwarden installation completed successfully!"
}

# Run main function
main "$@"