#!/bin/bash

# Background ISO Build Completion Monitor
# Will notify when the AI Powerhouse ISO build completes

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/tmp/iso-build.log"
OUTPUT_DIR="/tmp/garuda-build/iso"

echo -e "${BLUE}🔍 Monitoring AI Powerhouse ISO build completion...${NC}"
echo -e "${YELLOW}Build started at: $(date)${NC}"
echo ""

# Function to check if build is complete
check_build_status() {
    # Check if buildiso process is still running
    if pgrep -f "buildiso.*ai-powerhouse" >/dev/null; then
        return 1  # Still building
    fi
    
    # Check for successful completion in log
    if grep -q "Done.*ISO" "$LOG_FILE" 2>/dev/null; then
        return 0  # Success
    fi
    
    # Check for failure in log  
    if grep -q "ERROR.*Aborted" "$LOG_FILE" 2>/dev/null; then
        return 2  # Failed
    fi
    
    return 1  # Still building
}

# Monitor loop
while true; do
    check_build_status
    status=$?
    
    case $status in
        0)  # Build completed successfully
            echo ""
            echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║                🎉 ISO BUILD COMPLETED! 🎉                   ║${NC}"
            echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            
            # Find the ISO file
            ISO_FILE=$(find "$OUTPUT_DIR" -name "*.iso" 2>/dev/null | head -1)
            
            if [[ -n "$ISO_FILE" && -f "$ISO_FILE" ]]; then
                ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
                ISO_NAME=$(basename "$ISO_FILE")
                
                echo -e "${GREEN}🚀 Your AI Powerhouse ISO is ready!${NC}"
                echo -e "${BLUE}📀 ISO File: $ISO_FILE${NC}"
                echo -e "${BLUE}📏 Size: $ISO_SIZE${NC}"
                echo -e "${BLUE}📝 Name: $ISO_NAME${NC}"
                echo ""
                
                # Generate checksum
                echo -e "${YELLOW}🔐 Generating checksums...${NC}"
                SHA256=$(sha256sum "$ISO_FILE" | cut -d' ' -f1)
                echo "$SHA256  $ISO_NAME" > "${ISO_FILE}.sha256"
                
                echo -e "${GREEN}✅ SHA256: $SHA256${NC}"
                echo -e "${GREEN}💾 Checksum saved: ${ISO_FILE}.sha256${NC}"
                echo ""
                
                echo -e "${BLUE}🎯 Next Steps:${NC}"
                echo -e "1. Write to USB: dd if='$ISO_FILE' of=/dev/sdX bs=4M status=progress"
                echo -e "2. Boot from USB and install with ZFS root filesystem"
                echo -e "3. Run your AI Powerhouse transformation script"
                echo ""
                echo -e "${GREEN}Your ultimate AI development environment is ready! 🔥${NC}"
                
                # Send notification
                if command -v notify-send >/dev/null 2>&1; then
                    notify-send "AI Powerhouse ISO" "Build completed successfully! Size: $ISO_SIZE" -i applications-development
                fi
                
            else
                echo -e "${RED}❌ ISO build completed but file not found!${NC}"
            fi
            
            break
            ;;
            
        2)  # Build failed
            echo ""
            echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${RED}║                ❌ ISO BUILD FAILED! ❌                       ║${NC}"
            echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e "${RED}Build failed. Check the log file: $LOG_FILE${NC}"
            echo ""
            echo -e "${YELLOW}Last 10 lines of build log:${NC}"
            tail -n 10 "$LOG_FILE" 2>/dev/null
            
            # Send notification
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "AI Powerhouse ISO" "Build failed! Check logs." -i dialog-error
            fi
            
            break
            ;;
            
        1)  # Still building
            # Show current progress
            if [[ -f "$LOG_FILE" ]]; then
                # Get package count
                PKG_COUNT=$(grep -c "installing\|upgrading" "$LOG_FILE" 2>/dev/null || echo 0)
                
                # Get current activity
                CURRENT_ACTIVITY=$(tail -n 2 "$LOG_FILE" 2>/dev/null | head -1)
                
                # Update status line
                printf "\r${BLUE}📦 Packages: $PKG_COUNT | Current: ${CURRENT_ACTIVITY:0:50}...${NC}"
            else
                printf "\r${YELLOW}⏱️  Waiting for build to start...${NC}"
            fi
            ;;
    esac
    
    sleep 10
done

echo ""
echo -e "${BLUE}Build monitoring completed at: $(date)${NC}"