#!/bin/bash
# MT7902 Gen4 Driver Installation Script for Fedora 43+
# Based on: https://github.com/hmtheboy154/gen4-mt7902

set -e

echo "=== MT7902 Gen4 WiFi Driver Installation ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (sudo ./install.sh)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_VERSION=$(uname -r)

echo "[1/6] Installing kernel headers and build dependencies..."
dnf install -y kernel-devel-$KERNEL_VERSION kernel-headers-$KERNEL_VERSION gcc make git bc flex bison || true

echo ""
echo "[2/6] Cloning gen4-mt7902 driver source (with Fedora 42+ fix)..."
cd /tmp
rm -rf gen4-mt7902
git clone -b fix-fedora-42 https://github.com/Abdulrahman-Attya/gen4-mt7902.git

echo ""
echo "[3/6] Building the driver (this takes a few minutes)..."
cd gen4-mt7902
make -j$(nproc) 2>&1 | tail -20

if [ ! -f mt7902.ko ]; then
    echo "ERROR: Driver build failed!"
    exit 1
fi

echo ""
echo "[4/6] Installing kernel module..."
mkdir -p /lib/modules/$KERNEL_VERSION/kernel/drivers/net/wireless/mediatek/mt7902
cp mt7902.ko /lib/modules/$KERNEL_VERSION/kernel/drivers/net/wireless/mediatek/mt7902/
depmod -a

echo ""
echo "[5/6] Installing firmware files..."
cp "$SCRIPT_DIR/firmware/"*.bin /lib/firmware/ 2>/dev/null || cp firmware/*.bin /lib/firmware/

echo ""
echo "[6/6] Setting up blacklist configuration..."
cp "$SCRIPT_DIR/mt7902-blacklist.conf" /etc/modprobe.d/ 2>/dev/null || cat > /etc/modprobe.d/mt7902-blacklist.conf << 'EOF'
# Blacklist upstream mt79xx drivers to use gen4-mt7902 driver
blacklist mt7925e
blacklist mt7925_common
blacklist mt7921e
blacklist mt7921_common
blacklist wl

# Ensure mt7902 gen4 driver loads
options mt7902 debug_level=3
EOF

echo ""
echo "Regenerating initramfs..."
dracut -f

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Please REBOOT your system for changes to take effect."
echo ""
echo "After reboot, check WiFi status with:"
echo "  ip link show"
echo "  nmcli device status"
echo "  nmcli device wifi list"
echo ""
