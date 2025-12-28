#!/bin/bash
# MT7902 Bluetooth Fix Installation Script
# Adds USB device ID 0x13d3:0x3579 to btusb driver with BTUSB_MEDIATEK flag
# For Fedora 43 with kernel 6.17.x
#
# The issue: The mainline Linux kernel btusb driver doesn't recognize the
# MT7902 USB Bluetooth device (vendor 0x13d3, product 0x3579).
# This script builds and installs a patched btusb module that adds support.

set -e

echo "=== MT7902 Bluetooth Driver Fix Installation ==="
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (sudo ./install.sh)"
    exit 1
fi

KERNEL_VERSION=$(uname -r)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Kernel: $KERNEL_VERSION"
echo "Script directory: $SCRIPT_DIR"
echo ""

echo "[1/5] Installing kernel headers and build dependencies..."
dnf install -y kernel-devel-$KERNEL_VERSION kernel-headers-$KERNEL_VERSION gcc make 2>/dev/null || {
    echo "Some packages may already be installed. Continuing..."
}

echo ""
echo "[2/5] Checking for source files..."
cd "$SCRIPT_DIR"

if [ ! -f btusb.c ] || [ ! -f btmtk.c ]; then
    echo "ERROR: btusb.c or btmtk.c not found in $SCRIPT_DIR"
    exit 1
fi

# Create Makefile for building btusb and btmtk
cat > Makefile << 'MAKEFILE_EOF'
obj-m := btusb.o btmtk.o

KDIR := /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
MAKEFILE_EOF

echo ""
echo "[3/5] Building Bluetooth modules..."
make clean 2>/dev/null || true
make 2>&1 

if [ ! -f btusb.ko ] || [ ! -f btmtk.ko ]; then
    echo "ERROR: Module build failed!"
    exit 1
fi

echo ""
echo "[4/5] Installing Bluetooth modules..."

# Create updates directory for module override (takes precedence over kernel modules)
mkdir -p /lib/modules/$KERNEL_VERSION/updates

# Backup originals (if not already backed up)
if [ ! -f /lib/modules/$KERNEL_VERSION/kernel/drivers/bluetooth/btusb.ko.orig.xz ]; then
    cp /lib/modules/$KERNEL_VERSION/kernel/drivers/bluetooth/btusb.ko.xz \
       /lib/modules/$KERNEL_VERSION/kernel/drivers/bluetooth/btusb.ko.orig.xz 2>/dev/null || true
fi

# Install to updates directory
cp btusb.ko /lib/modules/$KERNEL_VERSION/updates/
cp btmtk.ko /lib/modules/$KERNEL_VERSION/updates/

# Update module dependencies
depmod -a

echo ""
echo "[5/5] Reloading Bluetooth driver..."
rmmod btusb btmtk 2>/dev/null || true
sleep 1
modprobe btusb

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Verifying installation..."

# Check if device is recognized
if hciconfig hci0 2>/dev/null | grep -q "UP RUNNING"; then
    echo "✓ Bluetooth adapter is UP and RUNNING"
    BD_ADDR=$(hciconfig hci0 | grep "BD Address" | awk '{print $3}')
    echo "  BD Address: $BD_ADDR"
else
    echo "⚠ Bluetooth adapter may need activation"
    echo "  Try: sudo hciconfig hci0 up"
fi

echo ""
echo "Useful commands:"
echo "  rfkill list               - Check for hardware blocks"
echo "  bluetoothctl show         - Show adapter info"
echo "  dmesg | grep -i bluetooth - Check kernel messages"
echo ""
