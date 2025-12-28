# MT7902 WiFi & Bluetooth Driver for Fedora 43+

Driver solutions for MediaTek MT7902 802.11ax WiFi adapter and Bluetooth on Fedora 43 and newer kernels.

## Hardware Information

| Component | Details |
|-----------|---------|
| WiFi PCI ID | `14c3:7902` |
| WiFi Subsystem | AzureWave `1a3b:5520` |
| Bluetooth USB ID | `13d3:3579` (IMC Networks) |
| Device Name | MediaTek MT7902 802.11ax PCIe Wireless Network Adapter [Filogic 310] |
| Laptop Tested | ASUS Vivobook Go E1504FA |
| OS Tested | Fedora 43, Kernel 6.17.12-300.fc43 |

## Current Status

| Feature | Status | Notes |
|---------|--------|-------|
| Bluetooth | **WORKING** | Custom btusb.ko with MT7902 USB ID + BTUSB_MEDIATEK flag |
| WiFi | **Not Working** | Both drivers crash on kernel 6.17 - see WiFi Status below |

## Bluetooth Fix (WORKING)

The mainline Linux kernel btusb driver doesn't recognize the MT7902 USB Bluetooth device.
Our fix adds the USB device ID `0x13d3:0x3579` with the `BTUSB_MEDIATEK` flag.

### Installation

```bash
cd bluetooth-fix
sudo chmod +x install.sh
sudo ./install.sh
```

### What it does
- Adds USB device ID to btusb driver with correct MediaTek flag
- Installs to `/lib/modules/$(uname -r)/updates/` for priority loading
- Persists across reboots

### Verification
```bash
rfkill list              # Should show asus-bluetooth and hci0
bluetoothctl show       # Should show adapter with address
hciconfig hci0          # Should show "UP RUNNING"
```

## WiFi Status (December 2024)

### IMPORTANT: Both available drivers crash on Kernel 6.17

1. **gen4-mt7902 driver** - DANGEROUS - Causes kernel panics
   - Infinite loop in `halRxReceiveRFBs` function
   - **DO NOT USE** - Blacklisted in modprobe config
   
2. **mt7925e mainline driver** - Has MT7902 support but crashes
   - Kernel has alias `pci:v000014C3d00007902` in mt7925e
   - Crashes with kernel Oops in `mt76_mmio_rr` during probe
   - Error: "not-present page" - PCI BAR memory mapping fails
   - Driver loads but fails to create wireless interface

### Crash Details (mt7925e)
```
BUG: unable to handle page fault for address: ffffd08d4a055024
#PF: supervisor read access in kernel mode
#PF: error_code(0x0000) - not-present page
RIP: 0010:mt76_mmio_rr+0x12/0x80 [mt76]
Call Trace:
  __mt7925_reg_addr+0x12c/0x350 [mt7925e]
  mt7925_rr+0x16/0x30 [mt7925e]
  mt7925_pci_probe+0x2da/0x420 [mt7925e]
```

### Possible Solutions (Under Investigation)
- Try kernel 6.18 RC (may have upstream fixes)
- BIOS settings: Check WiFi enable, PCIe power management options
- Kernel parameters: `pcie_aspm=off` or `pci=nomsi`
- Wait for upstream kernel fix
- Use a USB WiFi adapter as a workaround

### Current modprobe configuration
File: `/etc/modprobe.d/mt7902-wifi.conf`
```
# Blacklist the dangerous gen4 driver
blacklist mt7902
blacklist wlan
install mt7902 /bin/true
install wlan /bin/true

# Configure mt7925e (disable ASPM for better stability)
options mt7925e disable_aspm=1
```

## Directory Structure

```
MT7902-fedora43-driver/
├── bluetooth-fix/           # WORKING Bluetooth driver fix
│   ├── btusb.c             # Patched btusb driver source
│   ├── btmtk.c             # MediaTek Bluetooth support
│   ├── btmtk.h             # Header file
│   └── install.sh          # Installation script
├── gen4-driver/            # WiFi driver (DO NOT USE - causes panics)
├── mt7921/                 # Reference mt7921 driver source
├── mt7925/                 # Reference mt7925 driver source
└── README.md               # This file
```

## Firmware Files

The required firmware files should be in `/lib/firmware/mediatek/`:

### Bluetooth
- `BT_RAM_CODE_MT7902_1_1_hdr.bin`

### WiFi
- `WIFI_MT7902_patch_mcu_1_1_hdr.bin`
- `WIFI_RAM_CODE_MT7902_1.bin`

## Troubleshooting

```bash
# Check WiFi PCI device
lspci -k -s 02:00.0

# Check loaded modules
lsmod | grep -E "mt76|bt"

# Check kernel messages
sudo dmesg | grep -E "mt79|7902|bluetooth"

# Check rfkill blocks
rfkill list

# Check wireless interfaces
ip link show
iw dev
```

## Contributing

If you find a fix for the WiFi driver, please open an issue or PR!

## References

- [gen4-mt7902 original](https://github.com/hmtheboy154/gen4-mt7902)
- [Fedora 42+ fix](https://github.com/Abdulrahman-Attya/gen4-mt7902)
- [OpenWrt mt76 driver](https://github.com/openwrt/mt76)
- [Linux kernel mt7925 driver](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/drivers/net/wireless/mediatek/mt76/mt7925)

## License

GPL-2.0 (same as Linux kernel)
