# MT7902 Troubleshooting Guide

## Quick Diagnosis

### Check Hardware Detection
```bash
# Check if device is detected
lspci -nn | grep -i network
# Expected: 02:00.0 Network controller [0280]: MEDIATEK Corp. MT7902 [14c3:7902]

# Check Bluetooth
lsusb | grep -i bluetooth
# Expected: IMC Networks Wireless_Device (13d3:3579)
```

### Check Driver Status
```bash
# Check which drivers are loaded
lsmod | grep -E "mt76|bt"

# Check driver binding for WiFi
ls -la /sys/bus/pci/devices/0000:02:00.0/driver

# Check kernel messages
sudo dmesg | grep -E "mt79|7902|bluetooth" | tail -30
```

## Bluetooth Issues

### Bluetooth Not Working

1. **Check if btusb is loaded:**
   ```bash
   lsmod | grep btusb
   ```

2. **Check if device is recognized:**
   ```bash
   hciconfig -a
   ```

3. **If no hci0 device:**
   ```bash
   # Install our fix
   cd bluetooth-fix
   sudo ./install.sh
   ```

4. **If hci0 exists but is DOWN:**
   ```bash
   sudo hciconfig hci0 up
   rfkill unblock bluetooth
   ```

### Bluetooth Was Working, Now Broken After Kernel Update

The custom btusb.ko is kernel-version specific. After kernel update:
```bash
cd bluetooth-fix
sudo ./install.sh
```

## WiFi Issues

### WiFi Not Detected At All

1. **Check PCI device:**
   ```bash
   lspci -s 02:00.0 -v
   ```

2. **Check rfkill:**
   ```bash
   rfkill list
   # If blocked: rfkill unblock wifi
   ```

3. **Check BIOS:**
   - Ensure WiFi is enabled in BIOS
   - Try disabling PCIe power management

### Driver Loads But No Interface (Current Issue)

This is the current state with mt7925e on kernel 6.17. The driver crashes during probe.

**Crash signature:**
```
Oops: 0000 [#1] SMP NOPTI
RIP: 0010:mt76_mmio_rr+0x12/0x80 [mt76]
#PF: error_code(0x0000) - not-present page
```

**Possible workarounds:**

1. **Try kernel parameters:**
   Add to `/etc/default/grub` in `GRUB_CMDLINE_LINUX`:
   ```
   pcie_aspm=off
   pci=nomsi
   ```
   Then: `sudo grub2-mkconfig -o /boot/grub2/grub.cfg`

2. **Try different kernel:**
   ```bash
   # Install 6.18 RC kernel (if available)
   sudo dnf install kernel-6.18*
   
   # Boot to different kernel from GRUB menu
   ```

3. **Check for ACPI issues:**
   ```bash
   sudo dmesg | grep -i acpi | grep -i wlan
   # Look for errors like "Failure creating named object"
   ```

### Kernel Panics

If you're experiencing kernel panics with WiFi:

1. **Blacklist the problematic driver:**
   ```bash
   echo "blacklist mt7902" | sudo tee /etc/modprobe.d/blacklist-mt7902.conf
   echo "install mt7902 /bin/true" | sudo tee -a /etc/modprobe.d/blacklist-mt7902.conf
   sudo dracut -f
   sudo reboot
   ```

2. **Prevent driver from auto-loading:**
   ```bash
   echo "blacklist mt7925e" | sudo tee -a /etc/modprobe.d/blacklist-mt7902.conf
   sudo dracut -f
   ```

## Useful Commands

```bash
# Full system info
inxi -Fxz

# Network devices detailed
lshw -c network

# Module info
modinfo mt7925e
modinfo btusb

# Check firmware files
ls -la /lib/firmware/mediatek/WIFI*MT7902*
ls -la /lib/firmware/mediatek/BT*MT7902*

# PCI device details
sudo lspci -vvv -s 02:00.0

# USB device details
lsusb -v -d 13d3:3579 2>/dev/null
```

## Log Collection

If reporting an issue, please include:
```bash
# Collect diagnostic info
echo "=== System Info ===" > mt7902-debug.txt
uname -a >> mt7902-debug.txt
cat /etc/os-release >> mt7902-debug.txt

echo "=== PCI Devices ===" >> mt7902-debug.txt
lspci -nn >> mt7902-debug.txt

echo "=== USB Devices ===" >> mt7902-debug.txt
lsusb >> mt7902-debug.txt

echo "=== Loaded Modules ===" >> mt7902-debug.txt
lsmod | grep -E "mt76|bt" >> mt7902-debug.txt

echo "=== Kernel Messages ===" >> mt7902-debug.txt
sudo dmesg | grep -E "mt79|7902|bluetooth|wifi|wlan" >> mt7902-debug.txt

echo "=== Firmware Files ===" >> mt7902-debug.txt
ls -la /lib/firmware/mediatek/*7902* >> mt7902-debug.txt 2>&1
```
