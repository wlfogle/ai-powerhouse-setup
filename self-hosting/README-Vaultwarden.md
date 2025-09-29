# 🔐 Vaultwarden Installation for Garuda Media Stack

Vaultwarden is a lightweight, self-hosted implementation of the Bitwarden password manager server API. This installation provides a secure, native deployment integrated with your Garuda Linux media stack.

## Features

- 🔒 **Secure**: Isolated system user with hardened systemd service
- 🌐 **Web Access**: Full web vault interface with nginx reverse proxy
- 🔄 **Auto-restart**: Systemd service with automatic restart policies
- 🛡️ **Security Headers**: Comprehensive security headers via nginx
- 💾 **Backup Support**: Integrated backup and restore functionality
- 📊 **Health Monitoring**: Service status monitoring integration

## Quick Installation

### Option 1: Using Optional Services Installer
```bash
# Install Vaultwarden via the optional services menu
sudo ./install-optional-services.sh vaultwarden
```

### Option 2: Direct Installation
```bash
# Run the dedicated Vaultwarden installer
sudo ./install-vaultwarden.sh
```

## Access Information

After installation, Vaultwarden will be available at:

- **Main Interface**: http://localhost (via nginx reverse proxy)
- **Direct Access**: http://localhost:8222
- **Admin Panel**: http://localhost/admin

## Admin Token

During installation, a secure admin token is generated. **Save this token securely** - you'll need it to access the admin panel for configuration.

## Service Management

```bash
# Check service status
systemctl status vaultwarden

# View logs
journalctl -u vaultwarden -f

# Restart service
sudo systemctl restart vaultwarden

# Stop service
sudo systemctl stop vaultwarden

# Start service
sudo systemctl start vaultwarden
```

## Backup and Restore

### Create Backup
```bash
# Create a complete backup
sudo ./scripts/vaultwarden-backup.sh backup

# List available backups
./scripts/vaultwarden-backup.sh list
```

### Restore from Backup
```bash
# Restore from a specific backup
sudo ./scripts/vaultwarden-backup.sh restore vaultwarden_backup_YYYYMMDD_HHMMSS.tar.gz
```

### Automatic Cleanup
```bash
# Clean up old backups (older than 30 days)
sudo ./scripts/vaultwarden-backup.sh cleanup
```

## First-Time Setup

1. **Visit the Web Interface**
   - Open http://localhost in your browser
   - The Bitwarden web vault should load

2. **Create Your Account**
   - Click "Create Account" 
   - Fill in your email and master password
   - **Important**: Use a strong master password!

3. **Configure Admin Settings** (Optional)
   - Visit http://localhost/admin
   - Enter the admin token shown during installation
   - Configure SMTP settings for email verification
   - Adjust security settings as needed

4. **Install Client Applications**
   - Desktop: Download from https://bitwarden.com/download/
   - Mobile: Install from app stores
   - Browser: Install browser extensions
   - Configure server URL to point to your installation

## Configuration Files

- **Data Directory**: `/var/lib/vaultwarden/`
- **Config Directory**: `/etc/vaultwarden/`
- **Service File**: `/etc/systemd/system/vaultwarden.service`
- **Nginx Config**: `/etc/nginx/sites-available/vaultwarden`
- **Logs**: `/var/log/vaultwarden.log` and `journalctl -u vaultwarden`

## Security Considerations

### Production Deployment
For production use, consider these security enhancements:

1. **SSL/TLS Certificate**
   ```bash
   # Install certbot for Let's Encrypt
   sudo pacman -S certbot certbot-nginx
   
   # Get certificate (replace with your domain)
   sudo certbot --nginx -d your-domain.com
   ```

2. **Disable Signups** (After creating your account)
   - Edit `/etc/vaultwarden/config.json`
   - Set `"signups_allowed": false`
   - Restart service: `sudo systemctl restart vaultwarden`

3. **Restrict Admin Panel** (Uncomment in nginx config)
   - Edit `/etc/nginx/sites-available/vaultwarden`
   - Uncomment the IP restrictions for `/admin` location
   - Reload nginx: `sudo systemctl reload nginx`

4. **Enable Firewall**
   ```bash
   # Enable UFW firewall
   sudo ufw enable
   
   # The installer already configured nginx and Vaultwarden ports
   sudo ufw status
   ```

### Network Access
- **Local Network Only**: Default configuration allows access from any IP
- **VPN Access**: Consider using WireGuard (available in Ghost Mode)
- **External Access**: Requires proper SSL/TLS and domain configuration

## Troubleshooting

### Service Won't Start
```bash
# Check service status
systemctl status vaultwarden

# View detailed logs
journalctl -u vaultwarden -n 50

# Check if port is available
sudo ss -tlnp | grep 8222
```

### Web Interface Not Loading
```bash
# Check nginx status
systemctl status nginx

# Test nginx configuration
sudo nginx -t

# Check if Vaultwarden is responding
curl -I http://localhost:8222
```

### Database Issues
```bash
# Check database file permissions
ls -la /var/lib/vaultwarden/

# Check disk space
df -h /var/lib/vaultwarden/

# View storage usage
./scripts/vaultwarden-backup.sh usage
```

### Reset Admin Token
```bash
# Generate new admin token
openssl rand -hex 32

# Edit configuration file
sudo nano /etc/vaultwarden/config.json

# Update admin_token field and restart service
sudo systemctl restart vaultwarden
```

## Updates

To update Vaultwarden to the latest version:

```bash
# Re-run the installer (it will detect existing installation)
sudo ./install-vaultwarden.sh

# Or manually download and replace binary
curl -L $(curl -s https://api.github.com/repos/dani-garcia/vaultwarden/releases/latest | grep -Po '"browser_download_url": "\K.*vaultwarden.*linux-x64.tar.gz(?=")') -o /tmp/vaultwarden.tar.gz
sudo systemctl stop vaultwarden
cd /tmp && tar -xzf vaultwarden.tar.gz
sudo install -m 755 vaultwarden /usr/local/bin/vaultwarden
sudo systemctl start vaultwarden
```

## Integration with Media Stack

Vaultwarden integrates seamlessly with your existing media stack:

- **Health Checks**: Included in `./install-optional-services.sh status`
- **Service Management**: Follows same patterns as other services
- **Backup Integration**: Compatible with existing backup workflows
- **Firewall**: Shares UFW configuration with other services

## Support and Documentation

- **Official Documentation**: https://github.com/dani-garcia/vaultwarden/wiki
- **Bitwarden Help**: https://bitwarden.com/help/
- **Local Logs**: `journalctl -u vaultwarden -f`
- **Configuration Reference**: https://github.com/dani-garcia/vaultwarden/wiki/Configuration-overview

---

**Security Reminder**: Always keep your master password secure and consider using two-factor authentication. Regularly backup your Vaultwarden data to prevent data loss.