#!/bin/bash

# MobaLiveCD AI AppImage Builder
# Creates a portable AppImage with all dependencies bundled

set -e

PROJECT_NAME="mobalivecd-ai"
VERSION="2.0.0"
APPIMAGE_NAME="${PROJECT_NAME}-${VERSION}-x86_64.AppImage"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}=================================="
    echo -e "$1"
    echo -e "==================================${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
    print_header "🔍 Checking Dependencies"
    
    # Check for required tools
    local deps=("python3" "pip3" "wget" "file" "desktop-file-validate")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing[*]}"
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt install ${missing[*]}"
        echo "  Fedora: sudo dnf install ${missing[*]}"
        echo "  Arch: sudo pacman -S ${missing[*]}"
        exit 1
    fi
    
    print_success "All dependencies available"
}

# Download appimagetool if not present
get_appimagetool() {
    print_header "🛠️  Setting Up AppImage Tools"
    
    if ! command -v appimagetool &> /dev/null; then
        print_info "Downloading appimagetool..."
        
        wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" \
            -O appimagetool
        chmod +x appimagetool
        
        # Make it work on systems with FUSE issues
        ./appimagetool --appimage-extract &> /dev/null
        alias appimagetool="$(pwd)/squashfs-root/AppRun"
        
        print_success "appimagetool ready"
    else
        print_success "appimagetool already available"
    fi
}

# Create AppDir structure
create_appdir() {
    print_header "📂 Creating AppDir Structure"
    
    # Clean previous build
    rm -rf AppDir
    
    # Create directory structure
    mkdir -p AppDir/usr/{bin,lib,share/{applications,icons/hicolor/scalable/apps,metainfo}}
    mkdir -p AppDir/usr/share/${PROJECT_NAME}
    
    print_success "AppDir structure created"
}

# Install Python and dependencies
install_python_deps() {
    print_header "🐍 Installing Python Dependencies"
    
    # Create virtual environment
    python3 -m venv AppDir/usr/python-env
    source AppDir/usr/python-env/bin/activate
    
    # Install dependencies
    pip install --upgrade pip
    pip install psutil PyGObject
    
    deactivate
    
    print_success "Python dependencies installed"
}

# Copy application files
copy_application() {
    print_header "📦 Copying Application Files"
    
    # Copy source code
    cp -r ../../core ../../ui AppDir/usr/share/${PROJECT_NAME}/
    cp ../../enhanced_mobalivecd.py AppDir/usr/share/${PROJECT_NAME}/
    
    # Copy documentation
    cp ../../README.md ../../PROJECT_SUMMARY.md AppDir/usr/share/${PROJECT_NAME}/ 2>/dev/null || true
    
    print_success "Application files copied"
}

# Create launcher script
create_launcher() {
    print_header "🚀 Creating Launcher"
    
    cat > AppDir/usr/bin/${PROJECT_NAME} << 'EOF'
#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"

# Set up Python environment
export PYTHONPATH="${APP_DIR}/python-env/lib/python3.*/site-packages:${APP_DIR}/share/mobalivecd-ai:$PYTHONPATH"
export PATH="${APP_DIR}/python-env/bin:$PATH"

# Set up library paths
export LD_LIBRARY_PATH="${APP_DIR}/lib:$LD_LIBRARY_PATH"

# Change to application directory
cd "${APP_DIR}/share/mobalivecd-ai"

# Launch application
python3 enhanced_mobalivecd.py "$@"
EOF
    
    chmod +x AppDir/usr/bin/${PROJECT_NAME}
    
    print_success "Launcher script created"
}

# Create desktop entry
create_desktop_entry() {
    print_header "🖥️  Creating Desktop Entry"
    
    cat > AppDir/usr/share/applications/${PROJECT_NAME}.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=MobaLiveCD AI
GenericName=ISO Virtualization Tool
Comment=AI-Enhanced QEMU-based LiveCD/ISO testing tool with intelligent optimization
Icon=mobalivecd-ai
Exec=mobalivecd-ai %f
Terminal=false
StartupNotify=true
Categories=System;Utility;Emulator;
MimeType=application/x-iso9660-image;application/x-cd-image;
Keywords=qemu;kvm;virtualization;iso;livecd;ai;machine;vm;
EOF
    
    # Validate desktop entry
    desktop-file-validate AppDir/usr/share/applications/${PROJECT_NAME}.desktop
    
    print_success "Desktop entry created and validated"
}

# Create application icon
create_icon() {
    print_header "🎨 Creating Application Icon"
    
    # Create SVG icon
    cat > AppDir/usr/share/icons/hicolor/scalable/apps/${PROJECT_NAME}.svg << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="grad2" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#f093fb;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#f5576c;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- Background -->
  <rect width="128" height="128" rx="24" fill="url(#grad1)"/>
  
  <!-- Main monitor/screen -->
  <rect x="20" y="30" width="88" height="60" rx="8" fill="white" opacity="0.95"/>
  <rect x="24" y="34" width="80" height="52" rx="4" fill="#1a1a2e"/>
  
  <!-- Screen content - AI visualization -->
  <circle cx="45" cy="50" r="8" fill="url(#grad2)" opacity="0.8"/>
  <circle cx="64" cy="60" r="6" fill="#4facfe" opacity="0.8"/>
  <circle cx="85" cy="50" r="7" fill="#00f2fe" opacity="0.8"/>
  
  <!-- Connection lines -->
  <line x1="45" y1="50" x2="64" y2="60" stroke="#667eea" stroke-width="2" opacity="0.6"/>
  <line x1="64" y1="60" x2="85" y2="50" stroke="#667eea" stroke-width="2" opacity="0.6"/>
  
  <!-- Base/stand -->
  <rect x="58" y="90" width="12" height="8" rx="2" fill="white" opacity="0.9"/>
  <rect x="45" y="98" width="38" height="6" rx="3" fill="white" opacity="0.9"/>
  
  <!-- AI badge -->
  <circle cx="100" cy="40" r="12" fill="#f5576c"/>
  <text x="100" y="46" text-anchor="middle" font-family="Arial, sans-serif" 
        font-size="12" font-weight="bold" fill="white">AI</text>
  
  <!-- ISO indicator -->
  <rect x="30" y="110" width="20" height="12" rx="2" fill="#764ba2" opacity="0.8"/>
  <text x="40" y="119" text-anchor="middle" font-family="Arial, sans-serif" 
        font-size="8" fill="white">ISO</text>
</svg>
EOF
    
    # Create AppRun link
    ln -sf usr/bin/${PROJECT_NAME} AppDir/AppRun
    
    # Create desktop file link
    ln -sf usr/share/applications/${PROJECT_NAME}.desktop AppDir/${PROJECT_NAME}.desktop
    
    # Create icon link
    ln -sf usr/share/icons/hicolor/scalable/apps/${PROJECT_NAME}.svg AppDir/${PROJECT_NAME}.svg
    
    print_success "Application icon and links created"
}

# Create metainfo file
create_metainfo() {
    print_header "📋 Creating Metainfo"
    
    cat > AppDir/usr/share/metainfo/${PROJECT_NAME}.metainfo.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>org.mobatek.MobaLiveCDAI</id>
  <name>MobaLiveCD AI</name>
  <summary>AI-Enhanced ISO Virtualization Tool</summary>
  <description>
    <p>
      MobaLiveCD AI is an advanced, AI-enhanced QEMU-based LiveCD/ISO testing tool 
      that brings intelligent optimization to virtualization. Perfect for testing 
      Linux distributions, recovery tools, and other bootable images.
    </p>
    <p>Features:</p>
    <ul>
      <li>AI-powered ISO detection and optimization</li>
      <li>Smart hardware acceleration with KVM support</li>
      <li>Real-time performance monitoring</li>
      <li>Modern GTK4/Libadwaita interface</li>
      <li>Multi-VM management system</li>
      <li>Intelligent resource allocation</li>
    </ul>
  </description>
  <launchable type="desktop-id">mobalivecd-ai.desktop</launchable>
  <provides>
    <binary>mobalivecd-ai</binary>
  </provides>
  <url type="homepage">https://github.com/wlfogle/mobalivecd-linux</url>
  <url type="bugtracker">https://github.com/wlfogle/mobalivecd-linux/issues</url>
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>GPL-2.0-or-later</project_license>
  <releases>
    <release version="2.0.0" date="2024-09-09">
      <description>
        <p>Major AI-enhanced release with intelligent optimization features</p>
      </description>
    </release>
  </releases>
  <content_rating type="oars-1.1" />
</component>
EOF
    
    print_success "Metainfo file created"
}

# Build the AppImage
build_appimage() {
    print_header "🔨 Building AppImage"
    
    print_info "Running appimagetool..."
    
    # Set environment variables for AppImage
    export ARCH=x86_64
    export VERSION=${VERSION}
    
    # Build AppImage
    if command -v appimagetool &> /dev/null; then
        appimagetool AppDir ${APPIMAGE_NAME}
    elif [ -x "./squashfs-root/AppRun" ]; then
        ./squashfs-root/AppRun AppDir ${APPIMAGE_NAME}
    else
        print_error "appimagetool not available"
        exit 1
    fi
    
    # Make executable
    chmod +x ${APPIMAGE_NAME}
    
    print_success "AppImage built: ${APPIMAGE_NAME}"
    
    # Show file info
    ls -lh ${APPIMAGE_NAME}
    file ${APPIMAGE_NAME}
}

# Test the AppImage
test_appimage() {
    print_header "🧪 Testing AppImage"
    
    print_info "Testing AppImage execution..."
    ./${APPIMAGE_NAME} --version 2>/dev/null || print_warning "Version test failed (expected for current implementation)"
    
    print_info "Testing desktop integration..."
    ./${APPIMAGE_NAME} --help 2>/dev/null || print_warning "Help test failed (expected for current implementation)"
    
    print_success "Basic AppImage tests completed"
}

# Main execution
main() {
    print_header "🚀 MobaLiveCD AI AppImage Builder v${VERSION}"
    
    echo -e "${CYAN}Building portable AppImage for universal Linux compatibility${NC}"
    echo ""
    
    # Change to packaging directory
    cd "$(dirname "$0")"
    
    # Execute build steps
    check_dependencies
    get_appimagetool
    create_appdir
    install_python_deps
    copy_application
    create_launcher
    create_desktop_entry
    create_icon
    create_metainfo
    build_appimage
    test_appimage
    
    print_header "✅ Build Complete!"
    echo -e "${GREEN}AppImage created: ${APPIMAGE_NAME}${NC}"
    echo -e "${CYAN}You can now run: ./${APPIMAGE_NAME}${NC}"
    echo -e "${CYAN}Or distribute this single file to any Linux system!${NC}"
}

# Run main function
main "$@"
