# MT7902 Troubleshooting Guide

## Bluetooth Not Working

### Symptoms
- `bluetoothctl show` returns "No default controller available"
- `hciconfig hci0` shows BD Address: 00:00:00:00:00:00
- Bluetooth toggle in settings doesn't work

### Diagnosis
```bash
# Check if bluetooth device exists
ls /sys/class/bluetooth/

# Check device status
hciconfig hci0

# Check rfkill
rfkill list bluetooth

# Check service
systemctl status bluetooth
```

### Root Cause
Bluetooth is part of the same MT7902 combo chip. When WiFi firmware fails to load, bluetooth also fails.

### Solution
Fix the WiFi driver issue (kernel 6.16 build). Once MT7902 WiFi works, bluetooth should work automatically.

### Temporary Workaround
None - bluetooth requires working MT7902 driver.

---

## WiFi Not Detected

### Symptoms
- No wireless interface appears (`ip link`)
- MT7902 PCI device visible but no driver bound
- `lspci -k` shows no driver in use

### Diagnosis
```bash
# Check if device is detected
lspci -d 14c3:7902

# Check driver binding
lspci -k -d 14c3:7902

# Check if module exists
modinfo mt7925e

# Check module loading
lsmod | grep mt7925
```

### Possible Causes

#### 1. Wrong Kernel Version
MT7902 support requires:
- Kernel 6.16+ with mt7925 driver
- OR custom 6.17+ with ported driver

**Solution:** Boot into kernel 6.16 from GRUB menu

#### 2. Module Not Loaded
**Solution:**
```bash
sudo modprobe mt7925e
dmesg | tail -20
```

#### 3. Firmware Missing
**Solution:**
```bash
sudo dnf install linux-firmware
ls /lib/firmware/mediatek/mt7925/
```

Required files:
- `WIFI_MT7925_PATCH_MCU_1_1_hdr.bin`
- `WIFI_RAM_CODE_MT7925_1_1.bin`

#### 4. Driver Not Compiled
If using custom kernel, verify:
```bash
ls /lib/modules/$(uname -r)/kernel/drivers/net/wireless/mediatek/mt76/mt7925/
```

Should contain: `mt7925e.ko`, `mt7925-common.ko`, `mt792x-lib.ko`, `mt76-connac-lib.ko`, `mt76.ko`

---

## Kernel Build Failures

### Compilation Errors

#### Missing Dependencies
```bash
# Install build dependencies
sudo dnf install gcc make flex bison elfutils-libelf-devel openssl-devel ncurses-devel
```

#### Out of Disk Space
```bash
# Check space
df -h /

# Clean old builds
cd ~/kernel-6.16-build/linux-6.16
make clean
```

#### Out of Memory
```bash
# Reduce parallel jobs
make -j4  # instead of -j8
# Or
make -j2
```

### Slow Build Times

**Normal:** 1-3 hours on 8-core CPU
**Slow:** 4-6 hours on dual-core or with limited RAM

**Speed up:**
```bash
# Use more cores (if available)
make -j$(nproc)

# Use ccache (if installed)
export CC="ccache gcc"
make -j8
```

---

## Installation Issues

### GRUB Doesn't Show New Kernel

**Solution:**
```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grubby --info=ALL | grep title
```

### Wrong Kernel Boots by Default

**Solution:**
```bash
# Set kernel 6.16 as default
sudo grubby --set-default /boot/vmlinuz-6.16.0

# Verify
sudo grubby --default-kernel
```

### Boot Fails with New Kernel

**Recovery:**
1. Reboot and hold Shift key
2. Select Advanced Options
3. Choose Fedora 6.17.4 kernel
4. Boot successfully
5. Remove problematic kernel:
```bash
sudo dnf remove kernel-6.16.0
```

---

## Module Loading Failures

### "modprobe: FATAL: Module mt7925e not found"

**Cause:** Module not installed or wrong kernel running

**Solution:**
```bash
# Verify kernel version
uname -r

# Reinstall modules (from build directory)
cd ~/kernel-6.16-build/linux-6.16
sudo make modules_install

# Rebuild module dependencies
sudo depmod -a
```

### "mt7925e: Required key not available"

**Cause:** Secure Boot enabled, module not signed

**Solution:**
```bash
# Option 1: Disable Secure Boot in BIOS

# Option 2: Sign the module
sudo /usr/src/kernels/$(uname -r)/scripts/sign-file sha256 \
  /path/to/signing_key.priv \
  /path/to/signing_key.x509 \
  /lib/modules/$(uname -r)/kernel/drivers/net/wireless/mediatek/mt76/mt7925/mt7925e.ko
```

---

## Firmware Loading Failures

### "mt7925e: Direct firmware load failed"

**Check dmesg:**
```bash
dmesg | grep -i firmware
```

**Solutions:**

#### Missing Firmware Files
```bash
sudo dnf install linux-firmware
sudo dnf update linux-firmware
```

#### Wrong Firmware Path
```bash
# Check expected path
modinfo mt7925e | grep firmware

# Verify files exist
ls -l /lib/firmware/mediatek/mt7925/
```

#### Firmware Version Mismatch
Download latest firmware:
```bash
cd /tmp
git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
sudo cp linux-firmware/mediatek/mt7925/* /lib/firmware/mediatek/mt7925/
```

---

## Network Manager Issues

### Interface Not Managed

**Check:**
```bash
nmcli device status
```

If shows "unmanaged":

**Solution:**
```bash
# Edit NetworkManager config
sudo vi /etc/NetworkManager/NetworkManager.conf

# Ensure it contains:
[main]
plugins=ifcfg-rh

[ifcfg-rh]
unmanaged-devices=none

# Restart
sudo systemctl restart NetworkManager
```

### Can't Connect to Networks

**Try:**
```bash
# Delete and recreate connection
nmcli connection delete "WiFi-Name"
nmcli device wifi connect "SSID" password "password"
```

---

## Performance Issues

### Slow WiFi Speeds

**Check signal:**
```bash
iw dev wlan0 link
```

**Try different channels/bands:**
```bash
# Force 5GHz
nmcli connection modify "WiFi-Name" 802-11-wireless.band a
```

### Frequent Disconnections

**Check logs:**
```bash
journalctl -u NetworkManager -f
dmesg | grep mt7925
```

**Try disabling power management:**
```bash
sudo iw dev wlan0 set power_save off
```

---

## Deep Porting Method Issues

### Header Ordering Errors

```
error: invalid use of undefined type 'struct mt7902_dev'
```

**Cause:** Circular dependencies between mt7902.h and mt792x.h

**Solutions:**
1. Move inline functions to .c files
2. Add forward declarations
3. Reorganize header inclusion order
4. Use compatibility layer

### Type Mismatch Errors

```
error: incompatible types when passing argument
```

**Cause:** mt7902 custom structs vs mt792x generic structs

**Solution:**
- Add missing fields to mt7902 structs
- Use type casting where layouts are compatible
- Add compiler flags: `-Wno-incompatible-pointer-types`

---

## Getting Help

### Collect Diagnostics

Run this and share output:
```bash
echo "=== System Info ==="
uname -a
lspci -d 14c3:7902 -vv
echo ""
echo "=== Module Info ==="
lsmod | grep mt
modinfo mt7925e 2>/dev/null || echo "Module not found"
echo ""
echo "=== Firmware ==="
ls -lh /lib/firmware/mediatek/mt7925/ 2>/dev/null || echo "Firmware dir not found"
echo ""
echo "=== Kernel Messages ==="
dmesg | grep -i "mt7925\|mt7902\|mt76" | tail -50
echo ""
echo "=== Network Interfaces ==="
ip link show
```

### Community Support

- **GitHub Issues:** https://github.com/NullNaveen/MT7902-fedora43-driver/issues
- **Fedora Forums:** https://ask.fedoraproject.org/
- **Linux Wireless:** https://wireless.wiki.kernel.org/

### Reporting Bugs

Include:
1. Kernel version: `uname -r`
2. Distribution: `cat /etc/fedora-release`
3. Hardware: `lspci -d 14c3:7902`
4. Logs: `dmesg`, `journalctl -u NetworkManager`
5. Steps taken
6. Error messages (full text)
