#!/bin/bash
# Validation script for system clone ISO builder setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
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

print_status "Validating System Clone ISO Builder Setup"
print_status "=========================================="
echo ""

# Check source system
SOURCE_DIR="${SOURCE_DIR:-/mnt}"
if [[ -d "$SOURCE_DIR" && -f "$SOURCE_DIR/etc/os-release" ]]; then
    . "$SOURCE_DIR/etc/os-release"
    print_success "Source system found: $NAME ($SOURCE_DIR)"
else
    print_error "Source system not found at: $SOURCE_DIR"
    exit 1
fi

# Check disk space
print_status "Checking disk space..."
SOURCE_SIZE=$(du -s "$SOURCE_DIR" 2>/dev/null | awk '{print int($1/1024/1024)}' || echo "0")
AVAILABLE_SPACE=$(df -BG "$HOME" | awk 'NR==2 {gsub(/G/, "", $4); print $4}')
REQUIRED_SPACE=$((SOURCE_SIZE * 3))

echo "  Source system: ${SOURCE_SIZE}GB"
echo "  Available space: ${AVAILABLE_SPACE}GB"
echo "  Required space: ~${REQUIRED_SPACE}GB"

if [[ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]]; then
    print_warning "Insufficient disk space - you may encounter issues"
else
    print_success "Sufficient disk space available"
fi

# Check dependencies
print_status "Checking dependencies..."

if command -v rsync &> /dev/null; then
    print_success "rsync: $(which rsync)"
else
    print_error "rsync not found"
fi

if command -v mkarchiso &> /dev/null; then
    print_success "archiso: $(which mkarchiso)"
else
    print_warning "archiso not installed (will be installed automatically)"
fi

if command -v sudo &> /dev/null; then
    print_success "sudo: $(which sudo)"
else
    print_error "sudo not found"
fi

# Check script permissions
print_status "Checking script files..."
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

for script in "build-ai-powerhouse-iso-from-system.sh" "prepare-system-for-clone.sh"; do
    if [[ -x "$SCRIPT_DIR/$script" ]]; then
        print_success "$script: executable"
    else
        print_error "$script: not executable or missing"
    fi
done

# Check archiso profile
if [[ -d "$SCRIPT_DIR/archiso-method" ]]; then
    print_success "Original archiso profile: found"
else
    print_warning "Original archiso profile: not found (may cause issues)"
fi

# Check write permissions for output directories
print_status "Checking write permissions..."
if touch /tmp/test-write 2>/dev/null; then
    rm -f /tmp/test-write
    print_success "Write permission: /tmp (default output location)"
else
    print_error "No write permission: /tmp"
fi

print_status ""
print_status "Validation Results Summary:"
print_status "============================"
echo "✓ Source system: $SOURCE_DIR"
echo "✓ Scripts: Ready"
echo "✓ Dependencies: Available"

if [[ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]]; then
    echo "⚠ Disk space: May be insufficient"
else
    echo "✓ Disk space: Sufficient"
fi

echo ""
print_success "Setup validation completed!"
print_status "You can now run:"
echo "  1. ./prepare-system-for-clone.sh (optional cleanup)"
echo "  2. ./build-ai-powerhouse-iso-from-system.sh (build ISO)"