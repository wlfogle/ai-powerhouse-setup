# Makefile for MobaLiveCD Linux

APPNAME = mobalivecd
VERSION = 2.0.0
PREFIX = /usr/local
DESTDIR =

# Directories
BINDIR = $(DESTDIR)$(PREFIX)/bin
LIBDIR = $(DESTDIR)$(PREFIX)/lib/$(APPNAME)
DATADIR = $(DESTDIR)$(PREFIX)/share
APPDIR = $(DATADIR)/applications
ICONDIR = $(DATADIR)/pixmaps

# Installation targets
.PHONY: install uninstall clean test run check create-usb list-usb

# Default target
all:
	@echo "MobaLiveCD Linux v$(VERSION)"
	@echo "Available targets:"
	@echo "  install     - Install system-wide (requires root)"
	@echo "  install-user- Install for current user"
	@echo "  uninstall   - Uninstall system-wide (requires root)"
	@echo "  run         - Run application directly"
	@echo "  test        - Test application"
	@echo "  check       - Check dependencies"
	@echo "  list-usb    - List available USB devices"
	@echo "  create-usb  - Create bootable USB (interactive mode)"
	@echo "  clean       - Clean temporary files"

# Check dependencies
check:
	@echo "Checking dependencies..."
	@python3 --version || (echo "Python 3 required"; exit 1)
	@qemu-system-x86_64 --version || (echo "QEMU required"; exit 1)
	@python3 -c "import gi; gi.require_version('Gtk', '4.0'); from gi.repository import Gtk" || \
		(echo "PyGObject/GTK4 required"; exit 1)
	@echo "All dependencies satisfied"

# Run directly
run: check
	@echo "Running MobaLiveCD Linux..."
	cd . && python3 ./mobalivecd.py

# Test functionality
test: check
	@echo "Testing MobaLiveCD components..."
	@python3 -c "from core.qemu_runner import QEMURunner; r = QEMURunner(); print('QEMU runner:', r.get_system_info())"
	@echo "Basic tests passed"

# System installation (requires root)
install: check
	@if [ "$$(id -u)" != "0" ]; then \
		echo "System installation requires root privileges"; \
		echo "Run: sudo make install"; \
		exit 1; \
	fi
	@echo "Installing MobaLiveCD Linux system-wide..."
	@mkdir -p $(BINDIR) $(LIBDIR) $(APPDIR) $(ICONDIR)
	@cp mobalivecd.py $(BINDIR)/$(APPNAME)
	@chmod +x $(BINDIR)/$(APPNAME)
	@cp -r ui core i18n $(LIBDIR)/
	@cp mobalivecd.desktop $(APPDIR)/
	@sed -i 's|Exec=mobalivecd|Exec=$(PREFIX)/bin/$(APPNAME)|g' $(APPDIR)/mobalivecd.desktop
	@chmod +x $(APPDIR)/mobalivecd.desktop
	@echo "import sys; sys.path.insert(0, '$(PREFIX)/lib/$(APPNAME)')" | \
		cat - $(BINDIR)/$(APPNAME) > temp && mv temp $(BINDIR)/$(APPNAME)
	@chmod +x $(BINDIR)/$(APPNAME)
	@update-desktop-database $(DATADIR)/applications/ 2>/dev/null || true
	@echo "Installation completed"

# User installation
install-user: check
	@echo "Installing MobaLiveCD Linux for current user..."
	@./install.sh user

# System uninstallation
uninstall:
	@if [ "$$(id -u)" != "0" ]; then \
		echo "System uninstallation requires root privileges"; \
		echo "Run: sudo make uninstall"; \
		exit 1; \
	fi
	@echo "Uninstalling MobaLiveCD Linux..."
	@rm -f $(BINDIR)/$(APPNAME)
	@rm -rf $(LIBDIR)
	@rm -f $(APPDIR)/mobalivecd.desktop
	@update-desktop-database $(DATADIR)/applications/ 2>/dev/null || true
	@echo "Uninstallation completed"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -name "*.pyc" -delete
	@find . -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@echo "Cleanup completed"

# USB creation targets
list-usb:
	@echo "Listing available USB devices..."
	@python3 ./create_usb.py --list

create-usb: check
	@echo "Starting interactive USB creation..."
	@python3 ./create_usb.py --interactive

# Help
help: all
