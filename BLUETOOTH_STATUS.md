# MT7902 Bluetooth Fix Progress

## Hardware
- **Device:** IMC Networks Wireless_Device (USB ID 13d3:3579)
- **Integrated:** With MT7902 WiFi PCIe card (14c3:7902)
- **Controller:** hci0 detected
- **Status:** Hardware recognized, firmware loading fails

## Problem
```
Bluetooth: hci0: Direct firmware load for mediatek/BT_RAM_CODE_MT7902_1_1_hdr.bin failed with error -2
Bluetooth: hci0: Failed to load firmware file (-2)
Bluetooth: hci0: Failed to set up firmware (-2)
```

## Firmware Status
✅ Firmware exists: `/lib/firmware/mediatek/BT_RAM_CODE_MT7902_1_1_hdr.bin` (495426 bytes)
✅ SELinux context correct: `unconfined_u:object_r:lib_t:s0`
❌ Driver fails to load it (error -2 = ENOENT)

## Solution Attempts

### Attempt 1: Custom btusb Build ❌
**Source:** https://github.com/wildanadt/MT7902-bluetooth-linux

**Steps:**
```bash
cd ~/bluetooth-mt7902
make clean && make
sudo cp btusb.ko btmtk.ko /lib/modules/$(uname -r)/updates/
sudo depmod -a
```

**Result:** FAILED
```
Error: module btmtk: .gnu.linkonce.this_module section size must match 
the kernel's built struct module size at run time
```

**Cause:** Kernel version mismatch. Driver built for kernel 6.17.4, running 6.18.0-rc2.

### Attempt 2: System btusb ⏳
The system `btusb` module recognizes the device but:
- USB ID `13d3:3579` not in module alias table
- Device detected as generic Bluetooth
- Firmware path resolution fails

## Next Steps
1. **After reboot:** Check if fresh boot resolves firmware loading
2. **Alternative:** Try older kernel (6.17.x) where bluetooth-mt7902 repo was tested
3. **Build from source:** Compile against exact running kernel headers

## Bluetooth Module Dependencies
```bash
sudo modprobe btintel btbcm btrtl  # Load dependencies
sudo modprobe btusb                 # Load main driver
```

## Verification Commands
```bash
# Check Bluetooth status
rfkill list bluetooth
systemctl status bluetooth
bluetoothctl show

# Check device detection
lsusb | grep -i wireless
dmesg | grep -i "hci0\|bluetooth\|btusb"
```

## References
- Bluetooth repo: https://github.com/wildanadt/MT7902-bluetooth-linux
- Firmware location: `/lib/firmware/mediatek/BT_RAM_CODE_MT7902_1_1_hdr.bin`
- USB Device: Bus 001 Device 003: ID 13d3:3579 IMC Networks Wireless_Device
