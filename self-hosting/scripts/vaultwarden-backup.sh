#!/bin/bash

# 🔐 VAULTWARDEN BACKUP AND MAINTENANCE SCRIPT
# Backup Vaultwarden data and configuration for safe keeping

set -euo pipefail

# Configuration
DATA_ROOT="/var/lib/vaultwarden"
CONFIG_ROOT="/etc/vaultwarden"
BACKUP_ROOT="/var/backups/vaultwarden"
RETENTION_DAYS=30

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
        error "This script must be run as root to access Vaultwarden data"
        exit 1
    fi
}

# Create backup directory
setup_backup_directory() {
    log "Setting up backup directory..."
    
    mkdir -p "$BACKUP_ROOT"
    chown root:root "$BACKUP_ROOT"
    chmod 700 "$BACKUP_ROOT"
    
    log "✅ Backup directory created: $BACKUP_ROOT"
}

# Backup Vaultwarden data
backup_vaultwarden() {
    local backup_date=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$BACKUP_ROOT/backup_$backup_date"
    
    log "Creating Vaultwarden backup for $backup_date..."
    
    # Create backup directory
    mkdir -p "$backup_dir"
    
    # Stop Vaultwarden service temporarily for consistent backup
    local was_running=false
    if systemctl is-active --quiet vaultwarden; then
        log "Stopping Vaultwarden service for consistent backup..."
        systemctl stop vaultwarden
        was_running=true
    fi
    
    # Backup database and data
    if [[ -d "$DATA_ROOT" ]]; then
        log "Backing up Vaultwarden data directory..."
        cp -r "$DATA_ROOT" "$backup_dir/data"
        chown -R root:root "$backup_dir/data"
    else
        warn "Data directory not found: $DATA_ROOT"
    fi
    
    # Backup configuration
    if [[ -d "$CONFIG_ROOT" ]]; then
        log "Backing up Vaultwarden configuration..."
        cp -r "$CONFIG_ROOT" "$backup_dir/config"
        chown -R root:root "$backup_dir/config"
    else
        warn "Config directory not found: $CONFIG_ROOT"
    fi
    
    # Backup systemd service file
    if [[ -f "/etc/systemd/system/vaultwarden.service" ]]; then
        log "Backing up systemd service file..."
        cp "/etc/systemd/system/vaultwarden.service" "$backup_dir/vaultwarden.service"
    fi
    
    # Backup nginx configuration if exists
    if [[ -f "/etc/nginx/sites-available/vaultwarden" ]]; then
        log "Backing up nginx configuration..."
        mkdir -p "$backup_dir/nginx"
        cp "/etc/nginx/sites-available/vaultwarden" "$backup_dir/nginx/vaultwarden.conf"
    fi
    
    # Create backup metadata
    cat > "$backup_dir/backup_info.txt" << EOF
Vaultwarden Backup Information
==============================
Backup Date: $(date)
Hostname: $(hostname)
Vaultwarden Version: $(vaultwarden --version 2>/dev/null || echo "Unknown")
System: $(uname -a)

Contents:
- data/: Vaultwarden data directory
- config/: Vaultwarden configuration
- vaultwarden.service: systemd service file
- nginx/: nginx reverse proxy configuration
EOF
    
    # Restart Vaultwarden if it was running
    if [[ "$was_running" == "true" ]]; then
        log "Restarting Vaultwarden service..."
        systemctl start vaultwarden
        
        # Wait for service to be ready
        sleep 5
        if systemctl is-active --quiet vaultwarden; then
            log "✅ Vaultwarden service restarted successfully"
        else
            error "❌ Failed to restart Vaultwarden service"
            return 1
        fi
    fi
    
    # Create compressed archive
    log "Creating compressed backup archive..."
    cd "$BACKUP_ROOT"
    tar -czf "vaultwarden_backup_$backup_date.tar.gz" "backup_$backup_date"
    
    # Remove uncompressed backup directory
    rm -rf "backup_$backup_date"
    
    log "✅ Backup completed: vaultwarden_backup_$backup_date.tar.gz"
    return 0
}

# Clean up old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    
    local deleted_count=0
    
    # Find and delete old backup files
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            deleted_count=$((deleted_count + 1))
            log "Deleted old backup: $(basename "$file")"
        fi
    done < <(find "$BACKUP_ROOT" -name "vaultwarden_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS -print0 2>/dev/null)
    
    if [[ $deleted_count -eq 0 ]]; then
        log "No old backups to clean up"
    else
        log "✅ Cleaned up $deleted_count old backup(s)"
    fi
}

# List available backups
list_backups() {
    log "Available Vaultwarden backups:"
    echo ""
    
    if [[ ! -d "$BACKUP_ROOT" ]]; then
        warn "Backup directory does not exist: $BACKUP_ROOT"
        return 1
    fi
    
    local backup_count=0
    for backup_file in "$BACKUP_ROOT"/vaultwarden_backup_*.tar.gz; do
        if [[ -f "$backup_file" ]]; then
            local file_size=$(du -h "$backup_file" | cut -f1)
            local file_date=$(stat -c %y "$backup_file" | cut -d' ' -f1,2 | cut -d'.' -f1)
            echo "  📦 $(basename "$backup_file") - $file_size - $file_date"
            backup_count=$((backup_count + 1))
        fi
    done
    
    if [[ $backup_count -eq 0 ]]; then
        warn "No backups found in $BACKUP_ROOT"
    else
        echo ""
        log "Found $backup_count backup(s) in $BACKUP_ROOT"
        echo ""
        log "Backup storage usage:"
        du -sh "$BACKUP_ROOT"
    fi
}

# Restore from backup
restore_backup() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        error "Please specify a backup file to restore"
        echo "Usage: $0 restore <backup_filename>"
        list_backups
        return 1
    fi
    
    local backup_path="$BACKUP_ROOT/$backup_file"
    if [[ ! -f "$backup_path" ]]; then
        error "Backup file not found: $backup_path"
        list_backups
        return 1
    fi
    
    warn "⚠️  This will REPLACE your current Vaultwarden installation with the backup!"
    echo "Backup file: $backup_file"
    echo "Current data will be backed up before restoration."
    
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Restoration cancelled"
        return 0
    fi
    
    # Create a backup of current state before restore
    log "Creating backup of current state before restoration..."
    backup_vaultwarden
    
    # Stop Vaultwarden
    log "Stopping Vaultwarden service..."
    if systemctl is-active --quiet vaultwarden; then
        systemctl stop vaultwarden
    fi
    
    # Extract backup
    log "Extracting backup archive..."
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    tar -xzf "$backup_path"
    
    local extracted_dir=$(find . -maxdepth 1 -type d -name "backup_*" | head -n1)
    if [[ -z "$extracted_dir" ]]; then
        error "Failed to find extracted backup directory"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Restore data
    if [[ -d "$extracted_dir/data" ]]; then
        log "Restoring Vaultwarden data..."
        rm -rf "$DATA_ROOT"
        cp -r "$extracted_dir/data" "$DATA_ROOT"
        chown -R vaultwarden:vaultwarden "$DATA_ROOT"
    fi
    
    # Restore configuration
    if [[ -d "$extracted_dir/config" ]]; then
        log "Restoring Vaultwarden configuration..."
        rm -rf "$CONFIG_ROOT"
        cp -r "$extracted_dir/config" "$CONFIG_ROOT"
        chown -R vaultwarden:vaultwarden "$CONFIG_ROOT"
    fi
    
    # Restore systemd service
    if [[ -f "$extracted_dir/vaultwarden.service" ]]; then
        log "Restoring systemd service file..."
        cp "$extracted_dir/vaultwarden.service" "/etc/systemd/system/vaultwarden.service"
        systemctl daemon-reload
    fi
    
    # Restore nginx configuration
    if [[ -d "$extracted_dir/nginx" && -f "$extracted_dir/nginx/vaultwarden.conf" ]]; then
        log "Restoring nginx configuration..."
        mkdir -p /etc/nginx/sites-available
        cp "$extracted_dir/nginx/vaultwarden.conf" "/etc/nginx/sites-available/vaultwarden"
        ln -sf /etc/nginx/sites-available/vaultwarden /etc/nginx/sites-enabled/vaultwarden
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    # Start Vaultwarden
    log "Starting Vaultwarden service..."
    systemctl start vaultwarden
    
    # Verify restoration
    sleep 5
    if systemctl is-active --quiet vaultwarden; then
        log "✅ Restoration completed successfully"
        log "🌐 Vaultwarden should be accessible at http://localhost:8222"
    else
        error "❌ Vaultwarden service failed to start after restoration"
        systemctl status vaultwarden
        return 1
    fi
}

# Show disk usage
show_usage() {
    log "Vaultwarden storage usage:"
    echo ""
    
    if [[ -d "$DATA_ROOT" ]]; then
        echo "📊 Data directory:"
        du -sh "$DATA_ROOT"
        echo ""
        echo "📋 Data directory contents:"
        ls -la "$DATA_ROOT"
        echo ""
    fi
    
    if [[ -d "$BACKUP_ROOT" ]]; then
        echo "💾 Backup directory:"
        du -sh "$BACKUP_ROOT"
        echo ""
    fi
    
    # Show database size if exists
    local db_file="$DATA_ROOT/db.sqlite3"
    if [[ -f "$db_file" ]]; then
        echo "🗄️  Database file:"
        ls -lh "$db_file"
    fi
}

# Main function
main() {
    case "${1:-help}" in
        "backup")
            check_root
            setup_backup_directory
            backup_vaultwarden
            cleanup_old_backups
            ;;
        "list")
            list_backups
            ;;
        "restore")
            check_root
            restore_backup "${2:-}"
            ;;
        "cleanup")
            check_root
            setup_backup_directory
            cleanup_old_backups
            ;;
        "usage")
            show_usage
            ;;
        "help"|*)
            echo "🔐 Vaultwarden Backup and Maintenance Tool"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  backup   - Create a new backup of Vaultwarden data and config"
            echo "  list     - List available backups"
            echo "  restore  - Restore from a backup file"
            echo "  cleanup  - Remove old backups (older than $RETENTION_DAYS days)"
            echo "  usage    - Show disk usage information"
            echo "  help     - Show this help message"
            echo ""
            echo "Examples:"
            echo "  sudo $0 backup"
            echo "  $0 list"
            echo "  sudo $0 restore vaultwarden_backup_20240927_120000.tar.gz"
            echo "  sudo $0 cleanup"
            echo ""
            ;;
    esac
}

# Run main function
main "$@"