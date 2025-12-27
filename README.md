# MT7902 WiFi & Bluetooth Driver for Fedora 43+

**Working driver solution for MediaTek MT7902 802.11ax WiFi adapter on Fedora 43 and newer kernels.**

## Hardware Information

| Component | Details |
|-----------|---------|
| WiFi PCI ID | `14c3:7902` |
| Bluetooth USB ID | `13d3:3579` |
| Device Name | MediaTek MT7902 802.11ax PCIe Wireless Network Adapter [Filogic 310] |
| Laptop Tested | ASUS Vivobook Go E1504FA |
| OS Tested | Fedora 43, Kernel 6.17.12 |

## Current Status

| Feature | Status | Notes |
|---------|--------|-------|
| Bluetooth | ✅ **WORKING** | After adding USB device ID to btusb driver |
| WiFi | 🔄 **Testing** | Using gen4-mt7902 driver from Xiaomi BSP |

## Quick Installation

### WiFi Driver (gen4-mt7902)

```bash
cd gen4-driver
sudo chmod +x install.sh
sudo ./install.sh
sudo reboot
```

### Bluetooth Fix

```bash
cd bluetooth-fix
sudo chmod +x install.sh
sudo ./install.sh
```

## The Problem

The MT7902 WiFi chip is **not supported in the upstream Linux kernel**:

1. **PCI ID 0x7902 is missing** from both mt7925e and mt7921e drivers
2. Even when manually adding the PCI ID, firmware communication fails with "Failed to get patch semaphore"

## The Solution

We use the **gen4-mt7902** driver from [hmtheboy154](https://github.com/hmtheboy154/gen4-mt7902), based on Xiaomi's Android BSP:

- ✅ Proper MT7902 hardware support
- ✅ Includes correct firmware files
- ✅ Fixed for Fedora 42+ by [Abdulrahman-Attya](https://github.com/Abdulrahman-Attya/gen4-mt7902)

## Troubleshooting

```bash
# Check driver status
lspci -k -s 02:00.0
lsmod | grep mt7902

# Check dmesg for errors
sudo dmesg | grep -i mt79

# Check WiFi interface
ip link show
nmcli device wifi list

# Check Bluetooth
rfkill list
bluetoothctl show
```

## Credits

- [hmtheboy154/gen4-mt7902](https://github.com/hmtheboy154/gen4-mt7902)
- [Abdulrahman-Attya/gen4-mt7902](https://github.com/Abdulrahman-Attya/gen4-mt7902/tree/fix-fedora-42)
- [wildanadt/MT7902-bluetooth-linux](https://github.com/wildanadt/MT7902-bluetooth-linux)

## License

GPL-2.0
