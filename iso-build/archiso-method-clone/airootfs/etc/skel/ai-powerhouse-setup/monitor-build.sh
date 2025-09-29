#!/bin/bash

# AI Powerhouse ISO Build Progress Monitor
# Shows real-time build progress with visual indicators

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Progress tracking
STAGES=(
    "Cleaning up"
    "Loading Packages"
    "Prepare Base installation"
    "Installing packages"
    "Configure chroot"
    "Building desktop environment"
    "Creating squashfs"
    "Building ISO"
    "Creating checksums"
    "Finalizing"
)

CURRENT_STAGE=0
LAST_SIZE=0

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              🚀 AI POWERHOUSE ISO BUILD MONITOR              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

show_progress_bar() {
    local progress=$1
    local width=50
    local filled=$((progress * width / 100))
    local empty=$((width - filled))
    
    printf "${GREEN}["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "] %3d%%${NC}" "$progress"
}

show_spinner() {
    local chars="⣾⣽⣻⢿⡿⣟⣯⣷"
    local i=$(( $(date +%s) % ${#chars} ))
    printf "${YELLOW}%s${NC}" "${chars:$i:1}"
}

get_build_stats() {
    local log_file="/tmp/iso-build.log"
    local chroot_dir="/var/cache/garuda-tools/garuda-chroots/buildiso/ai-powerhouse/x86_64"
    local output_dir="/var/cache/garuda-tools/garuda-builds/iso"
    
    # Check if build log exists
    if [[ ! -f "$log_file" ]]; then
        echo "0|Waiting for build to start..."
        return
    fi
    
    # Analyze log for current stage
    local stage="Unknown"
    local progress=0
    
    if grep -q "Cleaning up" "$log_file" 2>/dev/null; then
        stage="Cleaning up old files"
        progress=5
    fi
    
    if grep -q "Loading Packages" "$log_file" 2>/dev/null; then
        stage="Loading package lists"
        progress=10
    fi
    
    if grep -q "Prepare.*installation" "$log_file" 2>/dev/null; then
        stage="Preparing base installation"
        progress=15
    fi
    
    if grep -q "Installing packages" "$log_file" 2>/dev/null; then
        stage="Installing packages to chroot"
        progress=25
        
        # Count installed packages
        local installed=$(grep -c "installing" "$log_file" 2>/dev/null || echo 0)
        if [[ $installed -gt 0 ]]; then
            progress=$((25 + (installed / 10)))  # Rough estimate
            if [[ $progress -gt 60 ]]; then progress=60; fi
        fi
    fi
    
    if grep -q "configure.*chroot\|chroot.*configure" "$log_file" 2>/dev/null; then
        stage="Configuring chroot environment"
        progress=65
    fi
    
    if grep -q "squashfs\|mksquashfs" "$log_file" 2>/dev/null; then
        stage="Creating compressed filesystem"
        progress=75
    fi
    
    if grep -q "grub\|bootloader" "$log_file" 2>/dev/null; then
        stage="Setting up bootloader"
        progress=85
    fi
    
    if grep -q "checksum\|sha256" "$log_file" 2>/dev/null; then
        stage="Creating checksums"
        progress=95
    fi
    
    if grep -q "Done\|finished\|ISO.*ready" "$log_file" 2>/dev/null; then
        stage="Build completed successfully!"
        progress=100
    fi
    
    if grep -q "ERROR\|FAILED" "$log_file" 2>/dev/null; then
        stage="❌ BUILD FAILED - Check logs"
        progress=-1
    fi
    
    # Get size info if available
    local size_info=""
    if [[ -d "$chroot_dir" ]]; then
        local current_size=$(du -sh "$chroot_dir" 2>/dev/null | cut -f1 || echo "0")
        size_info=" | Chroot: $current_size"
    fi
    
    if [[ -d "$output_dir" ]] && ls "$output_dir"/*.iso &>/dev/null; then
        local iso_size=$(du -sh "$output_dir"/*.iso 2>/dev/null | cut -f1 || echo "0")
        size_info="$size_info | ISO: $iso_size"
    fi
    
    echo "${progress}|${stage}${size_info}"
}

show_live_stats() {
    local log_file="/tmp/iso-build.log"
    
    echo -e "${BLUE}📊 Live Statistics:${NC}"
    
    # Show current download if happening
    local current_download=$(tail -n 5 "$log_file" 2>/dev/null | grep -o "[a-zA-Z0-9_-]*downloading" | tail -1)
    if [[ -n "$current_download" ]]; then
        echo -e "   📥 Currently downloading: ${YELLOW}${current_download/downloading/}${NC}"
    fi
    
    # Show package count
    local pkg_count=$(grep -c "installing\|upgrading" "$log_file" 2>/dev/null || echo 0)
    echo -e "   📦 Packages processed: ${GREEN}$pkg_count${NC}"
    
    # Show errors/warnings
    local errors=$(grep -c "ERROR\|error:" "$log_file" 2>/dev/null || echo 0)
    local warnings=$(grep -c "WARNING\|warning:" "$log_file" 2>/dev/null || echo 0)
    if [[ $errors -gt 0 ]]; then
        echo -e "   ❌ Errors: ${RED}$errors${NC}"
    fi
    if [[ $warnings -gt 0 ]]; then
        echo -e "   ⚠️  Warnings: ${YELLOW}$warnings${NC}"
    fi
    
    # Show build time
    local start_time=$(stat -c %Y "$log_file" 2>/dev/null || date +%s)
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    local hours=$((elapsed / 3600))
    local minutes=$(((elapsed % 3600) / 60))
    local seconds=$((elapsed % 60))
    
    printf "   ⏱️  Build time: ${CYAN}%02d:%02d:%02d${NC}\n" "$hours" "$minutes" "$seconds"
}

# Main monitoring loop
while true; do
    # Get current build status
    IFS='|' read -r progress stage_info <<< "$(get_build_stats)"
    
    # Clear screen and show header
    tput cup 0 0
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              🚀 AI POWERHOUSE ISO BUILD MONITOR              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Show current stage
    printf "🔧 Current Stage: "
    if [[ $progress -eq -1 ]]; then
        echo -e "${RED}$stage_info${NC}"
    elif [[ $progress -eq 100 ]]; then
        echo -e "${GREEN}$stage_info${NC}"
    else
        echo -e "${YELLOW}$stage_info${NC} $(show_spinner)"
    fi
    
    echo ""
    
    # Show progress bar
    if [[ $progress -ge 0 ]]; then
        printf "📈 Progress: "
        show_progress_bar "$progress"
        echo ""
    fi
    
    echo ""
    
    # Show live stats
    show_live_stats
    
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Show recent log lines
    echo -e "${BLUE}📜 Recent Activity:${NC}"
    tail -n 3 /tmp/iso-build.log 2>/dev/null | while read -r line; do
        if [[ "$line" =~ ERROR|error: ]]; then
            echo -e "   ${RED}$line${NC}"
        elif [[ "$line" =~ WARNING|warning: ]]; then
            echo -e "   ${YELLOW}$line${NC}"
        elif [[ "$line" =~ installing|upgrading ]]; then
            echo -e "   ${GREEN}$line${NC}"
        else
            echo -e "   ${NC}$line${NC}"
        fi
    done
    
    echo ""
    echo -e "${CYAN}Press Ctrl+C to stop monitoring (build continues in background)${NC}"
    
    # Exit if build completed or failed
    if [[ $progress -eq 100 ]] || [[ $progress -eq -1 ]]; then
        echo ""
        if [[ $progress -eq 100 ]]; then
            echo -e "${GREEN}🎉 BUILD COMPLETED SUCCESSFULLY!${NC}"
            
            # Show final ISO location
            local iso_path=$(find /var/cache/garuda-tools/garuda-builds/iso -name "*.iso" 2>/dev/null | head -1)
            if [[ -n "$iso_path" ]]; then
                local iso_size=$(du -sh "$iso_path" | cut -f1)
                echo -e "${GREEN}📀 ISO Location: $iso_path${NC}"
                echo -e "${GREEN}📏 ISO Size: $iso_size${NC}"
                
                # Calculate checksums
                echo -e "${YELLOW}🔐 Calculating checksums...${NC}"
                local sha256=$(sha256sum "$iso_path" | cut -d' ' -f1)
                echo -e "${GREEN}🔐 SHA256: $sha256${NC}"
                
                echo "$sha256  $(basename "$iso_path")" > "${iso_path}.sha256"
                echo -e "${GREEN}💾 Checksum saved to: ${iso_path}.sha256${NC}"
            fi
        else
            echo -e "${RED}❌ BUILD FAILED! Check the full log: /tmp/iso-build.log${NC}"
        fi
        break
    fi
    
    sleep 2
done