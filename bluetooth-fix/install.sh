#!/bin/bash
# MT7902 Bluetooth Fix Installation Script
# Adds USB device ID 0x13d3:0x3579 to btusb driver

set -e

echo "=== MT7902 Bluetooth Driver Fix Installation ==="
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (sudo ./install.sh)"
    exit 1
fi

KERNEL_VERSION=$(uname -r)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[1/4] Installing kernel headers and build dependencies..."
dnf install -y kernel-devel-$KERNEL_VERSION kernel-headers-$KERNEL_VERSION gcc make || true

echo ""
echo "[2/4] Building Bluetooth modules..."
cd "$SCRIPT_DIR"

# Create Makefile
cat > Makefile << 'EOF'
obj-m := btusb.o btmtk.o

KDIR := /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
EOF

make 2>&1 | tail -10

if [ ! -f btusb.ko ]; then
    echo "ERROR: btusb build failed!"
    exit 1
fi

echo ""
echo "[3/4] Installing Bluetooth modules..."
# Backup originals
cp /lib/modules/$KERNEL_VERSION/kernel/drivers/bluetooth/btusb.ko /lib/modules/$KERNEL_VERSION/kernel/drivers/bluetooth/btusb.ko.bak 2>/dev/null || true
cp /lib/modules/$KERNEL_VERSION/kernel/drivers/bluetooth/btmtk.ko /lib/modules/$KERNEL_VERSION/kernel/drivers/bluetooth/btmtk.ko.bak 2>/dev/null || true

# Install new modules
cp btusb.ko /lib/modules/$KERNEL_VERSION/kernel/drivers/bluetooth/
cp btmtk.ko /lib/modules/$KERNEL_VERSION/kernel/drivers/bluetooth/

depmod -a

echo ""
echo "[4/4] Reloading Bluetooth driver..."
rmmod btusb 2>/dev/null || true
modprobe btusb

echo ""
echo "=== Bluetooth Fix Installation Complete ==="
echo ""
echo "Check Bluetooth status with:"
echo "  rfkill list"
echo "  bluetoothctl show"
echo ""
