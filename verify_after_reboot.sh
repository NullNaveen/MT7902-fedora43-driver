#!/bin/bash
# Post-Reboot Verification Script for Kernel 6.16.0 and MT7902 WiFi
# Run this after rebooting into kernel 6.16.0

echo "========================================"
echo "MT7902 WiFi & Kernel 6.16.0 Verification"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: Kernel Version
echo "1. Checking kernel version..."
KERNEL=$(uname -r)
if [[ "$KERNEL" == "6.16.0" ]]; then
    echo -e "   ${GREEN}✓${NC} Running kernel: $KERNEL"
else
    echo -e "   ${RED}✗${NC} Not running kernel 6.16.0 (current: $KERNEL)"
    echo "   Please reboot and select kernel 6.16.0 from GRUB menu"
    exit 1
fi
echo ""

# Check 2: MT7902 Hardware Detection
echo "2. Checking MT7902 hardware..."
if lspci -nn | grep -q "14c3:7902"; then
    DEVICE=$(lspci -nn | grep "14c3:7902")
    echo -e "   ${GREEN}✓${NC} MT7902 detected: $DEVICE"
else
    echo -e "   ${RED}✗${NC} MT7902 hardware not detected"
    echo "   This is a hardware issue"
    exit 1
fi
echo ""

# Check 3: Driver Loaded
echo "3. Checking MT7925E driver..."
if lsmod | grep -q "mt7925e"; then
    echo -e "   ${GREEN}✓${NC} mt7925e driver loaded"
    lsmod | grep "mt7925\|mt792x" | sed 's/^/   - /'
else
    echo -e "   ${YELLOW}⚠${NC} mt7925e driver not loaded, attempting manual load..."
    sudo modprobe mt7925e 2>/dev/null
    sleep 2
    if lsmod | grep -q "mt7925e"; then
        echo -e "   ${GREEN}✓${NC} Driver loaded successfully"
    else
        echo -e "   ${RED}✗${NC} Failed to load driver"
        echo "   Check dmesg for errors:"
        dmesg | tail -20 | grep -i "mt7925\|error" | sed 's/^/   /'
        exit 1
    fi
fi
echo ""

# Check 4: WiFi Interface
echo "4. Checking WiFi interface..."
if ip link show | grep -q "wl"; then
    IFACE=$(ip link show | grep -o "wl[^:]*" | head -1)
    echo -e "   ${GREEN}✓${NC} WiFi interface found: $IFACE"
    
    # Get interface details
    echo "   Interface details:"
    iw dev | grep -E "Interface|addr|type|channel" | sed 's/^/   /'
else
    echo -e "   ${RED}✗${NC} No WiFi interface detected"
    echo "   Checking dmesg for issues..."
    dmesg | tail -30 | grep -i "mt7925\|ieee80211" | sed 's/^/   /'
    exit 1
fi
echo ""

# Check 5: Firmware Loading
echo "5. Checking firmware..."
if dmesg | grep -q "mt7925.*firmware"; then
    echo -e "   ${GREEN}✓${NC} Firmware messages found"
    dmesg | grep "mt7925.*firmware" | tail -3 | sed 's/^/   /'
    
    if dmesg | grep -q "mt7925.*firmware.*failed"; then
        echo -e "   ${RED}✗${NC} Firmware loading failed"
        exit 1
    fi
else
    echo -e "   ${YELLOW}⚠${NC} No firmware messages in dmesg yet"
fi
echo ""

# Check 6: Network Scanning
echo "6. Testing WiFi scanning..."
if command -v nmcli &> /dev/null; then
    SCAN_RESULT=$(nmcli device wifi list 2>/dev/null | wc -l)
    if [ "$SCAN_RESULT" -gt 1 ]; then
        echo -e "   ${GREEN}✓${NC} WiFi scan successful - found $(($SCAN_RESULT - 1)) networks"
        echo "   Sample networks:"
        nmcli device wifi list | head -4 | sed 's/^/   /'
    else
        echo -e "   ${YELLOW}⚠${NC} No networks found yet, this may take a moment"
        echo "   Triggering scan..."
        sudo nmcli device wifi rescan 2>/dev/null
        sleep 3
        SCAN_RESULT=$(nmcli device wifi list 2>/dev/null | wc -l)
        if [ "$SCAN_RESULT" -gt 1 ]; then
            echo -e "   ${GREEN}✓${NC} WiFi scan successful after rescan"
        else
            echo -e "   ${RED}✗${NC} Still no networks found"
        fi
    fi
else
    echo -e "   ${YELLOW}⚠${NC} nmcli not available, using iw instead"
    if command -v iw &> /dev/null; then
        sudo iw dev "$IFACE" scan | grep -E "SSID|signal" | head -10 | sed 's/^/   /'
    fi
fi
echo ""

# Check 7: Bluetooth
echo "7. Checking Bluetooth..."
if command -v bluetoothctl &> /dev/null; then
    BT_CONTROLLER=$(bluetoothctl show 2>/dev/null | grep "Controller" | cut -d' ' -f2)
    if [ -n "$BT_CONTROLLER" ] && [ "$BT_CONTROLLER" != "00:00:00:00:00:00" ]; then
        echo -e "   ${GREEN}✓${NC} Bluetooth controller detected: $BT_CONTROLLER"
        bluetoothctl show | grep -E "Name|Powered|Discoverable" | sed 's/^/   /'
    else
        echo -e "   ${YELLOW}⚠${NC} Bluetooth controller not ready"
        echo "   This is normal if bluetooth service hasn't started yet"
        echo "   Try: sudo systemctl restart bluetooth"
    fi
else
    echo -e "   ${YELLOW}⚠${NC} bluetoothctl not available"
fi
echo ""

# Summary
echo "========================================"
echo "VERIFICATION SUMMARY"
echo "========================================"
echo ""

if ip link show | grep -q "wl" && lsmod | grep -q "mt7925e"; then
    echo -e "${GREEN}✓ SUCCESS!${NC} MT7902 WiFi is working on kernel 6.16.0"
    echo ""
    echo "You can now:"
    echo "  - Connect to WiFi networks using NetworkManager"
    echo "  - Use command: nmcli device wifi connect <SSID> password <PASSWORD>"
    echo "  - Or use the GUI network manager"
    echo ""
    echo "WiFi interface: $(ip link show | grep -o "wl[^:]*" | head -1)"
    echo "Driver: mt7925e (supports MT7902 PCI ID 0x7902)"
    echo "Kernel: 6.16.0"
    echo ""
else
    echo -e "${RED}✗ ISSUES DETECTED${NC}"
    echo ""
    echo "Please check the detailed output above for specific errors."
    echo "Common fixes:"
    echo "  1. Reboot and select kernel 6.16.0 from GRUB"
    echo "  2. Check dmesg: dmesg | grep -i mt7925"
    echo "  3. Verify firmware: ls -l /lib/firmware/mediatek/WIFI_MT7925*"
    echo "  4. Manual driver load: sudo modprobe mt7925e"
    echo ""
fi

echo "Full documentation: ~/kernel-6.16-build/POST_BUILD_STATUS.md"
echo "GitHub: https://github.com/NullNaveen/MT7902-fedora43-driver"
echo "========================================"
